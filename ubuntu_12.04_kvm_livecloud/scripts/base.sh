cat <<'EOF' > /etc/apt/sources.list
deb http://cn.archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse
deb http://cn.archive.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse
deb http://cn.archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse
deb http://cn.archive.ubuntu.com/ubuntu/ precise-proposed main restricted universe multiverse
deb http://cn.archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse
deb-src http://cn.archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse
deb-src http://cn.archive.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse
deb-src http://cn.archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse
deb-src http://cn.archive.ubuntu.com/ubuntu/ precise-proposed main restricted universe multiverse
deb-src http://cn.archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse
EOF

apt-get update
apt-get install -y --force-yes chkconfig libglib2.0-0 curl 

echo "UseDNS no" >> /etc/ssh/sshd_config
sed -i "s/nameserver .*/nameserver 8.8.8.8/" /etc/resolv.conf 