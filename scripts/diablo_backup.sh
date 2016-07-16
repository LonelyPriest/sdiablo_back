#! /bin/bash

export PATH=/mnt/home2/bxhui/otp_bin_R16B03-1/bin:${PATH}

cd ~/diablo_controller/knife

scripts/knife_backup.sh diablo bxh bxhui

cd ~
