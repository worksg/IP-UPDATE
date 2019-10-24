#! /bin/bash

command -v 'curl' &>/dev/null || exit 1
command -v 'tar' &>/dev/null || exit 1
command -v 'sha256sum' &>/dev/null || exit 1
command -v 'awk' &>/dev/null || exit 1

source travis-ci-git-commit.bash

travis-branch-commit-init

ipv4_url='https://raw.github.com/17mon/china_ip_list/master/china_ip_list.txt'
ipv6_url='https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest'
domains_china='https://raw.github.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf'
domains_gfw='https://raw.github.com/gfwlist/gfwlist/master/gfwlist.txt'

mkdir download_temp
cd download_temp

curl -4sSkL "$ipv4_url" -o addr_ipv4.txt
curl -4sSkL "$ipv6_url" -o addr_ipv6.txt
curl -4sSkL "$domains_china" -o domains_china.txt
curl -4sSkL "$domains_gfw" -o domains_gfw.txt

## define an array ##
arrayname=( addr_ipv4 addr_ipv6 domains_china domains_gfw )

## get item count using ${arrayname[@]} ##
for filename in "${arrayname[@]}"
do
    if [ -f "../${filename}.tar.gz" ]; then
        new_sha256=`sha256sum "${filename}.txt" | awk '{ printf $1 }'`
        old_sha256=`tar zxf "../${filename}.tar.gz" -O | sha256sum - | awk '{ printf $1 }'`
        if [ "$new_sha256" != "$old_sha256" ]; then 
            tar czf "${filename}.tar.gz" "${filename}.txt"
            mv -f "${filename}.tar.gz" "../${filename}.tar.gz"
        fi
    else
        tar czf "${filename}.tar.gz" "${filename}.txt"
        mv -f "${filename}.tar.gz" "../${filename}.tar.gz"
    fi
done

rm -fv *.txt

cd -

rm -fr download_temp

git add -A -- .

git commit -m "travis automated update $(date -u \+\%Y\%m\%dT\%H\%M\%SZ) [CI SKIP]"

git push origin master:master
