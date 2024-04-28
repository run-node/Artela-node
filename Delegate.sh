# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/Delegate.sh"



# 安装expect
function install_expect() {
    sudo apt-get update
    sudo apt-get install -y expect

    echo "==============================模块安装完成=============================="

    read -p "按回车键返回主菜单"

  # 返回主菜单
  main_menu
}

# 委托功能
function delegate_staking() {
  # 检查是否存在旧的 cron 任务
  if crontab -l | grep -q '/root/art.sh'; then
    # 如果存在，则先移除旧的任务
    crontab -l | grep -v '/root/art.sh' | crontab -
  fi

  # 写入新的 cron 任务到临时文件
  echo "0 12 * * * sleep \$((RANDOM % 18000)) && /root/art.sh > /tmp/art.log 2>&1" > /tmp/cronjob

  # 将临时文件的内容追加到当前用户的 cron 任务列表中
  crontab -l | cat - /tmp/cronjob | crontab -

  # 清除临时文件
  rm /tmp/cronjob

  # 获取密码和钱包名
  local art_pwd art_wallet
  art_pwd=$(grep -oP 'art_pwd=\K.*' ~/.bash_profile)
  art_wallet=$(grep -oP 'art_wallet=\K.*' ~/.bash_profile)
  art_address=$(grep -oP 'art_address=\K.*' ~/.bash_profile)
  art_validator=$(grep -oP 'art_validator=\K.*' ~/.bash_profile)
  art_amount=$(grep -oP 'art_amount=\K.*' ~/.bash_profile)
  
  # 获取 art.sh 脚本
  wget -O art.sh https://raw.githubusercontent.com/run-node/Artela-node/main/art.sh && chmod +x art.sh

    # 获取密码并替换 art.sh 中的占位符
    sed -i "s|\$pwd|$art_pwd|g" art.sh

    # 获取钱包名并替换 art.sh 中的占位符
    sed -i "s|\$wallet|$art_wallet|g" art.sh

    # 获取质押数量并替换 art.sh 中的占位符
    sed -i "s|\$amount|$art_amount|g" art.sh

    # 获取钱包地址并替换 art.sh 中的占位符
    sed -i "s|\$address|$art_address|g" art.sh

    # 获取验证者地址并替换 art.sh 中的占位符
    sed -i "s|\$validator|$art_validator|g" art.sh


  # 输出信息
  echo "===========================自动质押已开启；每日晚上9点~10点执行==========================="

  read -p "按回车键返回主菜单"

  # 返回主菜单
  main_menu
}

# 查询钱包列表功能
function check_wallet() {
    echo "正在查询中，请稍等"
    artelad keys list

    read -p "按回车键返回主菜单"

     # 返回主菜单
    main_menu
}


# 设置密码功能
function set_password() {
    # 检查 ~/.bash_profile 是否存在，如果不存在则创建
    if [ ! -f ~/.bash_profile ]; then
        touch ~/.bash_profile
    fi

    read -p "请输入创建节点时的密码(自动质押需要输入密码,否则无法自动执行): " new_pwd

    # 检查 ~/.bash_profile 中是否已存在 art_pwd，如果存在则替换为新密码，如果不存在则追加
    if grep -q '^art_pwd=' ~/.bash_profile; then
    sed -i "s|^art_pwd=.*$|art_pwd=$new_pwd|" ~/.bash_profile
    else
    echo "art_pwd=$new_pwd" >> ~/.bash_profile
    fi

    # 输入钱包名
    read -p "请输入钱包名: " wallet_name

    # 检查 ~/.bash_profile 中是否已存在 art_wallet，如果存在则替换为新钱包名，如果不存在则追加
    if grep -q '^art_wallet=' ~/.bash_profile; then
    sed -i "s|^art_wallet=.*$|art_wallet=$wallet_name|" ~/.bash_profile
    else
    echo "art_wallet=$wallet_name" >> ~/.bash_profile
    fi

    echo "正在查询钱包地址"
    # 检查 ~/.bash_profile 中是否已存在 art_address，如果存在则替换为新地址，如果不存在则追加
    if grep -q '^art_address=' ~/.bash_profile; then
    art_address=$(artelad keys show $wallet_name -a)
    sed -i "s|^art_address=.*$|art_address=$art_address|" ~/.bash_profile
    echo "钱包地址为: $art_address"
    else
    art_address=$(artelad keys show $wallet_name -a)
    echo "art_address=$art_address" >> ~/.bash_profile
    echo "钱包地址为: $art_address"
    fi
    echo "正在查询验证者地址"
    # 检查 ~/.bash_profile 中是否已存在 art_validator，如果存在则替换为新验证器，如果不存在则追加
    if grep -q '^art_validator=' ~/.bash_profile; then
    art_validator=$(artelad keys show $wallet_name --bech val -a)
    sed -i "s|^art_validator=.*$|art_validator=$art_validator|" ~/.bash_profile
    echo "验证者地址为: $art_validator"
    else
    art_validator=$(artelad keys show $wallet_name --bech val -a)
    echo "art_validator=$art_validator" >> ~/.bash_profile
    echo "验证者地址为: $art_validator"
    fi

    
    # 输入质押数量
  read -p "请输入每次自动质押时的数量: " amount

    # 检查 ~/.bash_profile 中是否已存在 art_wallet，如果存在则替换为新钱包名，如果不存在则追加
    if grep -q '^art_amount=' ~/.bash_profile; then
    sed -i "s|^art_amount=.*$|art_amount=$amount|" ~/.bash_profile
    else
    echo "art_amount=$amount" >> ~/.bash_profile
    fi

  echo "参数已设置成功，并写入到 ~/.bash_profile 文件中"

  read -p "按回车键返回主菜单"

  # 返回主菜单
  main_menu
}




# 主菜单
function main_menu() {
  clear
  echo "=====================专用脚本 盗者必究==========================="
  echo "需要测试网节点部署托管 技术指导 定制脚本 请联系Telegram :https://t.me/linzeusasa"
  echo "需要测试网节点部署托管 技术指导 定制脚本 请联系Wechat :llkkxx001"
  echo "1. 安装基础环境"
  echo "2. 查询Artela钱包信息"
  echo "3. 配置Artela节点信息"
  echo "4. 开始自动质押Art代币"
  read -p "请输入选项（1-3）: " OPTION

  case $OPTION in
  1) install_expect ;;
  2) check_wallet ;;
  3) set_password ;;
  4) delegate_staking ;;

  *) echo "无效选项。" ;;
  esac
}

# 显示主菜单
main_menu
