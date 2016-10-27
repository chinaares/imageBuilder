#! /bin/sh
echo "
************************************************************************
* Docker requires a 64-bit OS and version 3.10 or higher of the Linux  *
* kernel.  CentOS 6.x not supported by latest docker version           *
************************************************************************
"
# local registry server 
#sudo sed -i '/registry\.sumapay\.com$/d' /etc/hosts
#echo '192.161.14.101  registry.sumapay.com' | sudo tee -a /etc/hosts

# Add docker sources repo
lsb_dist=''
command_exists() {
    command -v "$@" > /dev/null 2>&1
}
if command_exists lsb_release; then
    lsb_dist="$(lsb_release -si)"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
    lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/debian_version ]; then
    lsb_dist='debian'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/fedora-release ]; then
    lsb_dist='fedora'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
    lsb_dist="$(. /etc/os-release && echo "$ID")"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/centos-release ]; then
    lsb_dist="$(cat /etc/*-release | head -n1 | cut -d " " -f1)"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/redhat-release ]; then
    lsb_dist="$(cat /etc/*-release | head -n1 | cut -d " " -f1)"
fi
lsb_dist="$(echo $lsb_dist | cut -d " " -f1)"
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
dist_version="$(rpm -q --whatprovides redhat-release --queryformat "%{VERSION}\n" | sed 's/\/.*//' | sed 's/\..*//' | sed 's/Server*//')"

echo "[docker-main-repo]
name=Docker main Repository
baseurl=http://192.161.14.24/mirrors/docker/yum/repo/${lsb_dist}${dist_version}
enabled=1
gpgcheck=1
gpgkey=http://192.161.14.24/mirrors/docker/yum/gpg" | sudo tee /etc/yum.repos.d/docker-main.repo

# Install Docker.
yum -y -q update
if [ "$lsb_dist" = "fedora" ] && [ "$dist_version" -ge "22" ]; then
	(
		dnf -y -q install docker-engine
	)
else
	(
		#yum -y -q install docker-engine
		# for centos 6
		yum -y -q install docker-io 
		#echo "none   /sys/fs/cgroup          cgroup  defaults        0 0" >> /etc/fstab 
	)
fi

# systemctl start docker.service
# systemctl enable docker.service
service docker start
chkconfig docker on
#To avoid having to use sudo when you use the docker command, 
#create a Unix group called docker and add users to it. 
usermod -a -G dockerroot centos
# echo version
#docker version

echo "install docker ok."
