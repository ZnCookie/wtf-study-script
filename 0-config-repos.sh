#!/bin/bash

# 检查当前用户是否为root
if [ "$(id -u)" != "0" ]; then
    echo "错误：该脚本需要以root用户权限执行。" 1>&2
    exit 1
fi

# 挂载CD-ROM到/media
mount /dev/cdrom /media

# 删除原有软件源防止报错
rm -rf /etc/yum.repos.d/*.repo
 
# 创建Yum仓库文件
echo "[Media]
name=Media
baseurl=file:///media/BaseOS
gpgcheck=0
enabled=1

[rhel8-AppStream]
name=rhel8-AppStream
baseurl=file:///media/AppStream
gpgcheck=0
enabled=1" > /etc/yum.repos.d/dvd.repo

# 清理Yum缓存
yum clean all

# 建立新的元数据缓存
yum makecache
