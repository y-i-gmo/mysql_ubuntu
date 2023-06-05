
-- user
-- skip binlog
SET sql_log_bin = 0;

CREATE USER 'study'@'192.168.100.%' IDENTIFIED BY 'study';
GRANT ALL ON *.* TO 'study'@'192.168.100.%';

CREATE USER 'study_ro'@'%' IDENTIFIED BY 'study_ro';
GRANT SELECT ON *.* TO 'study_ro'@'%';

CREATE USER 'repl'@'192.168.100.%' IDENTIFIED WITH mysql_native_password BY 'repl';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.100.%';

SET sql_log_bin = 1;

-- DB
CREATE DATABASE IF NOT EXISTS study  CHARACTER SET utf8mb4 COLLATE utf8mb4_bin ;

