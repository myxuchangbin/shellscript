#!/usr/bin/env bash
###
 # @Description: 适用于 CentOS / Debian / Ubuntu 的系统初始化优化脚本
 # @From: https://github.com/myxuchangbin/shellscript 
 # @Warning: 脚本仅供内部测试，请谨慎用于生产环境
###

# 颜色定义
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
yellowflash='\033[0;33;5m'
blackflash='\033[0;47;30;5m'
plain='\033[0m'

# 图标定义
INFO="ℹ"
OK="✓"
WARN="⚠"
ERROR="✗"
ARROW="➜"

# 打印带颜色的消息
msg_info() {
    echo -e "${yellow}${ARROW} $1${plain}"
}

msg_ok() {
    echo -e "${green}${OK} $1${plain}"
}

msg_warn() {
    echo -e "${yellow}${WARN} $1${plain}"
}

msg_error() {
    echo -e "${red}${ERROR} $1${plain}"
}

# 检查 root 权限
[[ $EUID -ne 0 ]] && msg_error "需要 root 权限运行此脚本！" && exit 1

# 检测操作系统
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
    msg_error "无法识别系统版本，脚本中止" && exit 1
fi

os_version=""

# 获取系统版本
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

# 版本检查
if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        msg_error "不支持 CentOS ${os_version}，需要 CentOS 7+" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        msg_error "不支持 Ubuntu ${os_version}，需要 Ubuntu 16+" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 9 ]]; then
        msg_error "不支持 Debian ${os_version}，需要 Debian 9+" && exit 1
    fi
fi

# 配置镜像源
GITHUB_URL="github.com"
GITHUB_RAW_URL="raw.githubusercontent.com"
GITHUB_DOWNLOAD_URL="github.com"
NTPSERVER="time.cloudflare.com"
TIMEZONE="Asia/Hong_Kong"
import_key=0

if [ -n "$*" ]; then
    if echo "$*" | grep -qwi "cn"; then
        GITHUB_URL="gitclone.com"
        GITHUB_RAW_URL="ghfast.top/https://raw.githubusercontent.com"
        GITHUB_DOWNLOAD_URL="ghfast.top/https://github.com"
        NTPSERVER="ntp1.aliyun.com"
        TIMEZONE="Asia/Shanghai"
        msg_info "已启用中国大陆镜像加速"
    fi
    if echo "$*" | grep -qwi "k"; then
        import_key=1
        msg_warn "将部署 SSH 公钥到服务器"
    fi
fi

# 安装基础工具包
install(){
    msg_info "安装基础工具包..."
    if [[ x"${release}" == x"centos" ]]; then
        if [ ${os_version} -eq 7 ]; then
            yum clean all
            yum makecache
            yum -y install epel-release
            yum -y install vim wget curl zip unzip bash-completion git tree mlocate lrzsz crontabs libsodium tar lsof nload screen nano python-devel python-pip python3-devel python3-pip socat nc mtr bind-utils yum-utils ntpdate gcc gcc-c++ make iftop traceroute net-tools vnstat pciutils iperf3 iotop htop sysstat bc cmake openssl openssl-devel gnutls ca-certificates systemd sudo
            update-ca-trust force-enable
        else
            # fix https://almalinux.org/blog/2023-12-20-almalinux-8-key-update/
            if [ ${os_version} -eq 8 ]; then
                (
                   . "/etc/os-release"
                   if [ "$ID" == "almalinux" ]; then
                       if ! rpm -q "gpg-pubkey-ced7258b-6525146f" > /dev/null 2>&1; then
                           rpm --import "https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux"
                       fi
                   fi
                )
            fi
            dnf -y install epel-release
            dnf -y install vim wget curl zip unzip bash-completion git tree mlocate lrzsz crontabs libsodium tar lsof nload screen nano python3-devel python3-pip socat nc mtr bind-utils yum-utils gcc gcc-c++ make iftop traceroute net-tools vnstat pciutils iperf3 iotop htop sysstat bc cmake openssl openssl-devel gnutls ca-certificates systemd sudo libmodulemd langpacks-zh_CN glibc-locale-source glibc-langpack-en
        fi
    elif [[ x"${release}" == x"ubuntu" ]]; then
        apt update -y
        echo "iperf3 iperf3/start_daemon boolean false" | debconf-set-selections
        echo "libc6 glibc/restart-services string ssh exim4 cron" | debconf-set-selections
        echo "*	libraries/restart-without-asking	boolean	true" | debconf-set-selections
        apt install -y vim wget curl lrzsz tar lsof dnsutils nload iperf3 screen cron openssl libsodium-dev libgnutls30 ca-certificates systemd python3-dev python3-pip locales-all
        update-ca-certificates
    elif [[ x"${release}" == x"debian" ]]; then
        apt update -y
        echo "iperf3 iperf3/start_daemon boolean false" | debconf-set-selections
        echo "libc6 glibc/restart-services string ssh exim4 cron" | debconf-set-selections
        echo "*	libraries/restart-without-asking	boolean	true" | debconf-set-selections
        apt install -y vim wget curl lrzsz tar lsof dnsutils nload iperf3 screen cron openssl libsodium-dev libgnutls30 ca-certificates systemd python3-dev python3-pip locales-all
        update-ca-certificates
    fi
    
    if [ ! -e /usr/local/bin/tcping ]; then
        wget --timeout=30 --tries=3 -O /tmp/tcping-linux-amd64-static.tar.gz https://${GITHUB_DOWNLOAD_URL}/pouriyajamshidi/tcping/releases/latest/download/tcping-linux-amd64-static.tar.gz
        tar xf /tmp/tcping-linux-amd64-static.tar.gz -C /usr/local/bin/
        chmod +x /usr/local/bin/tcping
        rm -f /tmp/tcping-linux-amd64-static.tar.gz
    fi
    msg_ok "基础工具包安装完成"
}

