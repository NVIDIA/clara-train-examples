# SPDX-License-Identifier: Apache-2.0

import json
import logging
import os

import torch
import torch.distributed as dist
from monai.data import (
    CacheDataset,
    DataLoader,
    load_decathlon_datalist,
    partition_dataset,
)
from monai.engines import SupervisedEvaluator, SupervisedTrainer
from monai.handlers import (
    CheckpointSaver,
    LrScheduleHandler,
    MeanDice,
    StatsHandler,
    TensorBoardStatsHandler,
    ValidationHandler,
)
from monai.inferers import SimpleInferer, SlidingWindowInferer
from monai.losses import DiceLoss
from monai.networks.layers import Norm
from monai.networks.nets import UNet
from monai.transforms import (
    Activationsd,
    Spacingd,
    AsDiscreted,
    Compose,
    CropForegroundd,
    EnsureChannelFirstd,
    LoadImaged,
    RandCropByPosNegLabeld,
    RandShiftIntensityd,
    ScaleIntensityRanged,
    ToTensord,
)
from torch.nn.parallel import DistributedDataParallel


class TrainConfiger:
    """
    This class is used to config the necessary components of train and evaluate engines
    for MONAI trainer.
    Please check the implementation of `SupervisedEvaluator` and `SupervisedTrainer`
    from `monai.engines` and determine which components can be used.

    Args:
        config_root: root folder path of config files.
        wf_config_file_name: json file name of the workflow config file.
    """

    def __init__(
        self,
        config_root: str,
        wf_config_file_name: str,
        local_rank: int = 0,
    ):
        with open(os.path.join(config_root, wf_config_file_name)) as file:
            wf_config = json.load(file)

        self.wf_config = wf_config
        self.max_epochs = wf_config["max_epochs"]
        self.learning_rate = wf_config["learning_rate"]
        self.data_list_file_path = wf_config["data_list_file_path"]
        self.val_interval = wf_config["val_interval"]
        self.ckpt_dir = wf_config["ckpt_dir"]
        self.save_interval = wf_config["save_interval"]
        self.amp = wf_config["amp"]
        self.use_gpu = wf_config["use_gpu"]
        self.multi_gpu = wf_config["multi_gpu"]
        self.local_rank = local_rank

    def set_device(self):
        if self.multi_gpu:
            # initialize distributed training
            dist.init_process_group(backend="nccl", init_method="env://")
            device = torch.device(f"cuda:{self.local_rank}")
            torch.cuda.set_device(device)
        else:
            device = torch.device("cuda" if self.use_gpu else "cpu")
        self.device = device

    def configure(self):
        self.set_device()
        network = UNet(
            dimensions=3,
            in_channels=1,
            out_channels=2,
            channels=(16, 32, 64, 128, 256),
            strides=(2, 2, 2, 2),
            num_res_units=2,
            norm=Norm.BATCH,
        ).to(self.device)
        if self.multi_gpu:
            network = DistributedDataParallel(
                module=network,
                device_ids=[self.device],
                find_unused_parameters=False,
            )

        train_transforms = Compose(
            [
                LoadImaged(keys=("image", "label")),
                EnsureChannelFirstd(keys=("image", "label")),
                Spacingd(keys=("image", "label"),
                         pixdim=[1.0, 1.0, 1.0],
                         mode=["bilinear", "nearest"]
                         ),
                ScaleIntensityRanged(
                    keys="image",
                    a_min=-57,
                    a_max=164,
                    b_min=0.0,
                    b_max=1.0,
                    clip=True,
                ),
                CropForegroundd(keys=("image", "label"), source_key="image"),
                RandCropByPosNegLabeld(
                    keys=("image", "label"),
                    label_key="label",
                    spatial_size=(96, 96, 96),
                    pos=1,
                    neg=1,
                    num_samples=4,
                    image_key="image",
                    image_threshold=0,
                ),
                RandShiftIntensityd(keys="image", offsets=0.1, prob=0.5),
                ToTensord(keys=("image", "label")),
            ]
        )
        train_datalist = load_decathlon_datalist(
            self.data_list_file_path, True, "training"
        )
        if self.multi_gpu:
            train_datalist = partition_dataset(
                data=train_datalist,
                shuffle=True,
                num_partitions=dist.get_world_size(),
                even_divisible=True,
            )[dist.get_rank()]
        train_ds = CacheDataset(
            data=train_datalist,
            transform=train_transforms,
            cache_num=32,
            cache_rate=1.0,
            num_workers=4,
        )
        train_data_loader = DataLoader(
            train_ds,
            batch_size=2,
            shuffle=True,
            num_workers=4,
        )
        val_transforms = Compose(
            [
                LoadImaged(keys=("image", "label")),
                EnsureChannelFirstd(keys=("image", "label")),
                ScaleIntensityRanged(
                    keys="image",
                    a_min=-57,
                    a_max=164,
                    b_min=0.0,
                    b_max=1.0,
                    clip=True,
                ),
                CropForegroundd(keys=("image", "label"), source_key="image"),
                ToTensord(keys=("image", "label")),
            ]
        )

        val_datalist = load_decathlon_datalist(
            self.data_list_file_path, True, "validation"
        )
        val_ds = CacheDataset(val_datalist, val_transforms, 9, 0.0, 4)
        val_data_loader = DataLoader(
            val_ds,
            batch_size=1,
            shuffle=False,
            num_workers=4,
        )
        post_transform = Compose(
            [
                Activationsd(keys="pred", softmax=True),
                AsDiscreted(
                    keys=["pred", "label"],
                    argmax=[True, False],
                    to_onehot=True,
                    n_classes=2,
                ),
            ]
        )
        # metric
        key_val_metric = {
            "val_mean_dice": MeanDice(
                include_background=False,
                output_transform=lambda x: (x["pred"], x["label"]),
                device=self.device,
            )
        }
        val_handlers = [
            StatsHandler(output_transform=lambda x: None),
            CheckpointSaver(
                save_dir=self.ckpt_dir,
                save_dict={"model": network},
                save_key_metric=True,
            ),
            TensorBoardStatsHandler(
                log_dir=self.ckpt_dir, output_transform=lambda x: None
            ),
        ]
        self.eval_engine = SupervisedEvaluator(
            device=self.device,
            val_data_loader=val_data_loader,
            network=network,
            inferer=SlidingWindowInferer(
                roi_size=[160, 160, 160],
                sw_batch_size=4,
                overlap=0.5,
            ),
            post_transform=post_transform,
            key_val_metric=key_val_metric,
            val_handlers=val_handlers,
            amp=self.amp,
        )

        optimizer = torch.optim.Adam(network.parameters(), self.learning_rate)
        loss_function = DiceLoss(to_onehot_y=True, softmax=True)
        lr_scheduler = torch.optim.lr_scheduler.StepLR(
            optimizer, step_size=5000, gamma=0.1
        )
        train_handlers = [
            LrScheduleHandler(lr_scheduler=lr_scheduler, print_lr=True),
            ValidationHandler(
                validator=self.eval_engine, interval=self.val_interval, epoch_level=True
            ),
            StatsHandler(tag_name="train_loss", output_transform=lambda x: x["loss"]),
            TensorBoardStatsHandler(
                log_dir=self.ckpt_dir,
                tag_name="train_loss",
                output_transform=lambda x: x["loss"],
            ),
        ]

        self.train_engine = SupervisedTrainer(
            device=self.device,
            max_epochs=self.max_epochs,
            train_data_loader=train_data_loader,
            network=network,
            optimizer=optimizer,
            loss_function=loss_function,
            inferer=SimpleInferer(),
            post_transform=post_transform,
            key_train_metric=None,
            train_handlers=train_handlers,
            amp=self.amp,
        )

        if self.local_rank > 0:
            self.train_engine.logger.setLevel(logging.WARNING)
            self.eval_engine.logger.setLevel(logging.WARNING)
