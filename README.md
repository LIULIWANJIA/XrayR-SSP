# XrayR-SSP一键对接脚本


bash <(curl -Lso- https://raw.githubusercontent.com/LIULIWANJIA/XrayR-SSP/main/install.sh)

如无curl
可指令安装
yum -y install curl
或者
apt-get -y install curl



无脑操作，适用于SSpanel
其他面板对接请在对接完成后，手动修改 /etc/XrayR/config.yml里的面板类型
再执行XrayR restart
