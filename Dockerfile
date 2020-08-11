FROM centos:6.10

COPY cactiez-x86_64.tgz /tmp/

COPY Dockerfile /root/

RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup \
 && curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo \
 && yum -y update \
 && yum -y install net-snmp-utils net-snmp httpd php mysql-server php-mysql php-gd ntp rsyslog-mysql pango cronie \
 && yum clean all
	
RUN cd /tmp/ \
 && tar zxf cactiez-x86_64.tgz \
 && /bin/cp -rf /tmp/var/www/html/* /var/www/html \
 && /bin/cp -rf /tmp/usr/* /usr \
 && /bin/cp -rf /tmp/etc/* /etc \
 && chmod -R 777 /var/www/html/log/ \
 && chmod -R 7755 /var/www/html/rra/ \
 && chmod -R 755 /var/www/html/scripts/ \
 && chmod -R 755 /usr/local/spine/bin/ \
 && chmod -R 755 /usr/local/rrdtool/bin/ \
 && chown -R apache:apache /var/www/html/ \
 && echo '*/10 * * * * /usr/sbin/ntpdate ntp.aliyun.com && /sbin/clock -w' > /tmp/crontab2.tmp \
 && echo '*/5 * * * * php /var/www/html/poller.php > /dev/null 2>&1' >> /tmp/crontab2.tmp \
 && crontab /tmp/crontab2.tmp \
 && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
 && echo -e '/usr/sbin/ntpdate ntp.aliyun.com && /sbin/clock -w\n/etc/init.d/mysqld start\n/etc/init.d/snmpd start\n/etc/init.d/crond start\n/usr/sbin/httpd -D FOREGROUND' > /usr/bin/cacti-start \
 && chmod +x /usr/bin/cacti-start \
 && rm -rf /tmp/*
	
RUN service mysqld start \
 && /usr/bin/mysqladmin --user=root create cacti \
 && mysql -e "GRANT ALL ON cacti.* TO cactiuser@localhost IDENTIFIED BY 'cactiuser'" \
 && mysql cacti < /var/www/html/cactiez.sql
	
EXPOSE 80

ENTRYPOINT ["/bin/bash", "/usr/bin/cacti-start"]