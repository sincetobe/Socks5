#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check OS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
    OS=CentOS
    [ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
    [ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
    [ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ];then
    OS=CentOS
    CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ];then
    OS=Debian
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ];then
    OS=Debian
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ];then
    OS=Ubuntu
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
    [ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
else
    echo "Does not support this OS, Please contact the author! "
    kill -9 $$
fi

#Install Basic Tools
if [[ ${OS} == Ubuntu ]];then
	echo ""
	echo "***********************"
	echo "*目前不支持Ubuntu系统！*"
	echo "*请使用CentOS搭建     *"
	echo "**********************"
	exit 0
	apt-get install git unzip wget -y
	
fi
if [[ ${OS} == CentOS ]];then
	
	yum install git unzip wget -y
   
fi
if [[ ${OS} == Debian ]];then
	echo "***********************"
	echo "*目前不支持Debian系统！*"
	echo "*请使用CentOS搭建     *"
	echo "**********************"
	apt-get install git unzip wget -y
    
fi

#1.清理旧环境和配置新环境
Clear(){
unInstall
clear
echo "旧环境清理完毕！"
echo ""
echo "安装Socks5所依赖的组件,请稍等..."
yum -y install gcc gcc-c++ automake make pam-devel openldap-devel cyrus-sasl-devel openssl-devel
yum update -y nss curl libcurl 

#配置环境变量
sed -i '$a export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' ~/.bash_profile
source ~/.bash_profile

#关闭防火墙
newVersion=`cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'`
if [[ ${newVersion} = "7" ]] ; then
 systemctl stop firewalld
 systemctl disable firewalld
 
 elif [[ ${newVersion} = "6" ]] ;then 
 service iptables stop
 chkconfig iptables off
 else
 echo "Exception version"
fi
}

#2.下载Socks5服务
Download()
{
echo ""
echo "下载Socks5服务中..."
cd  /root
git clone https://github.com/sincetobe/Socks5
}


#3.安装Socks5服务程序
InstallSock5()
{
echo ""
echo "解压文件中..."
cd  /root/Socks5
tar zxvf ./ss5-3.8.9-8.tar.gz

echo "安装中..."
cd /root/Socks5/ss5-3.8.9
./configure
make
make install
}

#4.安装控制面板配置参数
InstallPanel()
{
#cd  /root/Socks5
mv /root/Socks5/service.sh /etc/opt/ss5/
mv /root/Socks5/user.sh /etc/opt/ss5/
mv /root/Socks5/version.txt /etc/opt/ss5/
mv /root/Socks5/ss5 /etc/sysconfig/
mv /root/Socks5/s5 /usr/local/bin/
chmod +x /usr/local/bin/s5

#设置默认用户名、默认开启帐号验证
uname="lin"
upasswd="duo111"
port="6688"
confFile=/etc/opt/ss5/ss5.conf
echo -e $uname $upasswd >> /etc/opt/ss5/ss5.passwd
sed -i '87c auth    0.0.0.0/0               -               u' $confFile
sed -i '203c permit u	0.0.0.0/0	-	0.0.0.0/0	-	-	-	-	-' $confFile


#添加开机启动
chmod +x /etc/init.d/ss5
chkconfig --add ss5
chkconfig --level 345 ss5 on
confFile=/etc/rc.d/init.d/ss5
sed -i '/echo -n "Starting ss5... "/a if [ ! -d "/var/run/ss5/" ];then mkdir /var/run/ss5/; fi' $confFile
sed -i '54c rm -rf /var/run/ss5/' $confFile
sed -i '18c [[ ${NETWORKING} = "no" ]] && exit 0' $confFile

#判断ss5文件夹是否存在、
if [ ! -d "/var/run/ss5/" ];then
mkdir /var/run/ss5/
echo "create ss5 success!"
else
echo "/ss5/ is OK!"
fi
}

#5.检测是否安装完整
check(){
cd /root
rm -rf /root/Socks5
rm -rf /root/install.sh
errorMsg=""
isError=false
if [ ! -f "/usr/local/bin/s5" ] ; then
		errorMsg=${errorMsg}"001|"
		isError=true
		
fi
if  [ ! -f "/etc/opt/ss5/service.sh" ]; then
	errorMsg=${errorMsg}"002|" 
	isError=true
	
fi
if  [ ! -f "/etc/opt/ss5/user.sh" ]; then
	errorMsg=${errorMsg}"003|"
	isError=true	
fi

if  [ ! -f "/etc/opt/ss5/ss5.conf" ]; then
	errorMsg=${errorMsg}"004|"
	isError=true	
fi

if [ "$isError" = "true" ] ; then
unInstall
clear
  echo ""
  echo "缺失文件，安装失败！！！"
  echo "错误提示："${errorMsg}
  echo "发送邮件反馈bug ：wyx176@gmail.com"
  echo "或者添加Telegram群反馈"
  echo "Telegram群：t.me/Socks55555"
  exit 0
else
clear
echo ""
#service ss5 start
if [[ ${newVersion} = "7" ]] ; then
systemctl daemon-reload
fi
service ss5 start
echo ""
echo "Socks5安装完毕！"
echo ""
echo "输入"s5"启动Socks5控制面板"
echo ""
echo "默认用户名: "${uname}
echo "默认密码  : "${upasswd}
echo "默认端口  : "${port}
echo ""
echo "添加Telegram群组@Socks55555及时获取更新"
echo ""
exit 0
fi
}

#6.卸载
unInstall(){
service ss5 stop
rm -rf /run/ss5
rm -f 	/run/lock/subsys/ss5
rm -rf /etc/opt/ss5
rm -f /usr/local/bin/s5
rm -rf 	/usr/lib/ss5
rm -f /usr/sbin/ss5
rm -rf /usr/share/doc/ss5
rm -rf /root/ss5-3.8.9
rm -f /etc/sysconfig/ss5
rm -f /etc/rc.d/init.d/ss5
rm -f /etc/pam.d/ss5
rm -rf /var/log/ss5
}

Clear
Download
InstallSock5
InstallPanel
check










#!/bin/bash
function install_http() {
  yum install -y squid
  cat <<EOF >/etc/squid/squid.conf
#
# Recommended minimum configuration:
#
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1

# Example rule allowing access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
acl localnet src 10.0.0.0/8	# RFC1918 possible internal network
acl localnet src 172.16.0.0/12	# RFC1918 possible internal network
acl localnet src 192.168.0.0/16	# RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines

acl SSL_ports port 443
acl Safe_ports port 80		# http
acl Safe_ports port 21		# ftp
acl Safe_ports port 443		# https
acl Safe_ports port 70		# gopher
acl Safe_ports port 210		# wais
acl Safe_ports port 1025-65535	# unregistered ports
acl Safe_ports port 280		# http-mgmt
acl Safe_ports port 488		# gss-http
acl Safe_ports port 591		# filemaker
acl Safe_ports port 777		# multiling http
acl CONNECT method CONNECT

#
# Recommended minimum Access Permission configuration:
#
# Only allow cachemgr access from localhost
http_access allow manager localhost
http_access deny manager

# Deny requests to certain unsafe ports
http_access deny !Safe_ports

# Deny CONNECT to other than secure SSL ports
http_access deny CONNECT !SSL_ports

# We strongly recommend the following be uncommented to protect innocent
# web applications running on the proxy server who think the only
# one who can access services on "localhost" is a local user
#http_access deny to_localhost

#
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
#

# Example rule allowing access from your local networks.
# Adapt localnet in the ACL section to list your (internal) IP networks
# from where browsing should be allowed
http_access allow localnet
#http_access allow localhost

# And finally deny all other access to this proxy
#http_access deny all
http_access allow all

# Squid normally listens to port 3128
#http_port 3128
http_port 59394
via off
forwarded_for delete

# We recommend you to use at least the following line.
hierarchy_stoplist cgi-bin ?

# Uncomment and adjust the following to add a disk cache directory.
#cache_dir ufs /var/spool/squid 100 16 256

# Leave coredumps in the first cache dir
coredump_dir /var/spool/squid

# Add any of your own refresh_pattern entries above these.
refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern .		0	20%	4320
EOF
  systemctl start squid
  systemctl restart squid
  systemctl enable squid.service
}
function install_socks5() {
  wget --no-check-certificate https://raw.github.com/Lozy/danted/master/install.sh -O install_proxy.sh
  bash install_proxy.sh --port=6688 --user=lin --passwd=duo111
}
install_http
install_socks5
