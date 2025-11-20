#!/bin/bash

script_tytle=$0 #スクリプト名
par=$1 #引数
par2=$2 #引数
arg_amount=$# #引数の個数

#メモリの位置情報
i2cline=0
memory="0x50"

#read出力先のファイル名
file_name="data_output"
ext=".csv"



#help--------------------------------------------------------------------------------------------
#ヘルプ番号割り当て
normal_help=1
read_help=2
write_help=3
file_help=4

#ヘルプメッセージ内容
helpmessage="---------------------------------------------------
$script_tytle [mode] [par]
        mode: -r (You can read the data in memory.)
            par: 00 ～ FF
                 none(alladdress)
        mode: -w (You can import CSV files.)
            par: XXXXX.csv
---------------------------------------------------"
read_helpmessage="------------------------------------------
    $script_tytle -r [par]
        par: 00 ～ FF
             none(alladdress)
------------------------------------------"
write_helpmessage="-------------------------------------
    $script_tytle -w [par]
        par: yourfile.csv
-------------------------------------"
file_helpmessage="-------------------------------------
    ${file_name}XX${ext}
        XX: 00 (min) → 99(max)
-------------------------------------"


#第1引数として受け取ったヘルプ番号とヘルプメッセージを対応させて表示する。
help_message()
{
    case $1 in
    $normal_help) echo "$helpmessage"
    ;;
    $read_help) echo "$read_helpmessage"
    ;;
    $write_help) echo "$write_helpmessage"
    ;;
    $file_help) echo "$file_helpmessage"
    ;;
    esac
}


#error--------------------------------------------------------------------------------------------
#エラー番号の割り当て
arg_none=1
arg_over=2
mode_wrong=10
read_digit=20
read_usechar=21
read_charsize=22
write_nonepar=31
write_notcsv=32
write_notexist=33

#エラーメッセージ内容
arg_none_mes="Please enter some parameters."
arg_over_mes="There are three or more arguments."
mode_wrong_mes="That mode does not exist."
read_digit_mes="The number of digits is too few or too many."
read_usechar_mes="This character cannot be used in hexadecimal."
read_charsize_mes="Small charecters cannot be used. "
write_nonepar_mes="Please enter the filename."
write_notcsv_mes="Only CSV files can be used."
write_notexist_mes="The file was not found."

#第1引数として受け取ったエラー番号とメッセージを対応させて表示し、第2引数として受け取ったヘルプ番号をhelp関数に渡して終了
error_par()
{
    case $1 in

    $arg_none) echo "$arg_none_mes"
    ;;
    $arg_over) echo "$arg_over_mes"
    ;;
    $mode_wrong) echo "$mode_wrong_mes"
    ;;
    $read_digit) echo "$read_digit_mes"
    ;;
    $read_usechar) echo "$read_usechar_mes"
    ;;
    $read_charsize) echo "$read_charsize_mes"
    ;;
    $write_nonepar) echo "$write_nonepar_mes"
    ;;
    $write_notcsv) echo "$write_notcsv_mes"
    ;;
    $write_notexist) echo "$write_notexist_mes"
    ;;
    esac

    help_message $2
    exit 1
}

read_muchfile=50

read_muchfile_mes="Please remove ${file_name}XX${ext}."

error_file()
{
    case $1 in
    
    $read_muchfile) echo "$read_muchfile_mes"
    ;;
    esac

    help_message $2
    exit 2
}


#read_function--------------------------------------------------------------------------------------------
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


#追番を若い順から空いているもの見つけ、ファイルを出力する。
read_make_outputcsv()
{
    for i in $(seq -w 0 99) #0埋め2桁の範囲を指定
    do
        if ! [ -e "$file_name${i}$ext" ]; then #若い順から追番がすでにあるか判定し、なければその番号でファイル名作成
            echo "$file_name${i}$ext"
            return
        fi
    done
}



