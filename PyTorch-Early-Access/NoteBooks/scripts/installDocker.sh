#!/bin/bash

# Copyright (c) 2018-2020, NVIDIA CORPORATION. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or ofr materials provided with the distribution.
#  * Neither the name of NVIDIA CORPORATION nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
# Clara Train SDK


MIN_DRIVER_VER="410"
DOCKER_PKG_VER="5:19.03.6~3-0"
DOCKER_COMPOSE_VER="1.28.6"
NVIDIA_DOCKER_PKG_VER="2.2.2-1"
NVIDIA_CONTAINER_RUNTIME_VER="3.1.4-1"
NVIDIA_CONTAINER_TOOLKIT_VER="1.0.5-1"
LIBNVIDIA_CONTAINER_VER="1.0.7-1"
KUBERNETES_VER="1.15.4-00"
SUPPORTED_K8S_MIN_VER="1.11"
SUPPORTED_K8S_MAX_VER="1.15.999"

FS_INOTIFY_MAX_USER_WATCHES=524288

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

set -euo pipefail

newline() {
    echo " "
}

info() {
    echo "$(date -u '+%Y-%m-%d %H:%M:%S') [INFO]:" $@
}

fatal() {
    >&2 echo "$(date -u '+%Y-%m-%d %H:%M:%S') [FATAL]:" $@
    newline
    exit 1
}

ver() {
    printf "%03d%03d%03d" $(echo "$1" | tr '.' ' ')
}

add_gpg_key() {
  local -r key_url="$1"
  info "Adding ${key_url} to gpg keys ..."
  if ! curl -sSL "${key_url}" | sudo apt-key add -; then
    fatal "Error adding gpg key: ${key_url}"
  fi
  info "Successfully added ${key_url} !"
}

add_apt_repo_list() {
  local -r repo_list_url="$1"

  # repo_list_url: 'http://a.com/b/c/d.txt' => filename: d.txt
  local -r filename="${repo_list_url##*/}"
  local -r local_repo_list_dir="/etc/apt/sources.list.d"

  info "Adding ${repo_list_url} to /etc/apt/sources.list.d/ ..."
  curl -sSL "${repo_list_url}" | sudo tee "${local_repo_list_dir}/${filename}"
  info "Successfully added ${repo_list_url} !"
}

ensure_package_dependencies() {
  local required_packages='apt-transport-https ca-certificates curl software-properties-common network-manager unzip lsb-release dirmngr'
  info "Check and install required packages: ${required_packages} ..."
  sudo apt-get update
  sudo apt-get install -y ${required_packages}
  info "Starting network-manager service..."
  sudo service network-manager start
  info "Successfully installed required packages: ${required_packages} !"
}

ensure_nvidia_gpu_drivers_installed () {
    info "Checking for NVIDIA GPU driver..."
    set +ue
    while :; do
        case $1 in
            --skip-gpu-check)
                info "Skipping NVIDIA GPU driver check..."
                return
            ;;
            *)
                break
            ;;
        esac
        shift
    done
    set -ue

    if [ ! -x "$(command -v nvidia-smi)" ]; then
        fatal "Please install NVIDIA CUDA driver at https://developer.nvidia.com/cuda-downloads?target_os=Linux"
    else
        local driver_version=$(nvidia-smi | grep "Driver Version:" | awk '{print $6}')
        info "NVIDIA CUDA driver version found: ${driver_version}"
        IFS='.' read -r -a version_parts <<< "$driver_version"
        if [  "${version_parts[0]}" -lt "$MIN_DRIVER_VER" ]
        then

            fatal "Please upgrade NVIDIA CUDA driver at https://developer.nvidia.com/cuda-downloads?target_os=Linux"
        fi

    fi
    info "NVIDIA GPU driver found"

}

