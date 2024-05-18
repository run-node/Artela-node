# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/Delegate.sh"



# 安装expect
function install() {
    sudo apt-get update
    sudo apt-get install -y expect
    sudo apt install screen

    echo "==============================模块安装完成=============================="

    read -p "按回车键返回主菜单"

  # 返回主菜单
  main_menu
}

# 委托功能
function delegate_staking() {

  if ! command -v screen &> /dev/null
    then
        sudo apt install screen
  fi

  # 获取密码和钱包名
  local art_pwd art_wallet
  art_pwd=$(grep -oP 'art_pwd=\K.*' ~/.bashrc)
  art_wallet=$(grep -oP 'art_wallet=\K.*' ~/.bashrc)
  art_address=$(grep -oP 'art_address=\K.*' ~/.bashrc)
  art_validator=$(grep -oP 'art_validator=\K.*' ~/.bashrc)
  art_amount=$(grep -oP 'art_amount=\K.*' ~/.bashrc)
  
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

    # 获取port并替换 art.sh 中的占位符
    Artela_RPC_PORT=$(grep -m 1 -E '^export Artela_RPC_PORT=' .bash_profile | cut -d= -f2-)
    # 如果未找到 Artela_RPC_PORT 参数，则设置默认值
    if [ -z "$Artela_RPC_PORT" ]; then
        Artela_RPC_PORT="tcp://47.254.66.177:26657"
    fi

    # 替换占位符
    sed -i "s|\$Artela_RPC_PORT|$Artela_RPC_PORT|g" art.sh

  # 检查并关闭已存在的 screen 会话
  if screen -list | grep -q delegate; then
    screen -S delegate -X quit
    echo "正在关闭之前设置的自动质押······"
  fi

  # 创建一个screen会话并运行命令
  screen -dmS delegate bash -c './art.sh'
  echo "===========自动质押已开启；每隔3~10小时自动质押(保证交互时间不一致)==========="
  echo "执行完后请前往网站查询钱包地址确保有tx记录----https://testnet.itrocket.net/artela"
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
    # 检查 ~/.bashrc 是否存在，如果不存在则创建
    if [ ! -f ~/.bashrc ]; then
        touch ~/.bashrc
    fi

    read -p "请输入创建节点时的密码(自动质押需要输入密码,否则无法自动执行): " new_pwd

    # 检查 ~/.bashrc 中是否已存在 art_pwd，如果存在则替换为新密码，如果不存在则追加
    if grep -q '^art_pwd=' ~/.bashrc; then
    sed -i "s|^art_pwd=.*$|art_pwd=$new_pwd|" ~/.bashrc
    else
    echo "art_pwd=$new_pwd" >> ~/.bashrc
    fi

    # 输入钱包名
    read -p "请输入钱包名: " wallet_name

    # 检查 ~/.bashrc 中是否已存在 art_wallet，如果存在则替换为新钱包名，如果不存在则追加
    if grep -q '^art_wallet=' ~/.bashrc; then
    sed -i "s|^art_wallet=.*$|art_wallet=$wallet_name|" ~/.bashrc
    else
    echo "art_wallet=$wallet_name" >> ~/.bashrc
    fi

    echo "正在查询钱包地址"
    # 检查 ~/.bashrc 中是否已存在 art_address，如果存在则替换为新地址，如果不存在则追加
    if grep -q '^art_address=' ~/.bashrc; then
    art_address=$(artelad keys show $wallet_name -a)
    sed -i "s|^art_address=.*$|art_address=$art_address|" ~/.bashrc
    echo "钱包地址为: $art_address"
    else
    art_address=$(artelad keys show $wallet_name -a)
    echo "art_address=$art_address" >> ~/.bashrc
    echo "钱包地址为: $art_address"
    fi
    echo "正在查询验证者地址"
    # 检查 ~/.bashrc 中是否已存在 art_validator，如果存在则替换为新验证器，如果不存在则追加
    if grep -q '^art_validator=' ~/.bashrc; then
    art_validator=$(artelad keys show $wallet_name --bech val -a)
    sed -i "s|^art_validator=.*$|art_validator=$art_validator|" ~/.bashrc
    echo "验证者地址为: $art_validator"
    else
    art_validator=$(artelad keys show $wallet_name --bech val -a)
    echo "art_validator=$art_validator" >> ~/.bashrc
    echo "验证者地址为: $art_validator"
    fi

    
    # 输入质押数量
  read -p "请输入每次自动质押时的数量(建议1个): " amount

    # 检查 ~/.bashrc 中是否已存在 art_wallet，如果存在则替换为新钱包名，如果不存在则追加
    if grep -q '^art_amount=' ~/.bashrc; then
    sed -i "s|^art_amount=.*$|art_amount=$amount|" ~/.bashrc 
    else
    echo "art_amount=$amount" >> ~/.bashrc 
    fi

  echo "参数已设置成功，并写入到 ~/.bashrc  文件中"

  read -p "按回车键返回主菜单"

  # 返回主菜单
  main_menu
}

function check_logs(){
screen -r delegate
}


# 主菜单
function main_menu() {
  clear
  echo "=====================专用脚本 盗者必究==========================="
  echo "需要测试网节点部署托管 技术指导 定制脚本 请联系Telegram :https://t.me/linzeusasa"
  echo "1. 安装基础环境"
  echo "2. 查询Artela钱包信息"
  echo "3. 配置Artela节点信息"
  echo "4. 开始自动质押Art代币(如果之前已经配置过Artela节点信息，直接执行该步骤)"
  echo "5. 查询质押日志(关闭会话时请执行Ctrl+A 然后D 如果操作失误请重新执行第4步)"
  read -p "请输入选项（1-5）: " OPTION

  case $OPTION in
  1) install ;;
  2) check_wallet ;;
  3) set_password ;;
  4) delegate_staking ;;
  5) check_logs ;;

  *) echo "无效选项。" ;;
  esac
}

# 显示主菜单
main_menu
