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
    echo "将在24~28小时内继续自动质押art"
    
    # 等待24到28小时
    sleep $((24 * 3600 + RANDOM % (4 * 3600)))
done