install_nvidia_docker2() {
    info "Start installing docker and nvidia-docker2 ..."

    local docker=$(docker --version)
    if [[ $docker != *"Docker version"* ]]; then
        local release
        release="$(lsb_release -cs)"
        add_gpg_key 'https://download.docker.com/linux/ubuntu/gpg'
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${release} stable"

        sudo apt-get update
        local docker_version=$(apt-cache madison docker-ce | grep "${DOCKER_PKG_VER}" | cut -d'|' -f2 | head -1 | tr -d ' ')
        info "Installing docker-ce(=$docker_version)..."
        if ! sudo apt-get install -y docker-ce=${docker_version}; then
            fatal "There were failures trying to install docker."
        fi
    fi

    if id $SUDO_USER | grep -q docker; then
        info "'$SUDO_USER' is already added to docker group. Skipping docker group configuration ..."
    else
        info "Adding user '$SUDO_USER' to docker group..."
        sudo usermod -a -G docker $SUDO_USER
        /bin/echo -e "\033[1;37mPlease log out and log back in later so that your group membership is re-evaluated and you can use docker/kubectl/helm commands without 'sudo'\033[0m"
    fi

    local nvidia_docker=$(nvidia-docker --version)
    if [[ $nvidia_docker == *"Docker version"* ]]; then
        info "Skipping nvidia-docker install since it is already present."
        if ! docker info | grep -q "Default Runtime: nvidia"; then
            /bin/echo -e "\033[1;37mPlease set the docker default runtime to 'nvidia' to use NVIDIA k8s device plugin"
            /bin/echo -e
            /bin/echo -e '$ \033[1;32msudo vi /etc/docker/daemon.json\033[1;37m'
            /bin/echo -e 'Then, set "default-runtime" option to "nvidia" like below:'
            /bin/echo -e '\033[1;34m
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
\033[1;37m
'
            /bin/echo -e "After editing daemon.json, restart docker daemon:"
            /bin/echo -e '\033[1;34m
sudo pkill -SIGHUP dockerd
sudo service docker restart
\033[1;37m
'
            /bin/echo -e 'Then, please execute \033[1;32msudo ./bootstrap.sh\033[1;37m again.'
            /bin/echo -e
            /bin/echo -e "You can check the prerequisites at: https://github.com/NVIDIA/k8s-device-plugin#prerequisites"
            /bin/echo -e "You can learn how to set the runtime at: https://github.com/NVIDIA/k8s-device-plugin#quick-start"
            /bin/echo -e -n "\033[0m"
            exit 1
        fi
        return
    fi
    local distribution
    distribution="$(source /etc/os-release;echo $ID$VERSION_ID)"
    add_gpg_key 'https://nvidia.github.io/nvidia-docker/gpgkey'
    add_apt_repo_list "https://nvidia.github.io/nvidia-docker/${distribution}/nvidia-docker.list"

    sudo apt-get update
    local nvidia_docker_version=$(apt-cache madison nvidia-docker2 | grep "${NVIDIA_DOCKER_PKG_VER}" | cut -d'|' -f2 | head -1 | tr -d ' ')

    info "Installing nvidia-docker2(=$nvidia_docker_version), nvidia-container-runtime(=${NVIDIA_CONTAINER_RUNTIME_VER}), nvidia-container-toolkit(=${NVIDIA_CONTAINER_TOOLKIT_VER}), libnvidia-container-tools(=$LIBNVIDIA_CONTAINER_VER), libnvidia-container1(=$LIBNVIDIA_CONTAINER_VER) ..."
    local nvidia_docker_install_cmd="sudo apt-get install -y nvidia-docker2=$nvidia_docker_version nvidia-container-runtime=${NVIDIA_CONTAINER_RUNTIME_VER} nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VER} libnvidia-container-tools=$LIBNVIDIA_CONTAINER_VER libnvidia-container1=$LIBNVIDIA_CONTAINER_VER"
    if ! $nvidia_docker_install_cmd; then
        local error_msg="$($nvidia_docker_install_cmd | grep "nvidia-docker2 : Depends: docker-ce (=")"
        local workaround="$(echo "${error_msg}" | grep -oP "\(= \K([0-9:.~\-a-z]*)")"
        if [ -n "$workaround" ]; then
            /bin/echo -e "\033[1;37mThere is an issue with nvidia-docker installation. The following command would be executed to workaround the issue:"
            /bin/echo -e
            /bin/echo -e '$ \033[1;32msudo apt-get install -y --allow-downgrades docker-ce='"${workaround}" '\033[0m'
            sudo apt-get install -y --allow-downgrades docker-ce=$workaround
            info "Installing nvidia-docker2 again..."
            $nvidia_docker_install_cmd
        else
            fatal "There were failures trying to install nvidia-docker2."
        fi
    fi

    # This is required since nvidia-docker2 add nvidia runtime, but not
    # set it as default. If we want pods run with gpu support, we need
    # dockerd started with --default-runtime=nvidia
    info "Updating docker runtime configuration..."
    local dns_servers=$(nmcli dev show|grep "IP4.DNS"|awk '{print "\""$2"\""}'|paste -sd ',' -)
    if [ ! -z $dns_servers ]
    then
        dns_servers="$dns_servers,"
    fi
    # Include Google DNS servers
    dns_servers="$dns_servers\"8.8.4.4\", \"8.8.8.8\""
    info "Updating docker daemon configuration..."
    info "  Configuring DNS entries with $dns_servers..."

    # Docker default bridge subnet is of 172.17.XX which can be routable. If this is the case, you can override the defult
    # configuration by fixing the bridge in the daemon.json. Just add the following in the daemon.json below:
    # "bip": "192.168.1.5/24",
    # "fixed-cidr": "192.168.1.0/25",
    # "fixed-cidr-v6": "2001:db8::/64",

    cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "default-runtime": "nvidia",
    "dns": [$dns_servers]
}
EOF
    if pgrep -x "dockerd" > /dev/null
    then
        set +e
        info "Restarting dockerd..."
        sudo pkill -SIGHUP dockerd
        sudo service docker restart
        set -e
    fi

}

install_docker_compose() {
    local docker_compose_ver
    docker_compose_ver="$(docker-compose version --short 2> /dev/null || true)"
    if [ -n "$docker_compose_ver" ]; then
        info "Docker Compose version ${docker_compose_ver} is already installed. Skipping docker-compose installation..."
        return
    fi
    info "Start installing docker-compose Version ${DOCKER_COMPOSE_VER}..."
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VER}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo chown $(whoami) /usr/local/bin/docker-compose
    info "Successfully installed docker-compose!"
}

install_kubernetes() {
    local kubernetes=$(sudo dpkg --get-selections | grep -v deinstall | grep kuber*)
    if [[ "$kubernetes" != "" ]]; then
        info "The following versions of k8s components are already installed."
        info "- kubectl: $(sudo kubectl version --short)"
        info "- kubelet: $(sudo kubelet --version)"
        info "- kubeadm: $(sudo kubeadm version -o short)"
        local kubernetes_ver=$(kubelet --version | grep -Po '(?<=v)[0-9\.]+')
        if [ $(ver $kubernetes_ver) -lt $(ver $SUPPORTED_K8S_MIN_VER) ]; then
            fatal "Clara doesn't support the Kubernetes version $kubernetes_ver (< $SUPPORTED_K8S_MIN_VER) yet. Please consider upgrade Kubernetes."
        elif [ $(ver $kubernetes_ver) -gt $(ver $SUPPORTED_K8S_MAX_VER) ]; then
            fatal "Clara doesn't support the Kubernetes version $kubernetes_ver (> $SUPPORTED_K8S_MAX_VER) yet. Please consider downgrade Kubernetes."
        else
            info "Skipping Kubernetes installation (version: $KUBERNETES_VER) since Kubernetes is already present."
        fi
        return
    fi

    info "Start installing kubernetes ..."
    add_gpg_key 'https://packages.cloud.google.com/apt/doc/apt-key.gpg'
    # count # of existing item in /etc/apt/sources.list.d/kubernetes.list
    local kube_srclist_count=$(cat /etc/apt/sources.list.d/kubernetes.list 2> /dev/null | grep -c "deb http://apt.kubernetes.io/ kubernetes-xenial main" 2> /dev/null || true)
    if [ $kube_srclist_count -gt 1 ]; then
        # remove duplicate lines
        sudo sed -i '\#deb http://apt.kubernetes.io/ kubernetes-xenial main#d' /etc/apt/sources.list.d/kubernetes.list
        kube_srclist_count=0
    fi
    if [ $kube_srclist_count -eq 0 ]; then
        echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
    fi
    sudo apt-get update
    if ! sudo apt-get install -y kubelet=$KUBERNETES_VER kubeadm=$KUBERNETES_VER kubectl=$KUBERNETES_VER; then
        fatal "There were failures trying to install Kubernetes."
    fi

    # Prevent k8s installation error due to the low "fs.inotify.max_user_watches" value
    # See https://github.com/google/cadvisor/issues/1581
    local max_user_watches=$(cat /proc/sys/fs/inotify/max_user_watches)
    info "Existing value for fs.inotify.max_user_watches: ${max_user_watches}"
    if [ $max_user_watches -lt ${FS_INOTIFY_MAX_USER_WATCHES} ]; then
        info "Setting 'fs.inotify.max_user_watches' to ${FS_INOTIFY_MAX_USER_WATCHES} in /etc/sysctl.conf ..."
        echo fs.inotify.max_user_watches=${FS_INOTIFY_MAX_USER_WATCHES} | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p --system
    fi

    info "Initialize Master Node."
    if ! sudo kubeadm init --pod-network-cidr="10.244.0.0/16"; then
        info "== kubelet status =="
        sudo systemctl status kubelet -l
        info "== kubelet logs in journalctl =="
        sudo journalctl -xeu kubelet
        fatal "Please check what happenes on kubelet"
    fi

    # Run the following as normal user
    sudo -u $SUDO_USER mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    export KUBECONFIG=$HOME/.kube/config

    info "Deploy kubernetes pod network."
    sudo kubectl apply -f $SCRIPT_DIR/kube-flannel.yml
    sudo kubectl apply -f $SCRIPT_DIR/kube-flannel-rbac.yml

    # By default, deployments are not scheduled on the master node. To enable it on a single-node cluster, run:
    kubectl taint nodes --all node-role.kubernetes.io/master-

    info "Install Nvidia Kubernetes GPU Device Plugin"
    kubectl create -f $SCRIPT_DIR/nvidia-device-plugin.yml

    info "Install RBAC Configuration"
    kubectl create -f $SCRIPT_DIR/rbac-config.yaml

    sudo systemctl restart kubelet
    info "Successfully installed kubernetes!"
}

check_coredns() {
    local counter=0
    local counter_timeout=60
    local coredns_status=''
    while true; do
        # Check status of coredns pods
        coredns_status="$(sudo kubectl get pods -n kube-system -o jsonpath='{.items[?(@.metadata.labels.k8s-app == "kube-dns")].status.phase}')"

        # Break if all coredns pod status is 'Running'
        [ -n "$coredns_status" ] && [ "$(echo $coredns_status | xargs -n1 | grep -c -v "Running" || true)" -eq 0 ] && break
        counter=$((counter + 1))
        info "coredns pods are not running yet ..."
        if [ $counter -gt $counter_timeout ]; then
            info "Executing `sudo kubectl get pods -n kube-system | grep 'coredns'` to get status of coredns..."
            sudo kubectl get pods -n kube-system | grep 'coredns'

            if echo $coredns_status | grep -q "CrashLoopBackOff"; then
                info "The status of coredns pod is 'CrashLoopBackOff'!"

                # Check if dnsmasq is set up in /etc/NetworkManager/NetworkManager.conf
                if grep -q "^dns=dnsmasq" /etc/NetworkManager/NetworkManager.conf; then
                    info "It looks like your system is using 'dnsmasq' which can cause the issue."
                    info "Commenting the 'dns=dnsmasq' in /etc/NetworkManager/NetworkManager.conf ..."
                    sudo sed -i '/^dns=dnsmasq/ s/^\(.*\)$/#\1/g' /etc/NetworkManager/NetworkManager.conf
                    info "Restarting network/network-manager/docker services..."

                    sudo service network-manager restart
                    sudo service networking restart
                    sudo pkill -SIGHUP dockerd
                    sudo service docker restart
                    /bin/echo -e "\033[1;37mPlease re-execute this script to finish the prerequisites installation! \033[0m"
                else
                    /bin/echo -e "\033[1;37mPlease re-execute this script after resolving the 'CrashLoopBackOff' issue! \033[0m"
                fi
            fi
            fatal "Timed out for waiting coredns running."
        fi
        sleep 1
    done
}

install_helm() {
    local helm=$(helm --help)
    if [[ $helm == *"helm init"* ]]; then
        info "Skipping helm installation since it is already present."
    else
        local helm_version='helm-v2.15.2-linux-amd64.tar.gz'
        local helm_checksum='a9d2db920bd4b3d824729bbe1ff3fa57ad27760487581af6e5d3156d1b3c2511'
        if ! wget https://storage.googleapis.com/kubernetes-helm/$helm_version; then
            fatal "There were failures trying to get helm for Kubernetes."
        fi
        if [[ $(sha256sum $helm_version) != "$helm_checksum"* ]]; then
            info "Skipping helm installation.  Downloaded file invalid."
            return
        fi

        info "Start installing helm ..."
        tar -C /usr/local/bin --strip-components=1 -zxvf $helm_version
    fi

    helm init --upgrade --force-upgrade --service-account tiller > /dev/null 2>&1
}

check_sudo() {
    info "Checking user privilege..."
    if [ "$EUID" -ne 0 ]
        then echo "Please run as root"
        exit
    fi
    # Set SUDO_USER to 'root' in case the user was logged in as 'root'
    SUDO_USER=${SUDO_USER:-root}
}

disable_swap() {
    # k8s will not be installed if the swap is enabled.
    # https://github.com/kubernetes/kubernetes/issues/53533
    info "Disabling swap ..."
    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
}

update_permissions() {
    sudo chown -Rf $SUDO_USER:$(id -g $SUDO_USER) $HOME/.kube
    sudo chown -Rf $SUDO_USER:$(id -g $SUDO_USER) $HOME/.helm
}

wait_tiller_ready() {
    local tiller_pod=""
    local counter=0
    while true; do
        tiller_pod="$(kubectl get pods -l "name=tiller" --all-namespaces --output=jsonpath='{.items[*].metadata.name}' | xargs | cut -d' ' -f1)"
        [ -n "$tiller_pod" ] && break
        counter=$((counter + 1))
        info "tiller pod $tiller_pod is not started yet ..."
        [ $counter -gt 600 ] && fatal "Timed out for waiting tiller" && break
        sleep 1
    done
    info "Wait until tiller is ready ..."
    kubectl wait --for=condition=Ready pods/${tiller_pod} --namespace kube-system --timeout=600s
    if [ $? -ne 0 ]; then
        info "Timed out waiting for tiller (${tiller_pod}). The followings are the debug information"
        kubectl get pods -n kube-system
        kubectl describe pods/${tiller_pod} -n kube-system
        kubectl logs ${tiller_pod} -n kube-system
    fi
}

check_proxy() {
    if printenv | grep -qi '_proxy='; then
        /bin/echo -e '\033[1;37m
It looks like your system is using a proxy server! \033[0m

If the internet connection is provided through an HTTP Proxy server, docker containers cannot access the internet while building docker images or running containers.
Even if proxies for Docker is set up properly, Clara Operators cannot access other Kubernetes services such as TRTIS because Kubernetes is using a specific service [CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) (default to "10.96.0.0/12") and Clara Deploy is set up to use "10.244.0.0/16" as a pod network CIDR of the Kubernetes node (defined in `bootstrap.sh` script).
Docker needs to be configured to not use proxies for those IP addresses.

To address those issues, you need to add/update `proxies` key in the `~/.docker/config.json` file (if the file does not exist, create it) like below (assuming that the address of the proxy server is `http://proxy.xxxx.edu:8080`) for Docker to have proper proxy settings (See https://docs.docker.com/network/proxy/ for the detailed information):
\033[1;34m
{
    "proxies": {
        "default":
        {
            "httpProxy": "http://proxy.xxxx.edu:8080",
            "httpsProxy": "http://proxy.xxxx.edu:8080",
            "noProxy": "127.0.0.1,10.96.0.0/12,10.244.0.0/16"
        }
    }
}\033[0m
'
    fi
}

main() {
    info "Clara Train SDK System Prerequisites Installation"
    check_sudo
    newline
    ensure_nvidia_gpu_drivers_installed "$@"
    #ensure_package_dependencies
    #disable_swap
    install_nvidia_docker2
    install_docker_compose
    #install_kubernetes
    #check_coredns
    #install_helm
    #update_permissions
    #wait_tiller_ready
    #check_proxy
    #newline
    info "Clara Train SDK Prerequisites installed successfully!"
}

main "$@"
