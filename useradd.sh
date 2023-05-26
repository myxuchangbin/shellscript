#!/bin/bash

name="$1"

if [ -z $1 ]; then
	echo "用户名不能为空，请输入用户名然后重试······"
	exit 1
fi

if [[ $EUID -ne 0 ]]; then
	echo "Error:请使用ROOT用户登录并进行创建用户." 1>&2
	exit 1
fi

# 配置公钥文件
set_keys(){
	mkdir -p --mode=700 /home/$name/.ssh
	wget -O /home/$name/id_rsa_1024.pub https://github.com/myxuchangbin/shellscript/raw/master/id_rsa_1024.pub
	cat /home/$name/id_rsa_1024.pub >> /home/$name/.ssh/authorized_keys
	rm -f /home/$name/id_rsa_1024.pub
	chmod 600 /home/$name/.ssh/authorized_keys
	chown -R "$name"."$name" /home/$name/.ssh
}

# 配置sudo
set_sudo(){
	cat /etc/sudoers | grep $name
	if [ $? -ne 0 ]; then
		sed -i "/root.*ALL=(ALL).*ALL/a$name    ALL=(ALL)    NOPASSWD:ALL" /etc/sudoers
		# echo "$name    ALL=(ALL)    NOPASSWD:ALL" >> /etc/sudoers
	fi
}

egrep "^$name" /etc/passwd >& /dev/null
if [ $? -eq 0 ]; then
	echo -e "用户：$name 已经存在！是否直接添加公钥文件？(y/n)"
	read -p "(默认为：n):" answer
	if [ -z $answer ]; then
        answer="n"
    fi
	if [ "$answer" = "y" ]; then
		set_keys
		set_sudo
	else	
		exit 0
	fi
else
	useradd -m $name
	set_keys
	set_sudo
fi