#配置 SSH 安全策略
set_security(){
    msg_info "配置 SSH 安全策略..."
    if grep -q "^UseDNS" /etc/ssh/sshd_config; then
        sed -i '/^UseDNS/s/yes/no/' /etc/ssh/sshd_config
    else
       sed -i '$a UseDNS no' /etc/ssh/sshd_config
    fi
    if grep -q "^GSSAPIAuthentication" /etc/ssh/sshd_config; then
        sed -i '/^GSSAPIAuthentication/s/yes/no/' /etc/ssh/sshd_config
    else
       sed -i '$a GSSAPIAuthentication no' /etc/ssh/sshd_config
    fi
    if grep -q "^PermitEmptyPasswords" /etc/ssh/sshd_config; then
        sed -i '/^PermitEmptyPasswords/s/yes/no/' /etc/ssh/sshd_config
    else
       sed -i '$a PermitEmptyPasswords no' /etc/ssh/sshd_config
    fi
    if grep -q "^IgnoreRhosts" /etc/ssh/sshd_config; then
        sed -i 's/^IgnoreRhosts.*/IgnoreRhosts yes/' /etc/ssh/sshd_config
    else
       sed -i '$a IgnoreRhosts yes' /etc/ssh/sshd_config
    fi
    if grep -q "^HostbasedAuthentication" /etc/ssh/sshd_config; then
        sed -i '/^HostbasedAuthentication/s/yes/no/' /etc/ssh/sshd_config
    else
       sed -i '$a HostbasedAuthentication no' /etc/ssh/sshd_config
    fi
    if grep -q "^UsePAM" /etc/ssh/sshd_config; then
        sed -i '/^UsePAM/s/no/yes/' /etc/ssh/sshd_config
    else
       sed -i '$a UsePAM yes' /etc/ssh/sshd_config
    fi
    if grep -qiP '^Protocol' /etc/ssh/sshd_config; then
        sed -i "/^Protocol/cProtocol 2" /etc/ssh/sshd_config
    else
       sed -i '$a Protocol 2' /etc/ssh/sshd_config
    fi
    if grep -qiP '^MaxAuthTries' /etc/ssh/sshd_config; then
        sed -i '/^MaxAuthTries[[:space:]]/cMaxAuthTries 3' /etc/ssh/sshd_config
    else
        sed -i '$a MaxAuthTries 3' /etc/ssh/sshd_config
    fi
    if grep -qiP '^ClientAliveInterval' /etc/ssh/sshd_config; then
        sed -i '/^ClientAliveInterval[[:space:]]/cClientAliveInterval 300' /etc/ssh/sshd_config
    else
        sed -i '$a ClientAliveInterval 300' /etc/ssh/sshd_config
    fi
    if grep -qiP '^LoginGraceTime' /etc/ssh/sshd_config; then
        sed -i '/^LoginGraceTime[[:space:]]/cLoginGraceTime 30' /etc/ssh/sshd_config
    else
        sed -i '$a LoginGraceTime 30' /etc/ssh/sshd_config
    fi
    if grep -qiP '^MaxStartups' /etc/ssh/sshd_config; then
        sed -i '/^MaxStartups[[:space:]]/cMaxStartups 10:30:60' /etc/ssh/sshd_config
    else
        sed -i '$a MaxStartups 10:30:60' /etc/ssh/sshd_config
    fi
    if [ -f /etc/selinux/config ]; then
        sed -i '/^SELINUX/s/enforcing/disabled/' /etc/selinux/config
        sed -i '/^SELINUX/s/permissive/disabled/' /etc/selinux/config
        setenforce 0
    fi
    msg_ok "SSH 安全策略配置完成"

    #安全警告：脚本输入k参数时，将部署ssh公钥到服务器
    #部署 SSH 公钥
    if [[ "${import_key}" == "1" ]]; then
        msg_info "部署 SSH 公钥..."
        [ -e /root/.ssh ] || mkdir -m 700 /root/.ssh
        [ -e /root/.ssh/authorized_keys ] || touch /root/.ssh/authorized_keys
        
        #新服务器操作系统中ssh-rsa（rsa/SHA1）签名算法默认被禁用，旧ssh客户端需使用ED25519密钥登录（推荐优先ED25519其次4096位RSA）
        #https://help.aliyun.com/zh/ecs/user-guide/resolve-an-rsa-key-based-connection-failure-to-an-instance
        # ED25519 密钥
        if [ "$(grep -c "ed25519 256-250324" /root/.ssh/authorized_keys)" -eq 0 ]; then
            echo -e "\nssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQGxmeW+E1nNIzRZZrwMwbmrsGKZy9Gnu1NSt84mXT1 ed25519 256-250324" >> /root/.ssh/authorized_keys
            if [ $? -eq 0 ]; then
                msg_ok "ED25519 公钥部署成功"
            else
                msg_warn "ED25519 公钥部署失败，请检查"
            fi
        else
            msg_info "ED25519 公钥已存在，跳过"
        fi
        
        # RSA 密钥
        if [ "$(grep -c "rsa 4096-250324" /root/.ssh/authorized_keys)" -eq 0 ]; then
            KEY_CHECKSUM="ef7d690265ea090c77025d133198e21f"
            wget --timeout=30 --tries=3 -O /tmp/id_rsa_4096.pub https://${GITHUB_RAW_URL}/myxuchangbin/shellscript/main/id_rsa_4096.pub
            if echo "$KEY_CHECKSUM  /tmp/id_rsa_4096.pub" | md5sum -c; then
                cat /tmp/id_rsa_4096.pub >> /root/.ssh/authorized_keys
                if [ $? -eq 0 ]; then
                    msg_ok "RSA 公钥部署成功"
                else
                    msg_warn "RSA 公钥部署失败，请检查"
                fi
            else
                msg_error "RSA 公钥校验失败，终止部署"
            fi
            rm -f /tmp/id_rsa_4096.pub
        else
            msg_info "RSA 公钥已存在，跳过"
        fi
    fi

    # 配置系统时区
    msg_info "配置系统时区..."
    if [[ x"${release}" == x"centos" ]]; then
        if [ ${os_version} -eq 7 ]; then
            if [ "$(timedatectl | grep "Time zone" | grep -c "${TIMEZONE}")" -eq 0 ]; then
                timedatectl set-timezone ${TIMEZONE}
                sed -i 's%SYNC_HWCLOCK=no%SYNC_HWCLOCK=yes%' /etc/sysconfig/ntpdate
            fi
            ntpdate ${NTPSERVER}
            hwclock -w
        else
            if [ "$(timedatectl | grep "Time zone" | grep -c "${TIMEZONE}")" -eq 0 ]; then
                timedatectl set-timezone ${TIMEZONE}
                echo "server ${NTPSERVER} iburst" >>/etc/chrony.conf
                systemctl restart chronyd.service
                chronyc -a makestep
            fi
        fi
    elif [[ x"${release}" == x"ubuntu" ]] || [[ x"${release}" == x"debian" ]]; then
        if [ "$(timedatectl | grep "Time zone" | grep -c "${TIMEZONE}")" -eq 0 ]; then
            timedatectl set-timezone ${TIMEZONE}
        fi 
    fi
    msg_ok "系统时区配置完成"

    # 启用历史命令时间戳
    msg_info "启用历史命令时间戳..."
    if ! grep -q 'HISTTIMEFORMAT=' /etc/profile; then
        echo "export HISTTIMEFORMAT=\"%F %T \`whoami\` \"" >> /etc/profile
    fi
    msg_ok "历史命令时间戳已启用"

    # 禁用 Ctrl+Alt+Del 重启
    msg_info "禁用 Ctrl+Alt+Del 重启..."
    rm -rf /usr/lib/systemd/system/ctrl-alt-del.target
    msg_ok "Ctrl+Alt+Del 重启已禁用"

    # 配置系统字符集
    msg_info "配置系统字符集..."
    if [[ x"${release}" == x"centos" ]]; then
        localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8
        export LC_ALL=zh_CN.UTF-8
        if grep -q "^LANG" /etc/locale.conf; then
            sed -i '/^LANG=/s/.*/LANG=zh_CN.UTF-8/' /etc/locale.conf
        else
           sed -i '$a LANG=zh_CN.UTF-8' /etc/locale.conf
        fi
        msg_ok "系统字符集配置完成"
    elif [[ x"${release}" == x"ubuntu" ]] || [[ x"${release}" == x"debian" ]]; then
        locale-gen zh_CN.UTF-8 2>/dev/null || true
        update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 2>/dev/null || true
        msg_info "已生成 zh_CN.UTF-8 字符集"
    fi

    # 配置定时内存回收
    msg_info "配置定时内存回收..."
    crontab -l > /tmp/drop_cachescronconf
    if grep -wq "drop_caches" /tmp/drop_cachescronconf; then
        sed -i "/drop_caches/d" /tmp/drop_cachescronconf
    fi
    echo "0 6 * * * sync; echo 3 > /proc/sys/vm/drop_caches" >> /tmp/drop_cachescronconf
    crontab /tmp/drop_cachescronconf
    rm -f /tmp/drop_cachescronconf
    msg_ok "定时内存回收已配置"
}

