cat <<'EOF' > /etc/apt/sources.list
deb http://mirrors.zju.edu.cn/ubuntu/ trusty main restricted universe multiverse
deb http://mirrors.zju.edu.cn/ubuntu/ trusty-security main restricted universe multiverse
deb http://mirrors.zju.edu.cn/ubuntu/ trusty-updates main restricted universe multiverse
deb http://mirrors.zju.edu.cn/ubuntu/ trusty-proposed main restricted universe multiverse
deb http://mirrors.zju.edu.cn/ubuntu/ trusty-backports main restricted universe multiverse
deb-src http://mirrors.zju.edu.cn/ubuntu/ trusty main restricted universe multiverse
deb-src http://mirrors.zju.edu.cn/ubuntu/ trusty-security main restricted universe multiverse
deb-src http://mirrors.zju.edu.cn/ubuntu/ trusty-updates main restricted universe multiverse
deb-src http://mirrors.zju.edu.cn/ubuntu/ trusty-proposed main restricted universe multiverse
deb-src http://mirrors.zju.edu.cn/ubuntu/ trusty-backports main restricted universe multiverse
EOF

apt-get update
apt-get install -y --force-yes libglib2.0-0 curl 

echo "UseDNS no" >> /etc/ssh/sshd_config