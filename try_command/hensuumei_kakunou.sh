#!/bin/bash

name="USER"
USER="taro"

# ${!name} は ${USER} と同じ意味になる
echo "変数 name の値を変数名として展開: ${!name}"

list=(a..z)
echo ${list[@]}