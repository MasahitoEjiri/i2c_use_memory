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

#0~15を10進数➡16進数、A~Fを16進数➡10進数に変える
change_1digit()
{
    local par=$1 #関数に入った引数を定義
    list16=(0 1 2 3 4 5 6 7 8 9 A B C D E F)
    for i in {0..15}
    do
        if [ $par = $i ];then #引数が0～15のときに当てはまる
            echo ${list16[$i]} #その値（順番）に対応する16進数を出す
        fi
    done

    list10=(10 11 12 13 14 15)
    local count=0
    for i in {A..F}
    do
        if [ $par = $i ];then #引数がA~Fのときに当てはまる
            echo ${list10[$count]} #その値（順番）に対応する16進数を出す
        fi
        count=$(($count + 1)) #カウントアップ
    done
}

#引数に与えられた2桁の16進数を10進数に変える
change16to10()
{
    local par=$1 #関数に入った引数を定義
    local par_leng=${#par} #桁数を定義
    local par_0jou=${par:$((par_leng - 1)):1} #0乗目の値を取り出す（何番目：何文字）
    local par_1jou=${par:$((par_leng - 2)):1} #1乗目の値取り出す

    local ten_0jou=$(change_1digit $par_0jou) #一桁ずつ10進数に変換
    local ten_1jou=$(change_1digit $par_1jou)

    echo $((ten_0jou * 1 + ten_1jou * 16 )) #16の累乗分をかけて合算
}

#引数に与えられた255までの10進数を16進数に変える
change10to16()
{
    local par=$1 #関数に入った引数を定義
    local ten_0jou=$(($par % 16)) #16で割った余りを0乗の値に
    local ten_1jou=$(($par / 16)) #16で割った商を1乗の値に

    echo $(change_1digit $ten_1jou)$(change_1digit $ten_0jou) #1乗と0乗の値を16進数に変換し、連続で表示する
}

#指定したアドレスに至るまで、すべてのデータを表示する
alladdress()
{
    fin_address="FF" #アドレス指定
    local cnt_address=0
    while [ $cnt_address -le $(change16to10 $fin_address) ] #指定したアドレスを10進数に変えて挿入
    do
        i2cget -y 1 0x50 0x$(change10to16 $cnt_address) #カウントアドレスを16進数に戻してi2cgetに挿入
        cnt_address=`expr $cnt_address + 1` #カウントアップ
    done
}


#メインループ
if [ $arg_amount -eq 0 ]; then
    alladdress
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