# 配置系统资源限制
set_file(){
    msg_info "配置系统资源限制..."
    limits=/etc/security/limits.conf
    grep -Fxq "root soft nofile 512000"  $limits || echo "root soft nofile 512000"  >> $limits
    grep -Fxq "root hard nofile 512000"  $limits || echo "root hard nofile 512000"  >> $limits
    grep -Fxq "* soft nofile 512000"     $limits || echo "* soft nofile 512000"     >> $limits
    grep -Fxq "* hard nofile 512000"     $limits || echo "* hard nofile 512000"     >> $limits
    grep -Fxq "* soft nproc 512000"      $limits || echo "* soft nproc 512000"      >> $limits
    grep -Fxq "* hard nproc 512000"      $limits || echo "* hard nproc 512000"      >> $limits

    if [[ x"${release}" == x"centos" ]]; then
        if [ ${os_version} -eq 7 ]; then
            [[ -f /etc/security/limits.d/20-nproc.conf ]] && sed -i 's/4096/65535/' /etc/security/limits.d/20-nproc.conf
        fi
    fi

    ulimit -SHn 512000
    if grep -q "^ulimit" /etc/profile; then
        sed -i '/ulimit -SHn/d' /etc/profile
        echo -e "\nulimit -SHn 512000" >> /etc/profile
    else
        echo -e "\nulimit -SHn 512000" >> /etc/profile
    fi

    if [ -e /etc/pam.d/common-session ]; then
        if ! grep -q "pam_limits.so" /etc/pam.d/common-session; then
            echo "session required pam_limits.so" >> /etc/pam.d/common-session
        fi
    else
        echo "session required pam_limits.so" >> /etc/pam.d/common-session
    fi

    if [ -e /etc/pam.d/common-session-noninteractive ]; then
        if ! grep -q "pam_limits.so" /etc/pam.d/common-session-noninteractive; then
            echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive
        fi
    else
        echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive
    fi

    if grep -q "^DefaultLimitCORE" /etc/systemd/system.conf; then
        sed -i '/DefaultLimitCORE/d' /etc/systemd/system.conf
        echo "DefaultLimitCORE=infinity" >> /etc/systemd/system.conf
    else
        echo "DefaultLimitCORE=infinity" >> /etc/systemd/system.conf
    fi

    if grep -q "^DefaultLimitNOFILE" /etc/systemd/system.conf; then
        sed -i '/DefaultLimitNOFILE/d' /etc/systemd/system.conf
        echo "DefaultLimitNOFILE=512000" >> /etc/systemd/system.conf
    else
        echo "DefaultLimitNOFILE=512000" >> /etc/systemd/system.conf
    fi

    if grep -q "^DefaultLimitNPROC" /etc/systemd/system.conf; then
        sed -i '/DefaultLimitNPROC/d' /etc/systemd/system.conf
        echo "DefaultLimitNPROC=512000" >> /etc/systemd/system.conf
    else
        echo "DefaultLimitNPROC=512000" >> /etc/systemd/system.conf
    fi

    systemctl daemon-reload
    msg_ok "系统资源限制配置完成"
}

