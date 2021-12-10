#!/bin/bash

# bash <(curl -Lso- https://raw.githubusercontent.com/LIULIWANJIA/XrayR-SSP/main/install.sh)

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
    exit 2
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
    else
        apt install wget curl unzip tar cron socat -y
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/XrayR.service ]]; then
        return 2
    fi
    temp=$(systemctl status XrayR | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

install_acme() {
    curl https://get.acme.sh | sh
}

install_XrayR() {
    echo "请设定对接地址"
    echo ""
    read -p "请输入对接地址:" apihost
    [ -z "${apihost}" ]
    echo "---------------------------"
    echo "您设定的对接地址为 ${apihost}"
    echo "---------------------------"
    echo ""
    echo "请先设定对接Key"
    echo ""
    read -p "请输入对接Key:" apikey
    [ -z "${apikey}" ]
    echo "---------------------------"
    echo "您设定的对接Key为 ${apikey}"
    echo "---------------------------"
    echo ""
    echo "请设定节点ID"
    echo ""
    read -p "请输入节点ID:" nodeid
    [ -z "${nodeid}" ]
    echo "---------------------------"
    echo "您设定的节点序号为 ${nodeid}"
    echo "---------------------------"
    echo ""
    install_base
    install_acme
    
    if [[ -e /usr/local/XrayR/ ]]; then
        rm /usr/local/XrayR/ -rf
    fi

    mkdir /usr/local/XrayR/ -p
	cd /usr/local/XrayR/

    if  [ $# == 0 ] ;then
        #last_version=$(curl -Ls "https://api.github.com/repos/XrayR-project/XrayR/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        #if [[ ! -n "$last_version" ]]; then
        #    echo -e "${red}检测 XrayR 版本失败，可能是超出 Github API 限制，请稍后再试，或手动指定 XrayR 版本安装${plain}"
        #    exit 1
        #fi
        #echo -e "检测到 XrayR 最新版本：${last_version}，开始安装"
        #wget -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux-64.zip https://github.com/XrayR-project/XrayR/releases/download/${last_version}/XrayR-linux-64.zip
        #github源下载
        wget -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux.zip https://github.com/LIULIWANJIA/XrayR-SSP/raw/main/XrayR-linux-64.zip
        
        #wget -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux.zip https://github.com/LIULIWANJIA/XrayR-SSP/raw/main/XrayR-linux-arm64-v8a.zip.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 XrayR 失败，请确保你的服务器能够下载 Github 的文件${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/XrayR-project/XrayR/releases/download/${last_version}/XrayR-linux-64.zip"
        echo -e "开始安装 XrayR v$1"
        wget -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux-64.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 XrayR v$1 失败，请确保此版本存在${plain}"
            exit 1
        fi
    fi

    unzip XrayR-linux.zip
    rm XrayR-linux.zip -f
    chmod +x XrayR
    mkdir /etc/XrayR/ -p
    rm /etc/systemd/system/XrayR.service -f
    
    file="https://raw.githubusercontent.com/LIULIWANJIA/XrayR-SSP/main/XrayR.service"
    wget -N --no-check-certificate -O /etc/systemd/system/XrayR.service ${file}
    systemctl daemon-reload
    systemctl stop XrayR
    systemctl enable XrayR
    echo -e "${green}XrayR ${last_version}${plain} 安装完成，已设置开机自启"
    cp geoip.dat /etc/XrayR/
    cp geosite.dat /etc/XrayR/ 

    if [[ ! -f /etc/XrayR/config.yml ]]; then
        cp config.yml /etc/XrayR/
        echo -e ""
        echo -e "全新安装中"
    else
        systemctl start XrayR
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}XrayR 重启成功${plain}"
        else
            echo -e "${red}XrayR 可能启动失败，请稍后使用 XrayR log 查看日志信息，若无法启动，则可能更改了配置格式，请前往 wiki 查看：https://github.com/XrayR-project/XrayR/wiki${plain}"
        fi
    fi

    if [[ ! -f /etc/XrayR/dns.json ]]; then
        cp dns.json /etc/XrayR/
    fi
    
    curl -o /usr/bin/XrayR -Ls https://raw.githubusercontent.com/LIULIWANJIA/XrayR-SSP/main/XrayR.sh
    chmod +x /usr/bin/XrayR

    # Writing json
    echo "正在尝试写入配置文件..."
    wget https://raw.githubusercontent.com/LIULIWANJIA/XrayR-SSP/main/config.yml -O /etc/XrayR/config.yml    
    sed -i "s/ApiHost:.*/ApiHost: '${apihost}'/g" /etc/XrayR/config.yml
    sed -i "s/ApiKey:.*/ApiKey: '${apikey}'/g" /etc/XrayR/config.yml
    sed -i "s/NodeID:.*/NodeID: ${nodeid}/g" /etc/XrayR/config.yml
    echo ""
    echo "写入完成，正在尝试重启XrayR服务..."
    echo
    XrayR restart
    echo "正在关闭防火墙！"
    echo
    systemctl disable firewalld
    systemctl stop firewalld
    echo "XrayR服务已经完成安装并启用！"
    echo
    echo -e ""
}

update_XrayR(){
    echo "请设定对接地址"
    echo ""
    read -p "请输入对接地址:" apihost
    [ -z "${apihost}" ]
    echo "---------------------------"
    echo "您设定的对接地址为 ${apihost}"
    echo "---------------------------"
    echo ""
    echo "请先设定对接Key"
    echo ""
    read -p "请输入对接Key:" apikey
    [ -z "${apikey}" ]
    echo "---------------------------"
    echo "您设定的对接Key为 ${apikey}"
    echo "---------------------------"
    echo ""
    echo "请设定节点ID"
    echo ""
    read -p "请输入节点ID:" nodeid
    [ -z "${nodeid}" ]
    echo "---------------------------"
    echo "您设定的节点序号为 ${nodeid}"
    echo "---------------------------"
    echo ""
    
    sed -i "s/ApiHost:.*/ApiHost: '${apihost}'/g" /etc/XrayR/config.yml
    sed -i "s/ApiKey:.*/ApiKey: '${apikey}'/g" /etc/XrayR/config.yml
    sed -i "s/NodeID:.*/NodeID: ${nodeid}/g" /etc/XrayR/config.yml
    echo ""
    echo "写入完成，正在尝试重启XrayR服务..."
    echo ""
    XrayR restart
    echo ""
    echo "XrayR服务已经完成配置更新并启用！"
    echo
    echo -e ""
}
set_speed(){
    echo "设定限速值(Mbps)"
    echo ""
    read -p "请输入限速值:" speed
    [ -z "${speed}" ]
    echo "---------------------------"
    echo "您设定的节点限速为 ${speed} Mbps"
    echo "---------------------------"
    echo ""
    
    sed -i "s/SpeedLimit:.*/SpeedLimit: ${speed}/g" /etc/XrayR/config.yml
    echo ""
    echo "写入完成，正在尝试重启XrayR服务..."
    echo ""
    XrayR restart
    echo ""
    echo "XrayR服务已经完成限速更新并启用！"
    echo
    echo -e ""
}

echo -e "${green}开始安装${plain}"
clear
while true
do
echo  " "
echo  " "
echo  "XrayR 一键对接脚本 v1.0"
echo  " "
echo  " "
echo  "————————————————————————"

echo -e "${green}1${plain} 安装对接"
echo -e "${green}2${plain} 查看状态"
echo -e "${green}3${plain} 卸载程序"
echo  " "
echo  "————————————————————————"
echo  " "
echo -e "${green}4${plain} 更新配置"
echo -e "${green}5${plain} 配置限速"
echo  " "
echo  "————————————————————————"
echo  " "
echo -e "${green}6${plain} 日志"
echo  " "
echo  "————————————————————————"
echo  " "
read -e -p " 请输入数字 [0-4]:" num
case "$num" in
	1)
	install_XrayR
	break
	;;
	2)
	XrayR status
	break
	;;
	3)
	XrayR uninstall
	break
	;;
	4)
	update_XrayR
	break
	;;
	5)
	set_speed
	break
	;;
	6)
	XrayR log
	break
	;;
	*)
	echo "请输入正确数字"
	;;
esac
done
