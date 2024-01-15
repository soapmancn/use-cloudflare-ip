#!/bin/bash

[[ ! -d "/usr/share/passwall/cloudflare" ]] && mkdir -p /usr/share/passwall/cloudflare
cd /usr/share/passwall/cloudflare

arch=$(uname -m)
if [[ ${arch} =~ "x86" ]]; then
	tag="amd"
	[[ ${arch} =~ "64" ]] && tag="amd64"
elif [[ ${arch} =~ "aarch" ]]; then
	tag="arm"
	[[ ${arch} =~ "64" ]] && tag="arm64"
else
	exit 1
fi

version=$(curl -s https://api.github.com/repos/XIU2/CloudflareSpeedTest/tags | sed -n 's/.*"name": "\(.*\)".*/\1/p' | head -n 1)
old_version=$(cat CloudflareST_version.txt )

if [[ ! -f "CloudflareST" || ${version} != ${old_version} ]]; then
	rm -rf CloudflareST_linux_${tag}.tar.gz
	wget -N https://github.com/XIU2/CloudflareSpeedTest/releases/download/${version}/CloudflareST_linux_${tag}.tar.gz
	echo "${version}" > CloudflareST_version.txt
	tar -xvf CloudflareST_linux_${tag}.tar.gz
	chmod +x CloudflareST
fi

##注意修改！！！
/etc/init.d/passwall stop
wait

./CloudflareST -dn 10 -tll 40 -o cf_result.txt
wait
sleep 3

if [[ -f "cf_result.txt" ]]; then
	first=$(sed -n '2p' cf_result.txt | awk -F ',' '{print $1}') && echo $first >>ip-all.txt
	wait
	uci commit passwall
	wait
	##注意修改！！！
	sed -i "s/$(uci get passwall.YJYS73HC.address)/${first}/g" /etc/config/passwall
	wait
	uci commit passwall
	wait
	/etc/init.d/passwall start
fi
