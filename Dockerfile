# os
#FROM ubuntu:22.04
FROM ubuntu:24.04

# tools
RUN apt-get -y update \
 && apt-get install -y init systemd \
 && apt-get install -y net-tools iputils-ping curl wget telnet less vim sudo \
 && apt-get install -y tzdata locales && locale-gen ja_JP.UTF-8 \
 && apt-get install -y lsb-release  gnupg \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# JP対応
ENV TZ Asia/Tokyo
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja

# MySQL8
RUN curl -OL https://dev.mysql.com/get/mysql-apt-config_0.8.34-1_all.deb
RUN apt-get install -y ./mysql-apt-config_0.8.34-1_all.deb
RUN apt-get -y update \
 && apt-get install -y mysql-server
VOLUME /var/lib/mysql
COPY files/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
COPY files/setup.sql /setup.sql

# 起動時実行: mysql server-idを設定
COPY files/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["sh", "/entrypoint.sh"]
CMD ["systemctl", "restart", "mysql"]

