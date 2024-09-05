#!/bin/bash

# 检查是否为 root 用户
if [ "$(id -u)" != "0" ]; then
   echo "此脚本必须以 root 用户权限运行" 1>&2
   exit 1
fi

# 安装必备软件
echo "安装必备软件..."
apt update
apt install -y git wget vim nano zsh curl tar zip unzip

# 设置 Zsh 为默认终端
echo "设置 Zsh 为默认终端..."
chsh -s $(which zsh)

# 安装 oh my zsh
echo "安装 oh my zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# 安装 Starship 提示符
echo "安装 Starship 提示符..."
sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y

# 配置 Starship
echo "配置 Starship..."
echo 'eval "$(starship init zsh)"' >> ~/.zshrc

# 修改 SSH 配置
echo "生成 SSH 密钥..."
ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa

echo "配置 SSH 密钥登录..."
cd ~/.ssh
touch authorized_keys
cat id_rsa.pub >> authorized_keys

echo "修改 SSH 配置..."
echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
systemctl restart ssh

# 修改 Swap 分区
echo "修改 Swap 分区...，感谢作者https://www.superbin.cc/windows/557.html"

Green="\033[36m"
Font="\033[0m"
Red="\033[31m" 

add_swap(){
    echo -e "${Green}请输入需要添加的swap(建议为内存的1.5-2倍)${Font}"
    read -p "请输入swap数值(单位M):" swapsize

    #检查是否存在swap
    grep -q "swap" /etc/fstab

    #如果不存在将为其创建swap
    if [ $? -ne 0 ]; then
        echo -e "${Green}swap未发现，正在为其创建swap${Font}"
        fallocate -l ${swapsize}M /swap
        chmod 600 /swap
        mkswap /swap
        swapon /swap
        echo '/swap none swap defaults 0 0' >> /etc/fstab
        echo -e "${Green}swap创建成功，并查看信息：${Font}"
        cat /proc/swaps
        cat /proc/meminfo | grep Swap
    else
        echo -e "${Red}swap已存在，swap设置失败，请先运行脚本删除swap后重新设置！${Font}"
    fi
}

del_swap(){
    #检查是否存在swap
    grep -q "swap" /etc/fstab

    #如果存在就将其移除
    if [ $? -eq 0 ]; then
        echo -e "${Green}swap已发现，正在将其移除...${Font}"
        sed -i '/swap/d' /etc/fstab
        echo "3" > /proc/sys/vm/drop_caches
        swapoff -a
        rm -f /swap
        echo -e "${Green}swap已删除！${Font}"
    else
        echo -e "${Red}swapfile未发现，swap删除失败！${Font}"
    fi
}

# Swap 修改菜单
echo -e "———————————————————————————————————————"
echo -e "${Green}Linux VPS一键添加/删除swap脚本${Font}"
echo -e "${Green}1、添加swap${Font}"
echo -e "${Green}2、删除swap${Font}"
echo -e "———————————————————————————————————————"
read -p "请输入数字 [1-2]:" num
case "$num" in
    1)
    add_swap
    ;;
    2)
    del_swap
    ;;
    *)
    echo -e "${Green}请输入正确数字 [1-2]${Font}"
    ;;
esac

# 开启 BBR
echo "开启 BBR..."
uname -r
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# 检查 BBR 是否成功开启
if sysctl net.ipv4.tcp_available_congestion_control | grep -q bbr; then
    echo -e "${Green}BBR 已成功开启！${Font}"
else
    echo -e "${Red}BBR 开启失败，请检查您的系统是否支持 BBR。${Font}"
fi

echo "所有操作完成！请检查配置是否正确。"

# 提示用户下载私钥
echo "请将 ~/.ssh/id_rsa 私钥下载到客户端以使用密钥登录。"