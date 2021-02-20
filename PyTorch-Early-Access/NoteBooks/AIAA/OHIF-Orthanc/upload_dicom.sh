#!/bin/bash

set -e

DATA_DIR="../dicomSample"
echo "Uploading dicom images from $DATA_DIR to Orthanc..."
echo -ne "\r\n--myboundary\r\nContent-Type: application/dicom\r\n\r\n" > mime.dicom.head
echo -ne "\r\n--myboundary--" > mime.tail
cat /dev/null > dicom.mime
for filename in $DATA_DIR/*.dcm; do
  cat mime.dicom.head $filename >> dicom.mime
done
cat mime.tail >> dicom.mime

curl -X POST -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" \
     http://localhost:8042/dicom-web/studies --data-binary @dicom.mime
rm mime.dicom.head
rm mime.tail
rm dicom.mime
echo "Upload completed"
