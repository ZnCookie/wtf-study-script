#!/bin/bash

# 检查当前用户是否为root
if [ "$(id -u)" != "0" ]; then
    echo "错误：该脚本需要以root用户权限执行。" 1>&2
    exit 1
fi

# 安装httpd服务
dnf install httpd -y

# 设置SELinux
echo "设置SELinux..."
setenforce 0

# 设置防火墙放行
echo "添加防火墙规则..."
firewall-cmd --permanent --add-service=http
echo "重载防火墙配置..."
firewall-cmd --reload

# 读取用户输入的域名和IP
read -p "请输入域名（例如 example.com）: " DOMAIN
read -p "请输入IP（例如 192.168.43.1）: " IP_ADDRESS

# 写入配置文件
mkdir /var/www/www1 /var/www/www2
echo "www1.${DOMAIN}'s web." > /var/www/www1/index.html
echo "www2.${DOMAIN}'s web." > /var/www/www2/index.html
cat > /etc/httpd/conf.d/vhost.conf << EOF
<Virtualhost ${IP_ADDRESS}>
    DocumentRoot /var/www/www1
    ServerName www1.${DOMAIN}
</Virtualhost>

<Virtualhost ${IP_ADDRESS}>
    DocumentRoot /var/www/www2
    ServerName www2.${DOMAIN}
</Virtualhost>
EOF

# 启用httpd服务
echo "重启httpd服务..."
systemctl restart httpd
systemctl enable httpd

# 查看httpd服务状态
systemctl status httpd
