# ローカル環境構築 MySQL8 + ubuntu 22.04 + docker

## 概要

mysql8のローカル検証環境を構築するdocker scirpt  
2台構成のmysql8コンテナを docker-compose で構築する。  
M1 Mac でVagrantが使えない代わりになる環境を目指した。  

## 特徴

systemctlが使える ubuntu22.04  
mysql directory (/var/lib/mysql)を永続化済み  
M1 MacBook にて動作する  

## 使い方

docker volume作成 (永続化のため)
```
docker volume create db1vol
docker volume create db2vol
```
起動（バックグラウンド）
```
docker up -d --build &
```
起動確認
```
docker ps
```
コンテナへログイン
```
db1コンテナ
docker exec -it mysql-db1-1 bash
db2コンテナ
docker exec -it mysql-db2-1 bash
```

## MySQL 

#### mysql起動/終了

起動/終了/状態確認
```
rootユーザー
systemctl status mysql
systemctl stop mysql
systemctl start mysql
```

#### 初期設定

パスワード設定（secure_installのため）
```
mysql -uroot
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password by '{password}';
exit
```
セキュリティ
```
mysql_secure_installation
```

#### MySQLユーザー作成

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

レプリケーションユーザー
```
CREATE USER 'repl'@'192.168.100.%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.100.%';
```

#### ログイン確認

各MySQLユーザーで
・ローカルDBへ接続(db1->db1,  db2->db2)
・リモートDBへ接続（db2 -> db1）


#### DB/TABLE作成

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

my.cnf
export
import
replication設定

