#!/bin/bash

# 关闭错误退出
set +e

while true; do
    expect -c '
    spawn artelad tx staking delegate $validator $amountart --from $address --chain-id artela_11822-1 --gas 300000 --node tcp://47.254.66.177:26657
    expect "Enter keyring passphrase (attempt 1/3):"
    send "$pwd\r"
    expect {
        -re {confirm transaction before signing and broadcasting \[y/N\]:\s*$} {
            send "y\r"
            exp_continue
        }
        eof
    }
    '
    echo "将在1~5小时内继续自动质押art"
    current_time=$(TZ=UTC-8 date +"%Y-%m-%d %H:%M:%S")
    echo "当前时间（UTC+8）: $current_time"
    
    # 等待1到5小时
    sleep $((10800 + RANDOM % 25200))
done
