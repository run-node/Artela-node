#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/Delegate.sh"


# 委托功能
function delegate_staking() {

}

# 设置密码功能
function set_password() {
  read -p "请输入密码: " new_pwd
  echo "pwd=\"$new_pwd\"" >> ~/.bash_profile
  echo "密码已设置，并写入到 ~/.bash_profile 文件中。"
}

# 主菜单
function main_menu() {
  clear
  echo "1. 委托功能"
  echo "2. 设置密码"
  read -p "请输入选项（1-3）: " OPTION

  case $OPTION in
  1) delegate_staking ;;
  2) set_password ;;
  *) echo "无效选项。" ;;
  esac
}

# 显示主菜单
main_menu