# 配置网络与内核参数
set_sysctl(){
    msg_info "配置网络与内核参数..."
    sed -i '/net.ipv4.icmp_echo_ignore_broadcasts/d' /etc/sysctl.conf
    sed -i '/net.ipv4.icmp_ignore_bogus_error_responses/d' /etc/sysctl.conf
    sed -i '/net.ipv4.conf.all.rp_filter/d' /etc/sysctl.conf
    sed -i '/net.ipv4.conf.default.rp_filter/d' /etc/sysctl.conf
    sed -i '/net.ipv4.conf.all.accept_source_route/d' /etc/sysctl.conf
    sed -i '/net.ipv4.conf.default.accept_source_route/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.all.accept_source_route/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.default.accept_source_route/d' /etc/sysctl.conf
    sed -i '/kernel.sysrq/d' /etc/sysctl.conf
    sed -i '/kernel.core_uses_pid/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
    sed -i '/kernel.msgmnb/d' /etc/sysctl.conf
    sed -i '/kernel.msgmax/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_sack/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_fack/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_window_scaling/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
    sed -i '/net.core.wmem_default/d' /etc/sysctl.conf
    sed -i '/net.core.rmem_default/d' /etc/sysctl.conf
    sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
    sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
    sed -i '/net.ipv4.udp_rmem_min/d' /etc/sysctl.conf
    sed -i '/net.ipv4.udp_wmem_min/d' /etc/sysctl.conf
    sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_tw_recycle/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
    sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
    sed -i '/net.ipv4.ip_local_reserved_ports/d' /etc/sysctl.conf
    sed -i '/net.ipv4.conf.all.accept_redirects/d' /etc/sysctl.conf
    sed -i '/net.ipv4.conf.default.accept_redirects/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.all.accept_redirects/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.default.accept_redirects/d' /etc/sysctl.conf
    sed -i '/net.ipv4.conf.all.secure_redirects/d' /etc/sysctl.conf
    sed -i '/net.ipv4.conf.default.secure_redirects/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_no_metrics_save/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_moderate_rcvbuf/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_retries2/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.conf
    sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf
    sed -i '/net.ipv6.bindv6only/d' /etc/sysctl.conf
    sed -i '/fs.file-max/d' /etc/sysctl.conf
    sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
    sed -i '/vm.swappiness/d' /etc/sysctl.conf
    sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_keepalive_time/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_keepalive_probes/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_keepalive_intvl/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.conf
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    
    cat << EOF >> /etc/sysctl.conf
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65535
kernel.msgmax = 65535
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.wmem_default = 65536
net.core.rmem_default = 65536
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.udp_rmem_min=4096
net.ipv4.udp_wmem_min=4096
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.ip_local_port_range = 16384 65535
#net.ipv4.ip_local_reserved_ports = 10001-10005
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.route.gc_timeout = 100
net.ipv6.bindv6only = 0
fs.file-max = 512000
fs.inotify.max_user_instances = 8192
vm.swappiness = 0
net.core.somaxconn = 32768
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
#net.ipv4.tcp_notsent_lowat = 16384
EOF

    msg_info "应用 sysctl 配置..."
    /sbin/sysctl -p /etc/sysctl.conf 2>/dev/null | awk -F' = ' -v g="$green" -v o="$OK" -v p="$plain" '{printf "  %s%s%s %-35s = %s\n", g, o, p, $1, $2}'
    msg_ok "网络与内核参数配置完成"
}

