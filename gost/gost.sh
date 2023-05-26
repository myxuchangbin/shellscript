#!/usr/bin/env bash
# Wiki: https://v2.gost.run/
# Usage: bash <(curl -s https://raw.githubusercontent.com/myxuchangbin/shellscript/master/gost/gost.sh)
# Uninstall: systemctl disable gost --now ; rm -rf /etc/systemd/system/gost.service /opt/gost

GITHUB_RAW_URL="raw.githubusercontent.com"
GITHUB_URL="github.com"
CN=0
customversion=0

# -v 指定版本号
# -c 国内加速模式
# -h 帮助信息
while getopts ":v:ch" optname
do
    case "$optname" in
      "v")
        targetversion=$OPTARG
        customversion=1
        ;;
      "c")
        CN=1
        ;;
      "h")
        echo "支持选项: -v 指定版本号 -c 国内加速模式"
        exit 0
        ;;
      ":")
        echo "选项 $OPTARG 无参数值"
        exit 1
        ;;
      "?")
        echo "无效选项 $OPTARG"
        exit 1
        ;;
    esac
done
if [ ${customversion} = 0 ]; then
  # 获取最新版本号
  targetversion=$(wget -qO- -t1 -T2 "https://api.github.com/repos/ginuerzh/gost/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/v//g;s/,//g;s/ //g')
  if [ -z $targetversion ]; then
      echo -e "获取Gost最新版本号失败，请使用参数 -v 2.11.5 手动指定版本号来继续安装"
      exit 1
  fi
fi
if [ ${CN} == 1 ]; then
    URL="https://ghproxy.com/https://github.com/ginuerzh/gost/releases/download/v${targetversion}/gost-linux-amd64-${targetversion}.gz"
    GITHUB_RAW_URL="raw.fastgit.org"
    GITHUB_URL="hub.fastgit.org"
else
    URL="https://github.com/ginuerzh/gost/releases/download/v${targetversion}/gost-linux-amd64-${targetversion}.gz"
fi
[ -e /opt/gost/ ] || mkdir -p /opt/gost/
[ -e /opt/gost/config.json ] || wget https://${GITHUB_RAW_URL}/myxuchangbin/shellscript/master/gost/config.json -O /opt/gost/config.json
[ -e /opt/gost/gost ] && rm -rf /opt/gost/gost
wget -O - $URL | gzip -d > /opt/gost/gost && chmod +x /opt/gost/gost
tmpdomain=`echo $RANDOM | md5sum | cut -c1-8`
openssl req -newkey rsa:4096 \
            -x509 \
            -sha256 \
            -days 3650 \
            -nodes \
            -out /opt/gost/cert.pem \
            -keyout /opt/gost/key.pem \
            -subj "/C=US/ST=Alabama/L=Montgomery/O=Super Shops/OU=Marketing/CN=www.${tmpdomain}.com"

cat <<EOF > /etc/systemd/system/gost.service
[Unit]
Description=Gost server
After=network-online.target
Wants=network-online.target

[Service]
LimitCORE=infinity
LimitNOFILE=512000
LimitNPROC=512000
Type=simple
DynamicUser=yes
StandardOutput=null
#StandardError=journal
WorkingDirectory=/opt/gost
ExecStart=/opt/gost/gost -C /opt/gost/config.json
User=root
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

crontab -l > /tmp/gostcronconf
if grep -wq "gost.service" /tmp/gostcronconf;then
  sed -i "/gost.service/d" /tmp/gostcronconf
fi
echo "0 6 * * *  /usr/bin/systemctl restart gost.service" >> /tmp/gostcronconf
crontab /tmp/gostcronconf
rm -f /tmp/gostcronconf
echo -e "已设置每天6:00定时重启gost服务，以释放服务器内存压力"

systemctl daemon-reload
systemctl enable gost.service
systemctl restart gost.service
sleep 2
systemctl --no-pager status gost.service
