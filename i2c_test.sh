#!/bin/bash

script_tytle=$0 #スクリプト名
par=$1 #引数
arg_amount=$# #引数の個数
digit_limit="^.{2}$" #桁数
permit_char="^[a-fA-F0-9]*$" #16進数範囲内の文字
permit_charsize="^[A-F0-9]*$" #小文字を除く
permit_csv="[cC][sS][vV]$" #csvファイル指定(.も判定したいけど保留)
i2cline=0
memory="0x50"

#引数に応じたエラーメッセージ表示
error()
{
    local helpmessage="---------------------------------
    $script_tytle [par]
        par : 00 ～ FF
---------------------------------"
    local helpmessage_write="---------------------------------
    $script_tytle [file.csv]
---------------------------------"
    local message_arg="There are two or more arguments."
    local message_char="This character cannot be used in hexadecimal."
    local message_digit="The number of digits is too few or too many."
    local message_charsize="Small charecters cannot be used. "
    local message_nonepar="Please enter the filename."
    local message_notcsv="Only CSV files can be used."
    local message_notexist="The file was not found."
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
    elif [ $1 = "nonepar" ]; then
        echo "$message_nonepar"
        echo "$helpmessage_write"
    elif [ $1 = "argwrite" ]; then
        echo "$message_arg"
        echo "$helpmessage_write"
    elif [ $1 = "notcsv" ]; then
        echo "$message_notcsv"
        echo "$helpmessage_write"
    elif [ $1 = "notexist" ]; then
        echo "$message_notexist"
        echo "$helpmessage_write"
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

#i2cgetででてくる0x○○（小文字）を●●：◯◯（アドレス：大文字）に整形する
ori_i2cget()
{
    local par=$1 #関数に入った引数を定義
    local option=$2
    local bef_result=$(i2cget -y $i2cline "$memory" 0x$par) #i2cgetの結果を変数として定義する
    local cut_result=${bef_result:2:2} #0xを取り除くため、2丁目から文字を出力
    local big_result=$(echo $cut_result | tr [a-f] [A-F]) #大文字に変換する

    case "$option" in
        "adplus") echo "$par:$big_result" #引数（アドレス）と整形したデータを：でつないで表示する。
        ;;
        *) echo "$big_result"
        ;;
    esac
}

##引数に入れたリストに、コンマを入れてcsv形式にする
#list_to_csv()
#{
#    local par=$*
#    local csv=$(echo $par|tr ' ' ',')
#    echo $csv
#}

##16個i2cgetの結果がたまったら1行分として吐き出し、表形式にする
#cell16_grid()
#{
#    local par=$1 #関数に入った引数を定義（16進数）
#    if [ "$par" = "remain" ]; then #ループを終えた後に残っていたものを吐き出す場合
#        list_to_csv ${cell16_list[*]}
#        unset cell16_list
#        return
#    elif ! [ -v cell16_list ]; then #cell16_listが存在しなかった場合（一番初め）
#        cell16_list=(00)
#    elif [ ${#cell16_list[*]} -eq 17 ]; then #cell16_listの長さが17個になった場合
#        list_to_csv ${cell16_list[*]} #リストをcsvに変えてecho
#        now_add_to10=$(change16to10 ${cell16_list[0]}) #今のリストの先頭を10進数にして変数に格納
#        next_add=$(change10to16 $((now_add_to10 + 16 ))) #16足して、16進数に戻す
#        cell16_list=($next_add) #cell16_listを更新し、先頭のアドレスを一つ先にする
#    fi
#    cell16_list+=($(ori_i2cget $par)) #リストの一番右にi2cgetの結果を追加する
#}

#【改善版】16個i2cgetの結果がたまったら1行分として吐き出し、表形式にする
cell16_grid_new()
{
    local par=$1 #関数に与えられた引数を定義（カウントアップ10進数）
    local ofs=$(($par % 16)) #リセット基準とのずれ
    local fin_add="$2" #関数に与えられた引数を定義（指定した最終アドレス）
    local now_add="$(change10to16 $par)" #16進数に変え、アドレスとして使える形にする
    if [ $ofs -eq 0 ]; then #16の倍数番目の場合、新しく先頭にアドレスを入れる
        cell16_list_new="$now_add"
    fi

        cell16_list_new="$cell16_list_new"",$(ori_i2cget $now_add)" #i2cgetの結果を横に並べる

    if [ $ofs -eq 15 ]; then #15番目が終わった場合吐き出す
        echo "$cell16_list_new"
    elif [ "$now_add" = "$fin_add" ]; then #最終アドレスに至った場合吐き出す
        echo "$cell16_list_new"
    else
        zzzzzzzz="zzzzzzzzzz" #なにもしない
    fi
}

#指定したアドレスに至るまで、すべてのデータを表示する
alladdress()
{
    fin_address="FF" #アドレス指定
    local cnt_address=0
    while [ $cnt_address -le $(change16to10 $fin_address) ] #指定したアドレスを10進数に変えて挿入
    do
        cell16_grid_new $cnt_address $fin_address #カウントアドレスと最終アドレスを渡す
        cnt_address=`expr $cnt_address + 1` #カウントアップ
    done
    echo "END"
}

#外部のcsvファイルを読み込んで、メモリに書き込む
csv_import()
{
    CSV_FILE=$1 #関数の引数として与えられたcsvファイルを取得
    last_char=$(tail -c 1 $CSV_FILE) #ファイルの末尾の一文字を取得
    if [ "$last_char" != "" ]; then #末尾が空白（改行）ではない場合
        echo "" >> $CSV_FILE #空白行を挿入
    fi

    #リダイレクトされたcsvファイルを1行ずつreadする
    while read LINE
    do
        echo "--------"
        csvlist=() #空のリストを用意
        adr=$(echo $LINE | cut -d "," -f 1) #コンマで区切って、先頭をアドレスとして取得
        adr10=$((16#$adr)) #アドレスを10進数に直す
        for i in {0..15}
        do
            csvlist[$i]=$(echo $LINE | cut -d "," -f $((i + 2))) #リストにcsvファイルの値を順番通り格納
            i2cset -y $i2cline "$memory" "0x$(printf "%X" $adr10)" "0x${csvlist[$i]}" #アドレスを16進数に直し、リストの値とともにi2csetへ挿入。
            adr10=$((adr10 + 1)) #アドレスをカウントアップ

        done
        echo "$adr:${csvlist[*]}" #書き込みが完了した列を表示
    done < $CSV_FILE #csvファイルをdo文へリダイレクト
}




#メインループver1（read機能だけ。引数はなしか、一つだけアドレスを指定する。）
main_readonly()
{
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

    ori_i2cget $par adplus
}

#メインループver2
main_writeonly()
{
    if [ $arg_amount -eq 0 ]; then #引数（指定ファイル）が無い場合
        error nonepar
        exit 5
    elif [ $arg_amount -gt 1 ]; then #引数が1より多い場合
        error argwrite
        exit 1
    elif ! [[ "$par" =~ $permit_csv ]]; then #拡張子がcsvではない場合
        error notcsv
        exit 6
    elif ! [ -e "$par" ]; then #指定ファイルが存在しない場合
        error notexist
        exit 7
    fi

    csv_import $par
}

#テスト用メインループ切替
Thistimeroop=2 #今回のバージョン指定

case $Thistimeroop in
    1) main_readonly
    ;;
    2) main_writeonly
    ;;
    *) zzzzzzzz="zzzzzzzzzzzzzz"
    ;;
esac 

