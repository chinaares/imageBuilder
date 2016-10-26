cat <<'EOF' > /etc/apt/sources.list
deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
EOF

echo "
Acquire::http::Proxy \"http://192.161.14.179:3142\";
Acquire::https::Proxy \"http://192.161.14.179:3142\";
Acquire::ftp::Proxy \"http://192.161.14.179:3142\";
"| sudo tee /etc/apt/apt.conf.d/90-apt-proxy.conf

apt-get update
apt-get -y --force-yes dist-upgrade
PACKAGES="
libglib2.0-0
curl
emacs24-nox
htop
nmon
slurm
tcpdump
unzip
vim-nox
"
apt-get install -y --force-yes $PACKAGES

# Add packer user to sudoers.
echo "packer        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/packer
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
