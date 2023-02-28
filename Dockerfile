FROM ubuntu:22.04

# os setup
RUN apt-get -y update \
 && apt-get install -y init \
 && apt-get install -y systemd \
 && apt-get install -y net-tools iputils-ping curl wget telnet less vim sudo tzdata locales && locale-gen ja_JP.UTF-8 \
 && apt-get clean


# MariaDB repository setup
RUN curl -OL https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb
RUN apt-get install -y ./mysql-apt-config_0.8.24-1_all.deb
RUN apt-get -y update \
 && apt-get install -y mysql-server

VOLUME /var/lib/mysql

# JP対応
ENV TZ Asia/Tokyo
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja

