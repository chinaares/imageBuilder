#!/bin/sh -eux

# local registry server 
#sudo sed -i '/registry\.sumapay\.com$/d' /etc/hosts
#echo '192.161.14.101  registry.sumapay.com' | sudo tee -a /etc/hosts

# install os supplied docker package, maybe too old, so not used
#apt-get -y update
#apt-cache policy docker.io
#apt-get -y install docker.io

# install upgrade docker depend package
apt-get -y update
apt-get -y install apt-transport-https ca-certificates

# Add the new GPG key.
#(W: GPG error: http://apt.dockerproject.org ubuntu-trusty InRelease: 
#The following signatures couldn't be verified because the public key is not available: NO_PUBKEY F76221572C52609D)
# curl -sSL https://apt.dockerproject.org/gpg > docker.gpg.key && echo "c836dc13577c6f7c133ad1db1a2ee5f41ad742d11e4ac860d8e658b2b39e6ac1 docker.gpg.key" | sha256sum -c && sudo apt-key add docker.gpg.key && rm docker.gpg.key
curl -sSL http://192.161.14.180/docker/gpg > docker.gpg.key && echo "c836dc13577c6f7c133ad1db1a2ee5f41ad742d11e4ac860d8e658b2b39e6ac1 docker.gpg.key" | sha256sum -c && sudo apt-key add docker.gpg.key && rm -f docker.gpg.key

# Add docker sources repo
lsb_dist="$(lsb_release -si | tr '[:upper:]' '[:lower:]')"
lsb_release="$(lsb_release -sr)"
lsb_codename="$(lsb_release -sc)"
echo "deb [arch=$(dpkg --print-architecture)] http://apt.dockerproject.org/repo ${lsb_dist}-${lsb_codename} main" > /etc/apt/sources.list.d/docker.list
# or like this
#cat <<'EOF' > /etc/apt/sources.list.d/docker.list
#deb http://apt.dockerproject.org/repo ubuntu-trusty main
#EOF

# Update your APT package index
apt-get -y update
apt-cache policy docker-engine
# For Ubuntu Trusty, and Xenial, it’s recommended to install the linux-image-extra-* 
# kernel packages. The linux-image-extra-* packages allows you use the aufs storage driver.
apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get -y install linux-image-generic-lts-${lsb_codename}
apt-get -y autoremove
# Install Docker.
apt-get -y install docker-engine
#apt-get upgrade docker-engine
# start docker service
#service docker start
#To avoid having to use sudo when you use the docker command, 
#create a Unix group called docker and add users to it. 
#sudo usermod -a -G docker ubuntu
# echo version
docker version

echo "install docker ok."
