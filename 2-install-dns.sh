#!/bin/bash

# 检查当前用户是否为root
if [ "$(id -u)" != "0" ]; then
    echo "错误：该脚本需要以root用户权限执行。" 1>&2
    exit 1
fi

# 安装BIND
dnf install bind bind-chroot bind-utils -y
clear

# 备份named.conf
cp -n /etc/named.conf /etc/named.conf.bak

# 修改allow-query为any，修改dnssec-validation为no
sed -i -e 's/allow-query     { \(.*\); };/allow-query     { any; };/g' -e 's/dnssec-validation yes;/dnssec-validation no;/g' -e 's/listen-on port 53 { 127.0.0.1; };/listen-on port 53 { any; };/g' /etc/named.conf

# 读取用户输入的域名
read -p "请输入域名（例如 example.com）: " DOMAIN
echo ""

# 创建区域配置文件named.zones，添加正向解析和反向解析
echo "我们新建了 /etc/named.zones 并在里面添加了一些东西..."
cat > /etc/named.zones << EOF
zone "$DOMAIN" IN {
	type master;
	file "$DOMAIN.zone";
	allow-update { none; };
};
zone "1.10.168.192.in-addr.arpa" IN {
        type master;
        file "1.10.168.192.zone";
        allow-update { none; };
};
EOF

# 检查 /etc/named.conf 文件中是否存在 include "/etc/named.zones";
if ! grep -q 'include "/etc/named.zones";' /etc/named.conf; then
    # 如果不存在，则添加它
    echo 'include "/etc/named.zones";' >> /etc/named.conf
fi

# 创建正向解析声明文件
echo "新建了 /var/named/$DOMAIN.zone 正向解析声明文件，您可能需要修改它(添加解析记录)"
cat > "/var/named/$DOMAIN.zone" << EOF
\$TTL 1D
@	IN SOA  @ rname.invalid. (
                                  	0	; serial
                                        1D	; refresh
                                        1H	; retry
                                        1W	; expire
                                        3H )    ; minimum
EOF

# 创建反向解析声明文件
echo "新建了 /var/named/1.10.168.192.zone 反向解析声明文件，您可能需要修改它(添加解析记录)"
cat > "/var/named/1.10.168.192.zone" << EOF
\$TTL 1D
@	IN SOA  @ rname.invalid. (
                                  	0	; serial
                                        1D	; refresh
                                        1H	; retry
                                        1W	; expire
                                        3H )    ; minimum
EOF

echo "您可以参考 /var/named 下的 named.localhost 和 named.loopback"
echo ""
echo "注意:你必须有一个NS记录"
echo "NS/NX/CNAME记录没有设置对应的A/AAAA记录时会导致服务启动失败"
echo ""


# 设置防火墙放行&修改配置文件权限
echo "添加防火墙规则..."
firewall-cmd --permanent --add-service=dns
echo ""
echo "重载防火墙配置..."
firewall-cmd --reload
chgrp named /etc/named.conf /etc/named.zones
chgrp named /var/named/$DOMAIN.zone /var/named/1.10.168.192.zone

echo "配置完成后，使用 systemctl restart named 重启服务"
echo "正常来说不应该输出任何内容"
echo "使用 systemctl status named 可以查看具体情况"
