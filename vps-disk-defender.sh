#!/bin/bash

BLUE='\e[34m'
RED='\e[31m'

function echo_blue {
    echo -e "${BLUE}$1\e[0m"
}

function echo_red {
    echo -e "${RED}$1\e[0m"
}

clear

function select_language {
    echo -e "选择你的语言 | Select your language:\n"
    echo -e "1. 中文"
    echo -e "2. English\n"
    read -p "输入你的选择 | Enter your choice (1-2): " LANG_CHOICE
    echo
    case $LANG_CHOICE in
        1) LANG_CHOICE="CN";;
        2) LANG_CHOICE="EN";;
        *) echo_red "错误的选择 | Invalid choice\n"; exit 1;;
    esac
}

function banner {
    if [ $LANG_CHOICE == "CN" ]; then
        echo -e '#  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
        echo -e '#                 捍卫小鸡硬盘空间                 #'
        echo -e '#        人为预先占用空闲硬盘，避免商家超售        #'
        echo -e '#    https://github.com/i-abc/vps-disk-defender    #'
        echo -e '#  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
    else
        echo -e '#  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
        echo -e '#          Defending your VPS Disk Space           #'
        echo -e '#   Preoccupying disk space to avoid overselling   #'
        echo -e '#    https://github.com/i-abc/vps-disk-defender    #'
        echo -e '#  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
    fi
}

function check_user {
    if [ "$(id -u)" != "0" ]; then
        if [ $LANG_CHOICE == "CN" ]; then
            echo_red "\n此脚本必须由root管理员运行，本次任务已中断，请切换至root后重新执行此脚本\n"
        else
            echo_red "\nThis script must be run as root. Operation aborted, please switch to root and re-run this script\n"
        fi
        exit 1
    fi
}

function get_space {
    df -m | grep '/$' | awk '{print $4}'
}

function check_input {
    local SIZE=$1
    if ! [[ "$SIZE" =~ ^[0-9]+$ ]]; then
        if [ $LANG_CHOICE == "CN" ]; then
            echo_red "您输入的不是纯数字，本次任务已中断，请重新执行此脚本\n"
        else
            echo_red "Your input is not a number, the task has been aborted, please re-run this script\n"
        fi
        exit 1
    fi
}

function check_size {
    local SIZE=$1
    local AVAILABLE_SPACE=$2
    local MAX_SIZE=$((AVAILABLE_SPACE * 90 / 100))
    if [ $SIZE -gt $MAX_SIZE ]; then
        if [ $LANG_CHOICE == "CN" ]; then
            echo_red "您的输入数值过大，大于剩余硬盘空间的90%，为了防止爆盘，本次任务已中断，请重新执行此脚本\n"
        else
            echo_red "Your input value is too large, more than 90% of the remaining hard disk space, to prevent disk explosion, this task has been aborted, please re-run this script\n"
        fi
        exit 1
    fi
}

function run_dd {
    local SIZE=$1
    dd if=/dev/urandom of=/opt/dd count=$SIZE bs=1M status=progress
}

function main {
    select_language
    banner
    check_user
    local OLD_SPACE=$(get_space)
    if [ $LANG_CHOICE == "CN" ]; then
        echo -e "\n当前本机的剩余硬盘空间：${OLD_SPACE}M"
        echo -e "\n您想要预先占用多少MB的磁盘空间？"
        echo_blue "请输入一个纯数字，由于已经默认以MB为单位，您的输入不能再带单位"
    else
        echo -e "\nCurrent remaining hard disk space: ${OLD_SPACE}M"
        echo -e "\nHow much MB of disk space would you like to preoccupy?"
        echo_blue "Please enter a pure number, since the unit is already in MB, your input cannot have a unit"
    fi

    if [ $LANG_CHOICE == "CN" ]; then
        read -p "您的输入：" SIZE
	echo -e "\n任务进行中……"
    else
        read -p "Your input: " SIZE
	echo -e "\nTask is in progress……"
    fi
    check_input $SIZE
    check_size $SIZE $OLD_SPACE

    run_dd $SIZE
    local NEW_SPACE=$(get_space)

    if [ $LANG_CHOICE == "CN" ]; then
        echo -e "\n空闲磁盘预先占用成功"
        echo_blue "预先占用前，本机的剩余硬盘空间：${OLD_SPACE}MB"
        echo_blue "预先占用后，本机的剩余硬盘空间：${NEW_SPACE}MB"
        echo -e "\n以后若想释放预先占用的硬盘空间，请执行以下命令："
    else
        echo -e "\nPreoccupied disk space successfully"
        echo_blue "Before preoccupying, the remaining hard disk space of this machine: ${OLD_SPACE}MB"
        echo_blue "After preoccupying, the remaining hard disk space of this machine: ${NEW_SPACE}MB"
        echo -e "\nIf you want to release the preoccupied hard disk space in the future, please execute the following command:"
    fi
    echo_red "rm /opt/dd\n"
}

main

