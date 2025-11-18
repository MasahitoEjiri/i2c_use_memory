#!/bin/bash

script_tytle=$0 #スクリプト名
par=$1 #引数
arg_amount=$# #引数の個数
digit_limit="^.{2}$" #桁数
permit_usechar="^[a-fA-F0-9]*$" #16進数範囲内の文字
permit_sizechar="^[A-F0-9]*$" #小文字を除く
permit_csv="[cC][sS][vV]$" #csvファイル指定(.も判定したいけど保留)
i2cline=0
memory="0x50"


arg_error()
{
    echo "There are two or more arguments."
}

read_error_par()
{
    local message_usechar="This character cannot be used in hexadecimal."
    local message_digit="The number of digits is too few or too many."
    local message_sizechar="Small charecters cannot be used. "
    local helpmessage="---------------------------------
    $script_tytle [par]
        par : 00 ～ FF
---------------------------------"

    if [ $1 = "digit" ]; then #関数の引数がdigitの場合
        echo "$message_digit"
    elif [ $1 = "usechar" ]; then #関数の引数がusecharの場合
        echo "$message_usechar"
    elif [ $1 = "sizechar" ]; then #関数の引数がsizecharの場合
        echo "$message_sizechar"
    fi

    echo "$helpmessage"
    
}

write_error_par()
{
    local message_nonepar="Please enter the filename."
    local message_notcsv="Only CSV files can be used."
    local message_notexist="The file was not found."
    local helpmessage="---------------------------------
    $script_tytle [file.csv]
---------------------------------"

    if [ $1 = "nonepar" ]; then #関数の引数がnoneparの場合
        echo "$message_nonepar"
    elif [ $1 = "notcsv" ]; then #関数の引数がnotcsvの場合
        echo "$message_notcsv"
    elif [ $1 = "notexist" ]; then #関数の引数がnotexistの場合
        echo "$message_notexist"
    fi

    echo "$helpmessage"
}

#i2cgetででてくる0x○○（小文字）を●●：◯◯（アドレス：大文字）に整形する
read_oneadr()
{
    local par=$1 #関数に入った引数を定義
    local option=$2 #関数に入った引数を定義
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


#16個i2cgetの結果がたまったら、1行分として表形式で吐き出す
read_lineadr()
{
    local par=$1 #関数に与えられた引数を定義（カウントアップ10進数）
    local ofs=$(($par % 16)) #リセット基準とのずれ
    local fin_add="$2" #関数に与えられた引数を定義（指定した最終アドレス）
    local now_add="$(printf "%X"  $par)" #16進数に変え、アドレスとして使える形にする
    if [ $ofs -eq 0 ]; then #16の倍数番目の場合、新しく先頭にアドレスを入れる
        cell16_list="$now_add"
    fi

        cell16_list="$cell16_list"",$(read_oneadr $now_add)" #i2cgetの結果を横に並べる

    if [ $ofs -eq 15 ]; then #15番目が終わった場合吐き出す
        echo "$cell16_list"
    elif [ "$now_add" = "$fin_add" ]; then #最終アドレスに至った場合吐き出す
        echo "$cell16_list"
    else
        zzzzzzzz="zzzzzzzzzz" #なにもしない
    fi
}

#指定したアドレスに至るまで、すべてのデータを表形式で表示する
read_alladr()
{
    fin_address="FF" #アドレス指定
    local cnt_address=0
    while [ $cnt_address -le $((16#$fin_address)) ] #指定したアドレスを10進数に変えて挿入
    do
        read_lineadr $cnt_address $fin_address #カウントアドレスと最終アドレスを渡す
        cnt_address=`expr $cnt_address + 1` #カウントアップ
    done
    echo "END"
}

#外部のcsvファイルを読み込んで、メモリに書き込む
write_fromcsv()
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
    if [ $arg_amount -eq 0 ]; then #引数が無い場合
        read_alladr
        exit
    elif [ $arg_amount -gt 1 ]; then #引数が1より多い場合
        arg_error
        exit 1
    elif ! [[ "$par" =~ $digit_limit ]]; then #引数の桁が2桁でない場合
        read_error_par digit
        exit 2
    elif ! [[ "$par" =~ $permit_usechar ]]; then #引数が16進数で使えない文字だった場合
        read_error_par usechar
        exit 3
    elif ! [[ "$par" =~ $permit_sizechar ]]; then #引数のアルファベットが大文字ではない場合
        read_error_par sizechar
        exit 4
    else
        zzzzzzzz="zzzzzzzzzzzzzzz"
    fi

    read_oneadr $par adplus
}

#メインループver2
main_writeonly()
{
    if [ $arg_amount -gt 1 ]; then #引数が1より多い場合
        arg_error
        exit 5
    elif [ $arg_amount -eq 0 ]; then #引数（指定ファイル）が無い場合
        write_error_par nonepar
        exit 6
    elif ! [[ "$par" =~ $permit_csv ]]; then #拡張子がcsvではない場合
        write_error_par notcsv
        exit 7
    elif ! [ -e "$par" ]; then #指定ファイルが存在しない場合
        write_error_par notexist
        exit 8
    else
        zzzzzzzz="zzzzzzzzzzzzzzz"
    fi

    write_fromcsv $par
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

