#!/bin/bash

script_tytle=$0 #スクリプト名
par=$1 #引数
arg_amount=$# #引数の個数
digit_limit="^.{2}$" #桁数
permit_char="^[a-fA-F0-9]*$" #16進数範囲内の文字
permit_charsize="^[A-F0-9]*$" #小文字を除く

#引数に応じたエラーメッセージ表示
error()
{
    local helpmessage="---------------------------------
    $script_tytle [par]
        par : 00 ～ FF
---------------------------------"
    local message_arg="There are two or more arguments."
    local message_char="This character cannot be used in hexadecimal."
    local message_digit="The number of digits is too few or too many."
    local message_charsize="Small charecters cannot be used. "

    if [ $1 = "arg" ]; then
        echo "$message_arg"
        echo "$helpmessage"
    elif [ $1 = "char" ]; then
        echo "$message_char"
        echo "$helpmessage"
    elif [ $1 = "digit" ]; then
        echo "$message_digit"
        echo "$helpmessage"
    elif [ $1 = "charsize" ]; then
        echo "$message_charsize"
        echo "$helpmessage"
    fi
}

#メインループ
if [ $arg_amount -eq 0 ]; then
    exit
elif [ $arg_amount -gt 1 ]; then
    error arg
    exit 1
elif ! [[ "$par" =~ $permit_char ]]; then
    error char
    exit 2
elif ! [[ "$par" =~ $digit_limit ]]; then
    error digit
    exit 3
elif ! [[ "$par" =~ $permit_charsize ]]; then
    error charsize
    exit 4
fi

i2cget -y 1 0x50 0x$par