#指定したアドレスに至るまで、すべてのデータを表形式で表示する
fin_address="FF" #アドレス指定
READ_RESULT=$(read_make_outputcsv)
read_alladr()
{
    local cnt_address=0
    echo "Wait a minute..."
    while [ $cnt_address -le $((16#$fin_address)) ] #指定したアドレスを10進数に変えて挿入
    do

        local ofs=$(($cnt_address % 16)) #リセット基準とのずれ
        local now_add="$(printf '%04X'  $cnt_address)" #4桁0埋めの16進数に変え、アドレスとして使える形にする
        if [ $ofs -eq 0 ]; then #16の倍数番目の場合、新しく先頭にアドレスを入れる
            lineadr_data="$now_add"
        fi

            lineadr_data="$lineadr_data"",$(read_oneadr $now_add)" #read_oneadrの結果を横に並べる

        if [ $ofs -eq 15 ]; then #15番目が終わった場合吐き出す
            echo "$lineadr_data" >> $READ_RESULT
        elif [ "$now_add" = "$fin_address" ]; then #最終アドレスに至った場合吐き出す
            echo "$lineadr_data" >> $READ_RESULT
        else
            zzzzzzzz="zzzzzzzzzz" #なにもしない
        fi

        cnt_address=`expr $cnt_address + 1` #カウントアップ
    done
    echo "filename: $READ_RESULT"
    cat $READ_RESULT
    echo "END"
}


#write_function--------------------------------------------------------------------------------------------
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
        line_csv="" #line_csvに残っている前行の結果を消す。
        adr=$(echo $LINE | cut -d "," -f 1) #コンマで区切って、先頭をアドレスとして取得
        adr10=$((16#$adr)) #アドレスを10進数に直す
        for i in {0..15}
        do
            one_csv=$(echo $LINE | cut -d "," -f $((i + 2))) #ループで回ってきた順番の値を取得
            i2cset -y $i2cline "$memory" "0x$(printf "%X" $adr10)" "0x$one_csv" #アドレスを16進数に直し、順番の値とともにi2csetへ挿入。
            line_csv="$line_csv"",$one_csv" #セットが完了した値からコンマ区切りの行文字列に格納
            adr10=$((adr10 + 1)) #アドレスをカウントアップ

        done
        echo "$(printf "%04X" 0x$adr)$line_csv" #アドレスを0埋めして4桁にし、書き込みが完了した列を表示
    done < $CSV_FILE #csvファイルをdo文へリダイレクト
}


#par_insert--------------------------------------------------------------------------------------------
#規定外のパラメータをはじくための正規表現格納
digit_limit="^.{2}$" #桁数
permit_usechar="^[a-fA-F0-9]*$" #16進数範囲内の文字
permit_sizechar="^[A-F0-9]*$" #小文字を除く
permit_csv="[cC][sS][vV]$" #csvファイル指定(.も判定したいけど保留)

#readモードにおいて、ユーザーが入力したパラメータをスクリプトに読み込ませる
read_insert_par()
{
    local par_adr=$1

    if ! [ -n "$par_adr" ]; then #引数が0文字の場合
        if ! [ -n "$READ_RESULT" ]; then #出力先ファイルが99までいっぱいで作成されなかった場合
            error_file $read_muchfile $file_help
        else
            read_alladr
            exit
        fi
    elif ! [[ "$par_adr" =~ $digit_limit ]]; then #引数の桁が2桁でない場合
        error_par $read_digit $read_help
    elif ! [[ "$par_adr" =~ $permit_usechar ]]; then #引数が16進数で使えない文字だった場合
        error_par $read_usechar $read_help
    elif ! [[ "$par_adr" =~ $permit_sizechar ]]; then #引数のアルファベットが大文字ではない場合
        error_par $read_charsize $read_help
    else
        zzzzzzzz="zzzzzzzzzzzzzzz" #なにもしない
    fi

    read_oneadr $par_adr adplus
}

#writeモードにおいて、ユーザーが入力したパラメータをスクリプトに読み込ませる
write_insert_par()
{
    local par_file=$1

    if ! [ -n "$par_file" ]; then #引数が0文字の場合
        error_par $write_nonepar $write_help
    elif ! [[ "$par_file" =~ $permit_csv ]]; then #拡張子がcsvではない場合
        error_par $write_notcsv $write_help
    elif ! [ -e "$par_file" ]; then #指定ファイルが存在しない場合
        error_par $write_notexist $write_help
    else
        zzzzzzzz="zzzzzzzzzzzzzzz" #なにもしない
    fi

    write_fromcsv $par_file

}


#mainroop--------------------------------------------------------------------------------------------
#メインループ。引数の個数エラーをはじいた後、モードを切り替える。
if [ $arg_amount -eq 0 ]; then #引数が無い場合
    error_par $arg_none $normal_help
elif [ $arg_amount -gt 2 ]; then #引数が2よりも多い場合
    error_par $arg_over $normal_help
fi

case "$par" in
"-r") read_insert_par $par2
;;
"-w") write_insert_par $par2
;;
"-h") help_message $normal_help
;;
*) error_par $mode_wrong $normal_help
;;
esac