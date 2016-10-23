# Base install
mkdir /etc/yum.repos.d-bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d-bak/
cat <<'EOF' > /etc/yum.repos.d/custom.repo
# yum --disablerepo=\* --enablerepo=centos6-1,centos6-2,epel6 [command]

[centos6-1]
name=CentOS-$releasever - Media
baseurl=http://192.161.14.180/CENTOS6/dvd/DVD1
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

[centos6-updates]
name=CentOS-$releasever - Media
baseurl=http://192.161.14.24/mirrors/centos/6.8/updates/x86_64
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

[centos6-extras]
name=CentOS-$releasever - Media
baseurl=http://192.161.14.24/mirrors/centos/6.8/extras/x86_64
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

[epel6]
name=CentOS-$releasever - Custom
baseurl=http://192.161.14.24/mirrors/epel/6/x86_64
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

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

