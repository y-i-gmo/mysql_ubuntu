# ローカル環境構築 MySQL8 + ubuntu 22.04 + docker

## 概要

mysql8のローカル検証環境を構築するdocker scirpt  
2台構成のmysql8コンテナを docker-compose で構築する。  
M1 Mac で使えなくなった Vagrant 代わりになる環境を目指した。  

## 特徴

docker コンテナ上で systemctl が使える ubuntu22.04 を構築  
mysql directory (/var/lib/mysql)を永続化済み  
M1/M2/Intel Mac にて動作する  

## 必要tool

doker  
docker compose (古いバージョンの方はdocker-compose)  

## 作成/起動方法

docker volume作成 (永続化のため)
```
docker volume create db1vol
docker volume create db2vol
```
起動（バックグラウンド）
```
docker compose up -d --build
 or 
docker-compose up -d --build -f compose.yaml
```
起動確認
```
docker ps
```
コンテナへログイン
```
db1コンテナ
docker exec -it db1 bash
db2コンテナ
docker exec -it db2 bash
```

## 再作成方法

docker containerの削除
```
docker compose stop && docker compose rm -f
```
docker imageの削除
```
docker rmi mysql_ubuntu-db1 mysql_ubuntu-db2
```
docker volumeの削除
```
docker volume rm db2vol db1vol
```
※新規に作り直す場合、上記作成/起動方法へ


## MySQL 

#### mysql起動/終了

起動/終了/状態確認コマンド
```
- terminalで実行
@rootユーザー

systemctl status mysql
systemctl stop mysql
systemctl start mysql
```

#### 初期設定

パスワード設定（secure_installのため）
```
- mysql接続して実行
mysql -uroot

ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password by 'root';
　　# パスワード適宜変更してください
exit
```
セキュリティ
```
mysql_secure_installation
```

#### MySQLユーザー作成

@db1コンテナで確認

studyユーザー（フル権限/非推奨）
```
CREATE USER 'study'@'192.168.100.%' IDENTIFIED BY 'study';
GRANT ALL ON *.* TO 'study'@'192.168.100.%';
```
study_readonlyユーザー（権限限定）
```
CREATE USER 'study_ro'@'%' IDENTIFIED BY 'study_ro';
GRANT SELECT ON *.* TO 'study_ro'@'%';
```
レプリケーションユーザー作成
```
CREATE USER 'repl'@'192.168.100.%' IDENTIFIED WITH mysql_native_password BY 'repl';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.100.%';
```

default設定では接続できないはず  
リモートホストからの接続を許可する  

/etc/mysql/mysql.conf.d/mysqld.cnf
```
コメントアウト(#をつける)
# bind-address            = 127.0.0.1
# mysqlx-bind-address     = 127.0.0.1
```
mysql 再起動
```
systemctl stop mysql
systemctl start mysql
systemctl status mysql
```

#### DB/TABLE作成

※db1コンテナmysqlでテーブル/レコードを作成して、レプリケーション構築したレプリカDB(db2)に反映されることを確認

mysqlコマンド
```
mysql -ustudy -pstudy -h192.168.100.11
```

study DB
```
CREATE DATABASE IF NOT EXISTS study  CHARACTER SET utf8mb4 COLLATE utf8mb4_bin ;
```
T1 TABLE
```
CREATE TABLE IF NOT EXISTS `study`.`t1` (
  id int(11) not null  auto_increment
  ,name varchar(100) null
  ,idx_num int(11) null
  ,created_at datetime
  ,PRIMARY KEY (id)
  ,KEY idx01 (idx_num)
);
```
INSERT
```
INSERT INTO `study`.`t1` (id, name, idx_num, created_at) VALUES (null, 'name01', 1, now());
```


#### レプリケーション構築

共通設定

@db1コンテナで作業  

my.cnf  
/etc/mysql/mysql.conf.d/mysqld.cnf  
```
- ubuntu terminalで作業

server-id=1
log_replica_updates

- 他必要に応じて設定
# log_bin = /var/log/mysql/mysql-bin.log
# binlog_expire_logs_seconds = 2592000
# max_binlog_size = 100M
```

@db2コンテナで作業  
my.cnf  
/etc/mysql/mysql.conf.d/mysqld.cnf  
```
- ubuntu terminalで作業

server-id=2
log_replica_updates

- 他必要に応じて設定
# log_bin = /var/log/mysql/mysql-bin.log
# binlog_expire_logs_seconds = 2592000
# max_binlog_size = 100M
```


##### 非同期レプリケーション(postion)

@db1コンテナで作業  

export  
```
mysqldump -uroot -p --default-character-set=binary  --single-transaction --master-data=2 --flush-logs --complete-insert --add-drop-database --databases study > /tmp/db1.dump
```

ファイル転送
```
@hostos
docker cp "db1:/tmp/db1.dump" .
docker cp ./db1.dump db2:/tmp/db1.dump
```


@db2コンテナで作業  

db1.dump 確認
```
less /tmp/db1.dump

TODO: 
```

import  
```
- ubuntu terminalで作業

mysql -uroot < /tmp/db1.dump
```

replication設定  
```
- mysql接続して作業
mysql -uroot

CHANGE MASTER TO
  MASTER_HOST='192.168.100.11'
  ,MASTER_USER='repl'
  ,MASTER_PASSWORD='repl'
  ,MASTER_LOG_FILE='binlog.000008'
  ,MASTER_LOG_POS=157
;

MASTER_LOG_FILE と MASTER_LOG_POS を db1.dump の値に変更する
```
確認
```
- mysql接続して作業

show replica status\G
```
replication開始
```
- mysql接続して作業

start replica;
```
確認
```
- mysql接続して作業

show replica status\G

こちらがともに Yes となればレプリケーション構築が成功しています。
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
```

UUIDが重複した場合、auto.cnfを削除する  
```
MySQL server UUIDs; these UUIDs must be different for replication to work  
```
削除
```
rm /var/lib/mysql/auto.cnf
```
mysql再起動
```
systemctl restart mysql
```

replication構築できたら, db1 mysqlでtableやrecordを作成してdb2に複製されているか確認してみよう  
  
mysqlコマンド
```
mysql -ustudy -p -h192.168.100.11
```

T2 TABLE
```
CREATE TABLE IF NOT EXISTS `study`.`t2` (
  id int(11) not null  auto_increment
  ,name varchar(100) null
  ,idx_num int(11) null
  ,created_at datetime
  ,PRIMARY KEY (id)
  ,KEY idx01 (idx_num)
);
```
INSERT
```
INSERT INTO `study`.`t1` (id, name, idx_num, created_at) VALUES (null, 'name02', 2, now());

INSERT INTO `study`.`t2` (id, name, idx_num, created_at) VALUES (null, 'name01', 1, now());
```


##### 非同期レプリケーション(GTID)

既存replication設定をリセット  
@db2コンテナ  

mysqlコマンド
```
mysql -ustudy -p -h192.168.100.12
```

リセット
```
stop replica;
reset replica all;
```
レプリケーション設定
```
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = '192.168.100.11',
  SOURCE_USER = 'repl',
  SOURCE_PASSWORD = 'repl',
  SOURCE_AUTO_POSITION = 1;
```
レプリケーション開始
```
start replica;
```
確認
```
show replica status;
```


