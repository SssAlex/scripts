set -x
set -e

[ -f /root/bootstrap.done ] && exit 0

DEBIAN_FRONTEND=noninteractive

swapoff -a
timedatectl set-timezone Europe/Zaporozhye

apt update
apt install -y openvpn
apt install -y ssh-import-id tmux mc vim

useradd -m -r -U -s /bin/bash ansible
usermod -aG sudo ansible

cat << EOF > /etc/sudoers.d/ansible
ansible ALL=(ALL) NOPASSWD:ALL
EOF

mkdir -p  /home/ansible/.ssh
ssh-keygen -q -N "" -b 256 -t ecdsa -f /home/ansible/.ssh/id_ecdsaq -C ansible@ans-ctl
cat << EOF >> /home/ansible/.ssh/authorized_keys
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOLzgA4OZQJcFH9PaXizOAMMJkSGZjliNODQavbmd/IAaoU4UdwNtIT8IReFZtZNEgEp/LQsWVQAY/Okcdq7Tdw= ansible@ans-ctl
EOF
chown -R ansible:ansible  /home/ansible/.ssh/

touch /root/bootstrap.done
