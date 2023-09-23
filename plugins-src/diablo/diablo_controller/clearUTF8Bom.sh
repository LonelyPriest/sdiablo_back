#! /bin/bash
FILE=$1
sed -i $'1s/^\uFEFF//' $1
