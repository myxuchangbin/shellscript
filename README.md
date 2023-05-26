# 个人使用和随手写的一些脚本，仅供参考和学习！

## switchkernel.sh

- 脚本说明: CentOS一键更换内核脚本，CentOS6 内核更换为： 2.6.32-642.el6.x86_64，CentOS7 内核更换为： 3.10.0-229.1.2.el7.x86_64
- 系统支持: CentOS6/7
- 内核说明: 匹配锐速的最新相应内核版本

### 使用方法：
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/myxuchangbin/shellscript/master/switchkernel.sh && chmod +x bbr.sh && bash switchkernel.sh
```
## mysqld-listen.sh

- 脚本说明: 监控mysql进程，当mysql死掉自动启动之
- 系统支持: Linux

### 使用方法：
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/myxuchangbin/shellscript/master/mysqld-listen.sh && chmod +x mysqld-listen.sh
crontab -e
*/5 * * * *    mysqld-listen.sh    #每隔5分钟，执行一次mysqld-listen.sh脚本。
```

## gost.sh

- 脚本说明: gost工具安装

### 使用方法：
``` bash
wget -N --no-check-certificate https://github.com/myxuchangbin/shellscript/raw/master/gost/gost.sh && bash gost.sh
```
国内加速：
``` bash
wget -N --no-check-certificate https://raw.fastgit.org/myxuchangbin/shellscript/raw/master/gost/gost.sh && bash gost.sh cn
```

## changeip.sh

- 脚本说明: 当gost中存在ddns地址时使用，可搭配crontab自动更新配置文件中的ip

## useradd.sh

- 脚本说明: linux系统添加非root用户

## time.sh

- 脚本说明: shell脚本显示执行总时间模板

## startsys.sh

- 脚本说明: 系统开箱优化
- 系统支持: Centos7/8 Debian Ubuntu

### 使用方法：
``` bash
bash <(curl -s https://raw.githubusercontent.com/myxuchangbin/shellscript/master/startsys.sh)
```
国内加速：
``` bash
bash <(curl -s https://raw.fastgit.org/myxuchangbin/shellscript/master/startsys.sh) cn
```

## 解锁Netflix

### 条件：
- 可看Netflix的VPS
- [sniproxy](https://github.com/dlundquist/sniproxy)
- [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html)
- 【可选】iptables/firewalld 用来限制ip访问

### 使用方法：
1. 根据官方文档安装好sniproxy，配置文件请参考`netfilx-proxy/sniproxy.conf`
2. 安装dnsmasq，配置文件请参考`netfilx-proxy/dnsmasq.conf`
3. 一般为了防止代理被滥用可使用防火墙来允许指定ip访问
   * firewalld
   ``` bash
   firewall-cmd --permanent --remove-service=http
   firewall-cmd --permanent --remove-service=https
   firewall-cmd --permanent --remove-service=dns
   firewall-cmd --permanent --remove-port=80/tcp
   firewall-cmd --permanent --remove-port=443/tcp
   firewall-cmd --permanent --remove-port=53/tcp
   firewall-cmd --permanent --remove-port=53/udp
   firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.1.66" port protocol="tcp" port="80" accept"
   firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.1.66" port protocol="tcp" port="443" accept"
   firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.1.66" port protocol="tcp" port="53" accept"
   firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.1.66" port protocol="udp" port="53" accept"
   firewall-cmd --reload
   ```
   **删除规则把`--add-rich-rule`改成`--remove-rich-rule`即可**
   * iptables
   ``` bash
   iptables -I INPUT -p tcp --dport 80 -j DROP
   iptables -I INPUT -p tcp --dport 443 -j DROP
   iptables -I INPUT -p tcp --dport 53 -j DROP
   iptables -I INPUT -p udp --dport 53 -j DROP
   iptables -I INPUT -s 10.10.10.20 -p tcp --dport 80 -j ACCEPT
   iptables -I INPUT -s 10.10.10.20 -p tcp --dport 443 -j ACCEPT
   iptables -I INPUT -s 10.10.10.20 -p tcp --dport 53 -j ACCEPT
   iptables -I INPUT -s 10.10.10.20 -p udp --dport 53 -j ACCEPT
   service iptables save
   service iptables restart
   ```
   **删除规则先执行`iptables -L INPUT -line-numbers`以序号形式列出，然后执行`iptables -D INPUT 1`删除指定序号规则**
4. 将本地电脑或中转VPS的DNS地址修改为VPS的IP，搞定。如果不好使，记得只保留一个DNS地址试试！
---
***持续更新中...***
