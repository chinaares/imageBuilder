#! /bin/sh

set -e

#if [ -z "$1" ]
#then
#    echo 'Error: Registry-mirror url required.'
#    exit 0
#fi

#MIRROR_URL=$1
# add internal distribution to mirror
MIRROR_URL="https://registry.sumapay.com:9443"
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
set_mirror(){
	case "$lsb_dist" in
	    centos)
	    if grep "CentOS release 6" /etc/redhat-release > /dev/null
	    then
		sudo sed -i "s|other_args=|other_args=\"--registry-mirror='$MIRROR_URL'\"|g" /etc/sysconfig/docker
		sudo sed -i "s|OPTIONS=|OPTIONS=\"--registry-mirror='$MIRROR_URL'\"|g" /etc/sysconfig/docker
		sudo service docker restart
				echo "Success."
				exit 0
	    fi
	    if grep "CentOS Linux release 7" /etc/redhat-release > /dev/null
	    then
		sudo cp -n /lib/systemd/system/docker.service /etc/systemd/system/docker.service
		sudo sed -i "s|ExecStart=/usr/bin/dockerd|ExecStart=/usr/bin/docker daemon --registry-mirror=\"$MIRROR_URL\"|g" /etc/systemd/system/docker.service
		sudo systemctl daemon-reload
		sudo service docker restart
				echo "Success."
				exit 0
	    fi

	echo "Error: Set mirror failed, please set registry-mirror manually please."
	exit 1
	;;
	    ubuntu|debian)
	    DOCKER_CONFIG_FILE="/etc/default/docker"
	    if grep "registry-mirror" $DOCKER_CONFIG_FILE > /dev/null
	    then
		sudo sed -i -u -E "s#--registry-mirror='?((http|https)://)?[a-zA-Z0-9.]+'?#--registry-mirror='$MIRROR_URL'#g" $DOCKER_CONFIG_FILE
	    else
		echo 'DOCKER_OPTS="$DOCKER_OPTS --registry-mirror='$MIRROR_URL'"' >> $DOCKER_CONFIG_FILE
		echo $MIRROR_URL
	    fi
	    sudo service docker restart
	    echo "Success."
	    exit 0
		echo "Error: Set mirror failed, please set registry-mirror manually."
	exit 1
	;;
	esac
	echo "Error: Unsupported OS, please set registry-mirror manually."
	exit 1
}
set_mirror
