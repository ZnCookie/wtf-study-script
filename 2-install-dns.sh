#!/bin/bash

# 检查当前用户是否为root
if [ "$(id -u)" != "0" ]; then
    echo "错误：该脚本需要以root用户权限执行。" 1>&2
    exit 1
fi

# 安装BIND
dnf install bind bind-chroot bind-utils -y

# 备份named.conf
cp -n /etc/named.conf /etc/named.conf.bak

# 修改allow-query为any，修改dnssec-validation为no
sed -i -e 's/allow-query     { \(.*\); };/allow-query     { any; };/g' -e 's/dnssec-validation yes;/dnssec-validation no;/g' -e 's/listen-on port 53 { 127.0.0.1; };/listen-on port 53 { any; };/g' /etc/named.conf

# 读取用户输入的域名和IP
read -p "请输入域名（例如 example.com）: " DOMAIN
read -p "请输入IP（例如 1.43.168.192）：" IP_ADDRESS
read -p "请再输入IP（例如 192.168.43.1）：" IP_ADDRESS_TRUE
echo ""

# 创建区域配置文件named.zones，添加正向解析和反向解析
echo "我们新建了 /etc/named.zones 并在里面添加了一些东西"
cat > /etc/named.zones << EOF
zone "${DOMAIN}" IN {
	type master;
	file "${DOMAIN}.zone";
	allow-update { none; };
};
zone "${IP_ADDRESS}.in-addr.arpa" IN {
        type master;
        file "${IP_ADDRESS}.zone";
        allow-update { none; };
};
EOF

# 检查 /etc/named.conf 文件中是否存在 include "/etc/named.zones";
if ! grep -q 'include "/etc/named.zones";' /etc/named.conf; then
    # 如果不存在，则添加它
    echo 'include "/etc/named.zones";' >> /etc/named.conf
fi

# 创建正向解析声明文件
echo "新建了 /var/named/${DOMAIN}.zone 正向解析声明文件"
cat > "/var/named/${DOMAIN}.zone" << EOF
\$TTL 1D
@	IN SOA  @ rname.invalid. (
                                  	0	; serial
                                        1D	; refresh
                                        1H	; retry
                                        1W	; expire
                                        3H )    ; minimum
@	IN	NS	dns.${DOMAIN}.
dns	IN	A	${IP_ADDRESS_TRUE}
WWW1	IN	A	${IP_ADDRESS_TRUE}
WWW2	IN	A	${IP_ADDRESS_TRUE}
EOF

# 创建反向解析声明文件
echo "新建了 /var/named/${IP_ADDRESS}.zone 反向解析声明文件"
cat > "/var/named/${IP_ADDRESS}.zone" << EOF
\$TTL 1D
@	IN SOA  @ rname.invalid. (
                                  	0	; serial
                                        1D	; refresh
                                        1H	; retry
                                        1W	; expire
                                        3H )    ; minimum
@	IN NS	dns.${DOMAIN}.
1	IN PTR	dns.${DOMAIN}.
1	IN PTR  www1.${DOMAIN}.
1       IN PTR  www2.${DOMAIN}.
EOF

# 设置防火墙放行&修改配置文件权限
echo "添加防火墙规则..."
firewall-cmd --permanent --add-service=dns
echo "重载防火墙配置..."
firewall-cmd --reload
chgrp named /etc/named.conf /etc/named.zones
chgrp named /var/named/${DOMAIN}.zone /var/named/${IP_ADDRESS}.zone

# 重启服务
echo "配置完成，使用 systemctl restart named 重启服务"
systemctl restart named