# 检查 BBR 状态
check_bbr(){
    kernel_version=$(uname -r | awk -F "-" '{print $1}')
    if [[ $(echo ${kernel_version} | awk -F'.' '{print $1}') == "4" ]] && [[ $(echo ${kernel_version} | awk -F'.' '{print $2}') -ge 9 ]] || [[ $(echo ${kernel_version} | awk -F'.' '{print $1}') == "5" ]] || [[ $(echo ${kernel_version} | awk -F'.' '{print $1}') == "6" ]]; then
        kernel_status="BBR"
    else
        kernel_status="noinstall"
    fi
    
    if [[ ${kernel_status} == "BBR" ]]; then
        bbr_run_status=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
        if [[ ${bbr_run_status} == "bbr" ]]; then
            bbr_run_status="${green}已启用${plain}"
        else
            bbr_run_status="${yellow}未启用${plain}"
        fi
    else
        bbr_run_status="${yellow}内核版本过低（当前: ${kernel_version}，需要 4.9+）${plain}"
    fi
}

# 配置熵池增强服务
set_entropy(){
    entropy_value=$(cat /proc/sys/kernel/random/entropy_avail)
    if [[ ${entropy_value} -lt 1000 && ${entropy_value} -ne 256 ]]; then
        msg_info "配置熵池增强服务..."
        if grep -q "rdrand" /proc/cpuinfo; then
            if [[ x"${release}" == x"centos" ]]; then
                yum -y install rng-tools
                systemctl enable --now rngd
            elif [[ x"${release}" == x"ubuntu" ]]; then
                apt install -y rng-tools
                systemctl enable --now rngd
            elif [[ x"${release}" == x"debian" ]]; then
                apt install -y rng-tools
                systemctl enable --now rngd
            fi
        else
            if [[ x"${release}" == x"centos" ]]; then
                yum -y install haveged
                systemctl enable --now haveged
            elif [[ x"${release}" == x"ubuntu" ]]; then
                apt install -y haveged
                systemctl enable --now haveged
            elif [[ x"${release}" == x"debian" ]]; then
                apt install -y haveged
                systemctl enable --now haveged
            fi
        fi
        msg_ok "熵池增强服务已启用"
    fi
}

