#!/bin/bash

set -x

: ${BUILD_VERSION:="v$(date +'%Y%m%d%H%M%S')"}
: ${BUILD_NAME:="Ubuntu_16.04-x86_64_openstack"}
: ${VM_NAME:="ubuntu16.04_openstack"}
: ${TEMPLATE_FILE:="template_kvm.json"}

if  [ "$1" = "docker" ]
then
   echo "**** Build image with docker engine installed. *****"
   BUILD_NAME="${BUILD_NAME}_d"
   VM_NAME="${VM_NAME}_d"
   TEMPLATE_FILE="template_kvm_docker.json"
fi

export BUILD_NAME
export VM_NAME
export BUILD_VERSION

PWD=`pwd`
FILENAME=${VM_NAME}
PACKER=/usr/bin/packer

if [ -e "${PWD}/disk" ];
then
    rm -rf ${PWD}/disk
fi

if [ ! -e "${PWD}/final_images" ];
then
    mkdir -pv ${PWD}/final_images
fi

$PACKER build ${TEMPLATE_FILE}

cd disk
qemu-img convert -c -O qcow2 $FILENAME ${BUILD_NAME}-${BUILD_VERSION}.qcow2
cd -

mv ${PWD}/disk/${BUILD_NAME}-${BUILD_VERSION}.qcow2 ${PWD}/final_images
rm -rf ${PWD}/disk
echo "==> Generate files:"
find ${PWD}/final_images -type f -printf "==> %f\n"

echo "Done"