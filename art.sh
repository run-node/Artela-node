# 使用expect命令输入密码
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
