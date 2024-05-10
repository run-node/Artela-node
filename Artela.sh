#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 检查并安装 Node.js 和 npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js 已安装"
    else
        echo "Node.js 未安装，正在安装..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm 已安装"
    else
        echo "npm 未安装，正在安装..."
        sudo apt-get install -y npm
    fi
}

# 检查并安装 PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 已安装"
    else
        echo "PM2 未安装，正在安装..."
        npm install pm2@latest -g
    fi
}

# 检查Go环境
function check_go_installation() {
    if command -v go > /dev/null 2>&1; then
        echo "Go 环境已安装"
        return 0 
    else
        echo "Go 环境未安装，正在安装..."
        return 1 
    fi
}

# 节点安装功能
function install_node() {
    node_address="tcp://localhost:3457"
    install_nodejs_and_npm
    install_pm2

    # 设置变量
    read -r -p "请输入你想设置的节点名称: " NODE_MONIKER
    export NODE_MONIKER=$NODE_MONIKER

    # 更新和安装必要的软件
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd

    # 安装 Go
    if ! check_go_installation; then
        sudo rm -rf /usr/local/go
        curl -L https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
        source $HOME/.bash_profile
        go version
    fi

    # 安装所有二进制文件
    cd $HOME
    git clone https://github.com/artela-network/artela
    cd artela
    git checkout v0.4.7-rc6
    make install

    # 配置artelad
    artelad config chain-id artela_11822-1
    artelad init "$NODE_MONIKER" --chain-id artela_11822-1
    artelad config node tcp://localhost:3457

    # 获取初始文件和地址簿
    curl -L https://snapshots-testnet.nodejumper.io/artela-testnet/genesis.json > $HOME/.artelad/config/genesis.json
    curl -L https://snapshots-testnet.nodejumper.io/artela-testnet/addrbook.json > $HOME/.artelad/config/addrbook.json

    # 配置节点
    SEEDS=""
    PEERS="096d8b3a2fe79791ef307935e0b72afcf505b149@84.247.140.122:24656,a01a5d0015e685655b1334041d907ce2db51c02f@173.249.16.25:45656,8542e4e88e01f9c95db2cd762460eecad2d66583@155.133.26.10:26656,dd5d35fb496afe468dd35213270b02b3a415f655@15.235.144.20:30656,8510929e6ba058e84019b1a16edba66e880744e1@217.76.50.155:656,f16f036a283c5d2d77d7dc564f5a4dc6cf89393b@91.190.156.180:42656,6554c18f24455cf1b60eebcc8b311a693371881a@164.68.114.21:45656,301d46637a338c2855ede5d2a587ad1f366f3813@95.217.200.98:18656"
    sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.artelad/config/config.toml

    # 配置端口
    sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:3458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:3457\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:3460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:3456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":3466\"%" $HOME/.artelad/config/config.toml
    sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:3417\"%; s%^address = \":8080\"%address = \":3480\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:3490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:3491\"%; s%:8545%:3445%; s%:8546%:3446%; s%:6065%:3465%" $HOME/.artelad/config/app.toml
    echo "export Artela_RPC_PORT=$node_address" >> $HOME/.bash_profile
    source $HOME/.bash_profile   

    pm2 start artelad -- start && pm2 save && pm2 startup
    
    # 下载快照
    curl https://testnet-files.itrocket.net/artela/snap_artela.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad

    # 使用 PM2 启动节点进程

    pm2 restart artelad

    echo '====================== 安装完成 ==========================='
    
}

# 查看Artela 服务状态
function check_service_status() {
    pm2 list
}

# Artela 节点日志查询
function view_logs() {
    pm2 logs artelad
}

# 卸载节点功能
function uninstall_node() {
            echo "开始卸载Artela节点..."
            pm2 stop artelad && pm2 delete artelad
            rm -rf $HOME/.artelad $HOME/artela $(which artelad)
            echo "Artela节点卸载完成"
}

# 创建钱包
function add_wallet() {
    artelad keys add wallet
}

# 导入钱包
function import_wallet() {
    artelad keys add wallet --recover
}

# 查询余额
function check_balances() {
    read -p "请输入钱包地址: " wallet_address
    artelad query bank balances "$wallet_address"
}

function walletlist() {
    artelad keys list
}

# 查看节点同步状态
function check_sync_status() {
    artelad status 2>&1 --node $Artela_RPC_PORT | jq .SyncInfo
}

# 创建验证者
function add_validator() {
    read -p "请输入您的钱包名称: " wallet_name
    read -p "请输入您想设置的验证者的名字: " validator_name
    
artelad tx staking create-validator \
--amount 1art \
--from $wallet_name \
--commission-rate 0.075 \
--commission-max-rate 0.1 \
--commission-max-change-rate 0.01 \
--min-self-delegation 1 \
--pubkey $(artelad tendermint show-validator) \
--moniker "$validator_name" \
--identity "artela" \
--details "artela" \
--chain-id artela_11822-1 \
--gas auto --gas-adjustment 1.5 \
-y

}

function Delegate(){
    wget -O Delegate.sh https://raw.githubusercontent.com/run-node/Artela-node/main/Delegate.sh && chmod +x Delegate.sh && ./Delegate.sh
}

# 主菜单
function main_menu() {
    while true; do
        clear
        echo "========================自用脚本 盗者必究========================="
        echo "需要测试网节点部署托管 技术指导 定制脚本 请联系Telegram :https://t.me/linzeusasa"
        echo "需要测试网节点部署托管 技术指导 定制脚本 请联系Wechat :llkkxx001"
        echo "===================Artela最新测试网节点一键部署===================="
        echo "未安装过Artela节点的请创建新钱包，若已有Artela钱包 请执行第三步"
        echo "网址为https://testnet.itrocket.net/artela/staking 请前往网站输入钱包地址 查询验证者信息"
        echo "请选择要执行的功能(1~11):"
        echo "1. 安装节点"
        echo "2. 钱包管理"
        echo "3. 查询信息"
        echo "4. 创建验证者(请确保同步状态为false并且钱包有1art再执行)"
        echo "5. 卸载节点"
        echo "6. 自动质押"
        read -p "请输入选项（1-6）: " OPTION

        case $OPTION in
        1) install_node ;;
        2)
            echo "=========================钱包管理菜单============================"
            echo "请选择要执行的操作:"
            echo "1. 创建钱包"
            echo "2. 导入钱包"
            echo "3. 钱包列表"
            read -p "请输入选项（1-2）: " WALLET_OPTION
            case $WALLET_OPTION in
            1) add_wallet ;;
            2) import_wallet ;;
            3) walletlist ;;
            *) echo "无效选项。" ;;
            esac
            ;;
        3)
            echo "=========================查询信息菜单============================"
            echo "请选择要执行的操作:"
            echo "1. 查看钱包地址余额(请先前往dc-faucet领水)"
            echo "2. 查看节点同步状态"
            echo "3. 查看节点运行状态"
            echo "4. 查看节点运行日志"
            read -p "请输入选项（1-4）: " INFO_OPTION
            case $INFO_OPTION in
            1) check_balances ;;
            2) check_sync_status ;;
            3) check_service_status ;;
            4) view_logs ;;
            *) echo "无效选项。" ;;
            esac
            ;;
        4) add_validator ;;
        5) uninstall_node ;;
        6) Delegate ;; 
        *) echo "无效选项。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done
    
}

# 显示主菜单
main_menu
