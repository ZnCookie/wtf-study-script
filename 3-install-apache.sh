#!/bin/bash

# 检查当前用户是否为root
if [ "$(id -u)" != "0" ]; then
    echo "错误：该脚本需要以root用户权限执行。" 1>&2
    exit 1
fi

# 安装httpd服务
dnf install httpd -y
clear

# 设置SELinux
echo "设置SELinux..."
setenforce 0
echo ""

# 设置防火墙放行
echo "添加防火墙规则..."
firewall-cmd --permanent --add-service=http
echo ""
echo "重载防火墙配置..."
firewall-cmd --reload
echo ""

# 启用httpd服务
echo "重启httpd服务..."
systemctl restart httpd
systemctl enable httpd

# 查看httpd服务状态
systemctl status httpd