# 配置 Vim 编辑器
set_vimserver(){
    msg_info "配置 Vim 编辑器..."
    if [[ x"${release}" == x"centos" ]]; then
        sys_vimrc=/etc/vimrc
    else
        sys_vimrc=/etc/vim/vimrc
    fi
    user_vimrc=~/.vimrc
    
    for opt in \
        'set cursorline' \
        'set autoindent' \
        'set showmode' \
        'set ruler' \
        'syntax on' \
        'filetype on' \
        'set smartindent' \
        'set tabstop=4' \
        'set shiftwidth=4' \
        'set hlsearch' \
        'set incsearch' \
        'set ignorecase'
    do
        grep -Fxq "$opt" "$sys_vimrc" || echo "$opt" >> "$sys_vimrc"
    done

    [[ -e $user_vimrc ]] || touch "$user_vimrc"
    for enc in \
        'set fileencodings=utf-8,gbk,utf-16le,cp1252,iso-8859-15,ucs-bom' \
        'set termencoding=utf-8' \
        'set encoding=utf-8'
    do
        grep -Fxq "$enc" "$user_vimrc" || echo "$enc" >> "$user_vimrc"
    done
    msg_ok "Vim 编辑器配置完成"
}

# 配置 Journald 日志服务
set_journal(){
    msg_info "配置 Journald 日志服务..."
    [ -e /var/log/journal ] || mkdir /var/log/journal
    
    if grep -q "^Storage" /etc/systemd/journald.conf; then
        sed -i '/^Storage/s/auto/persistent/' /etc/systemd/journald.conf
    else
       sed -i '$a Storage=persistent' /etc/systemd/journald.conf
    fi
    
    if grep -q "^ForwardToSyslog" /etc/systemd/journald.conf; then
        sed -i '/^ForwardToSyslog/s/yes/no/' /etc/systemd/journald.conf
    else
       sed -i '$a ForwardToSyslog=no' /etc/systemd/journald.conf
    fi
    
    if grep -q "^ForwardToWall" /etc/systemd/journald.conf; then
        sed -i '/^ForwardToWall/s/yes/no/' /etc/systemd/journald.conf
    else
       sed -i '$a ForwardToWall=no' /etc/systemd/journald.conf
    fi
    
    if grep -q "^SystemMaxUse" /etc/systemd/journald.conf; then
        sed -i '/^SystemMaxUse/s/.*/SystemMaxUse=384M/' /etc/systemd/journald.conf
    else
       sed -i '$a SystemMaxUse=384M' /etc/systemd/journald.conf
    fi
    
    if grep -q "^SystemMaxFileSize" /etc/systemd/journald.conf; then
        sed -i '/^SystemMaxFileSize/s/.*/SystemMaxFileSize=128M/' /etc/systemd/journald.conf
    else
       sed -i '$a SystemMaxFileSize=128M' /etc/systemd/journald.conf
    fi
    
    systemctl restart systemd-journald
    msg_ok "Journald 日志服务配置完成"
}

