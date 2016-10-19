# Base install

RELEASEVER=$(sed -e 's/.*release \([0-9]\+\).*/\1/' /etc/redhat-release)

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

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
baseurl=http://192.161.14.180/epel/${RELEASEVER}/\$basearch
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

# install cloud packages
yum --disablerepo=\* --enablerepo=centos7,epel7 -q -y update
yum --disablerepo=\* --enablerepo=centos7,epel7 -q -y install vim openssh-clients \
wget net-tools tcpdump vim-minimal 

# Make ssh faster by not waiting on DNS
echo "UseDNS no" >> /etc/ssh/sshd_config
