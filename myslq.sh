1、下载软件包
	x86_64字样的就是64位的包，带有i686字样的就是32位的包。
	查看linux是多少位的方法：
	#	uname -i
	x86_64
	下载源码包，如下所示：
	#	cd /usr/local/src/ //软件包存放位置
	#	wget http://mirrors.sohu.com/mysql/MySQL-5.6/mysql-5.6.36-linux-glibc2.5-x86_64.tar.gz
2、初始化
	#	tar zxf mysql-5.6.36-linux-glibc2.5-x86_64.tar.gz
	# 	[ -d /usr/local/mysql ] && mv /usr/local/mysql /usr/local/mysql_old
	# 	mv mysql-5.6.36-linux-glibc2.5-x86_64 /usr/local/mysql
	#	useradd -s /sbin/nologin mysql
	#	cd /usr/local/mysql
	# 	mkdir -p /data/mysql
	#	chown -R mysql:mysql /data/mysql
	#	./scripts/mysql_install_db --user=mysql --datadir=/data/mysql
	--user表示定义数据库以哪个用户的身份在运行，--datadir表示定义数据库的安装目录。如果最后一条命令报错，提示"FATAL ERROR:please install the following Perl modules before executing ./scripts/mysql_install_db:Data::Dumper"，这是因为缺少包perl-Module-Install，使用yum -y install perl-Module-Install安装它。
3、配置Mysql
	#	cp support-files/my-default.cnf /etc/my.cnf
	#	vim /etc/my.cnf
[mysqld]

# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
innodb_buffer_pool_size = 128M

# Remove leading # to turn on a very important data integrity option: logging
# changes to the binary log between backups.
log_bin = aminglinux

# These are commonly set, remove the # and set as required.
basedir = /usr/local/mysql
datadir = /data/mysql
port = 3306
server_id = 128
socket = /tmp/mysql.sock

# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
join_buffer_size = 128M
sort_buffer_size = 2M
read_rnd_buffer_size = 2M

sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
	
	其中，basedir是mysql包所在的路径，datadir是定义的存放数据的地方，默认情况下，错误日志也会记录在这个目录下面。port定义mysql服务监听的端口，如果不定义默认就是3306。server_id定义该mysql服务的ID号。socket定义mysql服务监听的套接字地址，在linux系统下面，很多服务不仅可以监听一个端口，也可以监听socket，两个进程就可以通过这个socket文件通信。
	复制启动脚本文件并修改其属性，如下所示：
	#	cp support-files/mysql.server /etc/init.d/mysqld
	#	chmod 755 /etc/init.d/mysqld
	修改启动脚本
	#	vim /etc/init.d/mysqld
	需要修改的地方有datadir=/data/mysql。把启动脚本加入系统服务项，设定开机启动mysql，
	#	chkconfig --add mysqld
	#	chkconfig mysqld on
	#	service mysqld start
	#	ps aux|grep mysqld
	#	netstat -lnp|grep 3306
	