# 配置 Readline 快捷键
set_readlines(){
    msg_info "配置 Readline 快捷键..."
    if grep -q '^"\\e.*": history-search-backward' /etc/inputrc; then
        sed -i 's/^"\\e.*": history-search-backward/"\\e\[A": history-search-backward/g' /etc/inputrc
    else
        sed -i '$a # map "up arrow" to search the history based on lead characters typed' /etc/inputrc
        sed -i '$a "\\e\[A": history-search-backward' /etc/inputrc
    fi
    
    if grep -q '^"\\e.*": history-search-forward' /etc/inputrc; then
        sed -i 's/^"\\e.*": history-search-forward/"\\e\[B": history-search-forward/g' /etc/inputrc
    else
        sed -i '$a # map "down arrow" to search history based on lead characters typed' /etc/inputrc
        sed -i '$a "\\e\[B": history-search-forward' /etc/inputrc
    fi
    
    if grep -q '"\\e.*": kill-word' /etc/inputrc; then
        sed -i 's/"\\e.*": kill-word/"\\e[3;3~": kill-word/g' /etc/inputrc
    else
        sed -i '$a # map ALT+Delete to remove word forward' /etc/inputrc
        sed -i '$a "\\e[3;3~": kill-word' /etc/inputrc
    fi
    msg_ok "Readline 快捷键配置完成"
}

# 配置虚拟化驱动（Centos外置virtio-blk和xen-blkfront）
set_drivers(){
    if [[ x"${release}" == x"centos" ]]; then
        msg_info "配置虚拟化驱动..."
        if [ ! -e /etc/dracut.conf.d/virt-drivers.conf ]; then
            echo 'add_drivers+=" xen-blkfront virtio_blk "' >> /etc/dracut.conf.d/virt-drivers.conf
        else
            if ! grep -wq "xen-blkfront" /etc/dracut.conf.d/virt-drivers.conf; then
                echo 'add_drivers+=" xen-blkfront virtio_blk "' >> /etc/dracut.conf.d/virt-drivers.conf
            fi
        fi
        msg_ok "虚拟化驱动配置完成"
    fi
}

# 配置登录欢迎信息
set_welcome(){
    msg_info "配置登录欢迎信息..."
    if [ ! -e /etc/profile.d/motd.sh ]; then
        wget --timeout=30 --tries=3 -O /etc/profile.d/motd.sh https://${GITHUB_RAW_URL}/myxuchangbin/shellscript/main/motd.sh
        chmod a+x /etc/profile.d/motd.sh
    fi
    msg_ok "登录欢迎信息配置完成"
}

# 主函数
main(){
    # 开始边框
    echo -e "\n${green}╔════════════════════════════════════════════════╗${plain}"
    echo -e "${green}║${plain}     系统初始化优化脚本 - 开始执行              ${green}║${plain}"
    echo -e "${green}╚════════════════════════════════════════════════╝${plain}\n"
    
    install
    set_security
    set_file
    set_sysctl
    check_bbr
    set_entropy
    set_vimserver
    set_journal
    set_readlines
    set_drivers
    set_welcome
    
    # 结束边框
    echo -e "\n${green}╔════════════════════════════════════════════════╗${plain}"
    echo -e "${green}║${plain}     系统初始化优化脚本 - 执行完毕              ${green}║${plain}"
    echo -e "${green}╚════════════════════════════════════════════════╝${plain}\n"
}

main

rm -f "$0" 2>/dev/null || true
history -c

if [[ "${import_key}" == "1" ]]; then
    echo -e "${yellowflash}${WARN} 安全提醒：/root/.ssh/authorized_keys 已写入 SSH 公钥${plain}"
    echo -e "${yellowflash}           若非本人操作，请立即手动删除公钥！${plain}\n"
fi

echo -e "${INFO} BBR 状态：${bbr_run_status}  |  完成时间：$(date '+%F %T')\n"
