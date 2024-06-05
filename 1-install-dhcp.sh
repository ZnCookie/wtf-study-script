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
subnet 192.168.10.0 netmask 255.255.255.0 {	#设置子网地址和子网掩码
  range 192.168.10.31 192.168.10.200;	#DHCP分配的IP范围
  option domain-name-servers 192.168.10.1;	#DNS服务器
  option routers 192.168.10.254;	#网关
  option broadcast-address 192.168.10.255;	#广播地址
  default-lease-time 600;	#默认租约时间
  max-lease-time 7200;	#最大租约时间
}
host Client2 {	#固定IP分配
  hardware ethernet 00:0c:29:08:5b:ca;	#MAC地址
  fixed-address 192.168.10.105;	#固定IP
}
EOF

# 启用dhcpd服务
systemctl restart dhcpd
systemctl enable dhcpd

# 查看dhcpd服务状态
systemctl status dhcpd

clear
echo "配置文件在/etc/dhcp/dhcpd.conf"
echo "备份在/etc/dhcp/dhcpd.conf.bak"
echo "默认采用的子网为192.168.10.0/24，你可能需要根据实际情况修改配置文件"
echo "注意：如果dhcpd报错，请*首先*检查当前服务器配置的IP地址！"
