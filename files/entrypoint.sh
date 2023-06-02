#!/bin/sh


# my.cnf 置換
ip4=`ifconfig | grep 192 | awk -F. '{print $4}' | awk -F" " '{print $1}'`
sed -i "s/server-id = 1/server-id = $ip4/g" /etc/mysql/mysql.conf.d/mysqld.cnf
cat /etc/mysql/mysql.conf.d/mysqld.cnf


# コンテナが起動して常に実行するべきプロセスを開始する
exec "$@"

