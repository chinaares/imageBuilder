#!/bin/bash

set -x

: ${BUILD_VERSION:="v$(date +'%Y%m%d%H%M%S')"}
: ${BUILD_NAME:="CentOS_7.0-x86_64_openstack"}
: ${VM_NAME:="centos_7.0_openstack"}
: ${TEMPLATE_FILE:="template_kvm.json"}
: ${DISK_DIR:="disk"}

if  [ "$1" = "docker" ]
then
   echo "**** Build image with docker engine installed. *****"
   BUILD_NAME="${BUILD_NAME}_d"
   VM_NAME="${VM_NAME}_d"
   TEMPLATE_FILE="template_kvm_docker.json"
   DISK_DIR="disk_d"
fi

export BUILD_NAME
export VM_NAME
export BUILD_VERSION

PWD=`pwd`
FILENAME=${VM_NAME} 
PACKER=/usr/bin/packer

if [ -e "${PWD}/${DISK_DIR}" ];
then
    rm -rf ${PWD}/${DISK_DIR}
fi

if [ ! -e "${PWD}/final_images" ];
then
    mkdir -pv ${PWD}/final_images
fi

$PACKER build ${TEMPLATE_FILE}

cd ${DISK_DIR}
qemu-img convert -c -O qcow2 $FILENAME ${BUILD_NAME}-${BUILD_VERSION}.qcow2
cd -

mv ${PWD}/${DISK_DIR}/${BUILD_NAME}-${BUILD_VERSION}.qcow2 ${PWD}/final_images
rm -rf ${PWD}/${DISK_DIR}
echo "==> Generate files:"
find ${PWD}/final_images -type f -printf "==> %f\n"

echo "Done"