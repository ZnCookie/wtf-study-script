#!/bin/bash

# 检查当前用户是否为root
if [ "$(id -u)" != "0" ]; then
    echo "错误：该脚本需要以root用户权限执行。" 1>&2
    exit 1
fi

# 安装dhcp-server
dnf install dhcp-server -y

# 备份dhcpd.conf
cp -n /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak

# 配置dhcp-server
cat > /etc/dhcp/dhcpd.conf <<'EOF'
subnet 192.168.10.0 netmask 255.255.255.0 {
  range 192.168.10.31 192.168.10.200;
  option domain-name-servers 192.168.10.1;
  option routers 192.168.10.254;
  option broadcast-address 192.168.10.255;
  default-lease-time 600;
  max-lease-time 7200;
}
host Client2 {
  hardware ethernet 00:0c:29:08:5b:ca;
  fixed-address 192.168.10.105;
}
EOF

# 启用dhcpd服务
systemctl restart dhcpd
systemctl enable dhcpd

# 查看dhcpd服务状态
systemctl status dhcpd

clear
echo "你可能需要根据实际情况修改配置文件!"
echo "配置文件在/etc/dhcp/dhcpd.conf"
echo "备份在/etc/dhcp/dhcpd.conf.bak"
