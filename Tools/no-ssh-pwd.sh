#!/bin/bash

# 修改 SSH 配置以禁用密码登录
echo "禁用 SSH 密码登录..."
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# 重启 SSH 服务
echo "重启 SSH 服务..."
systemctl restart sshd

echo "SSH 配置已更新，密码登录已禁用。"