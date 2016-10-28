cat <<'EOF' > /etc/apt/sources.list
deb http://mirrors.ustc.edu.cn/debian jessie main contrib non-free
deb-src http://mirrors.ustc.edu.cn/debian jessie main contrib non-free
deb http://mirrors.ustc.edu.cn/debian jessie-proposed-updates main contrib non-free
deb-src http://mirrors.ustc.edu.cn/debian jessie-proposed-updates main contrib non-free
deb http://mirrors.ustc.edu.cn/debian jessie-updates main contrib non-free
deb-src http://mirrors.ustc.edu.cn/debian jessie-updates main contrib non-free
deb http://mirrors.ustc.edu.cn/debian-security/ jessie/updates main contrib non-free
deb-src http://mirrors.ustc.edu.cn/debian-security/ jessie/updates main contrib non-free
EOF

<<<<<<< HEAD
=======
cat <<'EOF' > /etc/apt/sources.list
deb http://mirrors.163.com/debian/ jessie main contrib non-free
deb-src http://mirrors.163.com/debian jessie main contrib non-free
deb http://mirrors.163.com/debian/ jessie-proposed-updates main contrib non-free
deb-src http://mirrors.163.com/debian/ jessie-proposed-updates main contrib non-free
deb http://mirrors.163.com/debian/ jessie-updates main contrib non-free
deb-src http://mirrors.163.com/debian/ jessie-updates main contrib non-free
deb http://mirrors.163.com/debian-security/ jessie/updates main contrib non-free
deb-src http://mirrors.163.com/debian-security/ jessie/updates main contrib non-free
EOF

>>>>>>> 892db811ad8dcdd500458b53d6789bad2000b47e
echo "
Acquire::http::Proxy \"http://192.161.14.179:3142\";
Acquire::https::Proxy \"http://192.161.14.179:3142\";
Acquire::ftp::Proxy \"http://192.161.14.179:3142\";
"| sudo tee /etc/apt/apt.conf.d/90-apt-proxy.conf

apt-get update
apt-get -y --force-yes dist-upgrade

#Unable to correct missing packages.
#E: Failed to fetch http://mirrors.ustc.edu.cn/debian/pool/main/liby/libyaml/libyaml-0-2_0.1.6-3_amd64.deb  Size mismatch
wget http://mirrors.ustc.edu.cn/debian/pool/main/liby/libyaml/libyaml-0-2_0.1.6-3_amd64.deb \
-O /tmp/libyaml-0-2_0.1.6-3_amd64.deb  && \
dpkg -i /tmp/libyaml-0-2_0.1.6-3_amd64.deb 
#E: Failed to fetch http://mirrors.ustc.edu.cn/debian/pool/main/e/emacsen-common/emacsen-common_2.0.8_all.deb  Size mismatch
wget http://mirrors.ustc.edu.cn/debian/pool/main/e/emacsen-common/emacsen-common_2.0.8_all.deb \
-O /tmp/emacsen-common_2.0.8_all.deb  && \
dpkg -i /tmp/emacsen-common_2.0.8_all.deb
#E: Failed to fetch http://mirrors.ustc.edu.cn/debian/pool/main/n/nmon/nmon_14g+debian-1_amd64.deb  Size mismatch
wget http://mirrors.ustc.edu.cn/debian/pool/main/n/nmon/nmon_14g+debian-1_amd64.deb \
-O /tmp/nmon_14g+debian-1_amd64.deb  && \
dpkg -i /tmp/nmon_14g+debian-1_amd64.deb

PACKAGES="
chkconfig
libglib2.0-0
curl
emacs24-nox
htop
nmon
slurm
tcpdump
unzip
vim-nox
sudo
"
apt-get install -y --force-yes $PACKAGES

cat <<'EOF' > /root/.bashrc
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
force_color_prompt=yes

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

alias grep='grep --color=auto'
alias l.='ls -d .* --color=auto'
alias ll='ls -l --color=auto'
alias ls='ls --color=auto'
export EDITOR=vim
export VISUAL=vim
EOF


