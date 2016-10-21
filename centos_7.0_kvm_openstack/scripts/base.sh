# Base install
mkdir /etc/yum.repos.d-bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d-bak/
cat <<'EOF' > /etc/yum.repos.d/custom.repo
# yum --disablerepo=\* --enablerepo=centos7,epel7 [command]

[centos7]
name=CentOS-$releasever - Media
baseurl=http://192.161.14.180/CENTOS7/dvd/centos
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[epel7]
name=CentOS-$releasever - Media
baseurl=http://192.161.14.24/mirrors/epel/7/x86_64
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

echo "==> Applying updates"
yum -y update
yum -y install deltarpm vim-minimal wget curl openssh-server openssh-clients net-tools tcpdump

# Install root certificates
yum -y install ca-certificates
#To enable the hypervisor to reboot or shutdown an instance
yum -y install acpid
systemctl enable acpid

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

