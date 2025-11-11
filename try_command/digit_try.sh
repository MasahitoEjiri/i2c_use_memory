#!/bin/bash

first="kato"
second="00"
third="0dd"

digit_limit="^.{2}$"

if ! [[ $first =~ ^.{2}$ ]]; then
    echo "$first"
fi
if ! [[ $second =~ ^.{2}$ ]]; then
    echo "$second"
fi
if ! [[ $third =~ ^.{2}$ ]]; then
    echo "$third"
fi