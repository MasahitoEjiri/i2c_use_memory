#!/bin/bash
#for i in $(seq -w 0 99)
#do
#    rm test-${i}.txt
#    echo test-${i}.txt
#done

#実行結果
#test-1.txt
#test-2.txt
#test-3.txt
#.
#.
#.
#test-100.txt


#read出力先のファイル名
file_name="data_output"
ext=".csv"

for i in $(seq -w 0 99)
do
    if [ -e "$file_name${i}$ext" ]; then
        rm $file_name${i}$ext
        echo "$file_name${i}$ext"
    fi
done
