#!/bin/bash
cell16_list=(00 ijga 05 gadga gasfga jjwaa gafgfs gfaga)
echo $cell16_list
echo ${cell16_list[*]}

par=$(echo $cell16_list)
par1=($(echo ${cell16_list[*]}))
par2=($(echo ${cell16_list[@]}))
echo $par
echo $par1
echo $par2

list_to_csv()
{
    local par=$*
    echo $par
    csv=$(echo $par|tr ' ' ',')
    echo $csv
}

list_to_csv ${cell16_list[*]}
echo ${#cell16_list[@]}
echo ${#cell16_list[*]}
echo 0$((cell16_list[2] + 1))
echo $((cell16_list[2]))
next_add=0$((cell16_list[2] + 1))
echo $next_add
unset cell16_list
echo ${cell16_list[*]}
if [ -v cell16_list ]; then
    echo "hallo"
else
    echo "w"
fi
