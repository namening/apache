一、配置httpd支持PHP
	#	cd /usr/local/src
	#	wget http://cn2.php.net/distributions/php-5.6.32.tar.bz2
	# 	tar zxf php-5.6.32.tar.bz2
	#	cd php-5.6.32
	#	./configure \
	--prefix=/usr/local/php \
	--with-apxs2=/usr/local/apache2.4/bin/apxs \
	--with-config-file-path=/usr/local/php/etc \
	--with-mysql=/usr/local/mysql \
	--with-libxml-dir \
	--with-gd \
	--with-jpeg-dir \
	--with-png-dir \
	--with-freetype-dir \
	--with-iconv-dir \
	--with-zlib-dir \
	--with-bz2 \
	--with-openssl \
	--with-mcrypt \
	--enable-soap \
	--enable-gd-native-ttf \
	--enable-mbstring \
	--enable-sockets \
	--enable-exif
	配置编译报错，
	#	yum install -y libxml2-devel
	#	yum install -y openssl openssl-devel
	#	yum install -y bzip2 bzip2-devel
	#	yum install -y libpng libpng-devel
	#	yum install -y freetype freetype-devel
	#	yum install -y epel-release
	# 	yum install -y libmcrypt-devel
	# 	yum install -y libjpeg-devel
	#	cp php.ini-production /usr/local/php/etc/php.ini-production
	配置httpd支持PHP
	#	vim /usr/local/apache2.4/conf/httpd.conf/httpd
	搜索ServerName，把#ServerName www.example.com:80前面的井号删除。找到如下内容：
	<Directory />
		AllowOverride none
		Require all denied
	</Directory>
	改成如下：
	<Directory />
		AllowOverride none
		Require all granted
	</Directory>
	修改他的目的是，允许所有请求，如果不设置该行，则我们访问的时候会报403错误。再搜索下面这一行：
	AddType application/x-gzip .gz .tgz
	在该行下面添加一行：
	AddType application/x-httpd-php .php
	接着找到下面这一段：
	<IfModule dir_module>
		DirectoryIndex index.html
	</IfModule>
	改为
	<IfModule dir_module>
		DirectoryIndex index.html index.php
	</IfModule>

二、PHP配置
	查看PHP配置文件所在的命令为：
	#	/usr/local/php/bin/php -i|grep -i "loaded configuration file"
	php.ini为PHP的配置文件，可以看出其在/usr/local/php/etc/php.ini，这一行的Warning为警告信息，可以忽略，取消这个警告需要编辑php.ini，找到date.timezone设置如下：
	date.timezone = Asia/Shanghai
	再次执行不再提示警告信息。
1、PHP的disable_functions
	PHP有诸多内置的函数，有一些函数（比如exec）会直接调去linux系统命令，如果开放将会非常危险。因此，基于安全考虑应该把一些存在安全风险的函数禁掉：
	#	vim /usr/local/php/etc/php.ini-production
	disable_function = eval,assert,popen,passthru,escapeshellarg,escapeshellcmd,passthru,exec,system,chroot,scandir,chgrp,chown,escapeshellcmd,escapeshellarg,shell_exec,proc_get_status,ini_alter,ini_restore,dl,pfsockopen,openlog,syslog,readlink,symlink,leak,popepassthru,stream_socket_server,popen,proc_open,proc_close
	更改完php.ini后，由于需要在httpd中调用PHP,所以还需要重启httpd服务使其生效。
2、配置error_log
	#	vim /usr/local/php/etc/php.ini
	//搜索log_errors,改成如下
	log_errors = On
	//再搜索error_log,改为
	error_log = /var/log/php/php_errors.log
	//再搜索error_reporting,改为
	error_reporting = E_ALL & ~E_NOTICE
	//再搜索display_errors,改为
	display_errors = off
	log_errors可以设置为on或者off，或者想让PHP记录错误日志，需要设置为on。error_log设定错误日志路径；error_reporting设定错误日志的级别，E_ALL为所有类型的日志。在开发环境设置为E_ALL,可以方便程序员排查问题，但也会造成日志记录很多无意义的内容。&符号表示并且，~表示排除，所以两个组合在一起就是在E_ALL的基础上排除掉notice相关的日志。display_errors设置为on，则会把错误日志直接显示在浏览器里，这样对于用户访问来说体验不好，而且还会暴露网站的一些文件路径等重要信息，所以要设置为off。设置完php.ini,还需做一些额外的操作：
	#	mkdir /var/log/php
	#	chmod 777 /var/log/php	// 需要保证PHP的错误日志所在目录存在，并且权限为可写
	#	/usr/local/apache2.4/bin/apachectl graceful
3、配置open_basedir
	PHP有一个概念叫作open_basedir,它的作用就是将网站限定在指定目录里。如果你的服务器只有一个站点，那可以直接在php.ini中设置open_basedir参数。但如果服务器上跑的站点比较多，那么在php.ini中设置就不合适了，因为在php.ini中只能定义一次，也就是说所有重难点都一起定义限定的目录，那这样似乎起不到隔离多个站点的目录。先来看如何在php.ini中设置open_basedir:
	#	vim /usr/local/php/etc/php.ini	//搜索open_basedir，改成如下
	open_basedir = /tmp:/data/wwwroot/www.123.com
	open_basedir可以是多个目录，用:分隔
	单个虚拟主机设置open_basedir。对于php.ini里面的配置，在httpd.conf中也是可以设置的：
	#	vim /usr/local/apache2.4/conf/extra/httpd-vhosts.conf	//编辑如下
	<VirtualHost *:80>
		DocumentRoot "/data/wwwroot/www.123.com"
		ServerName www.123.com
		ServerAlias 123.com
		CustomLog "|/usr/local/apache2.4/bin/rotatelogs -l logs/123.com-access_%Y%m%d.log 86400" combined
		php_admin_value open_basedir "/data/wwwroot/www.123.com/:/tmp/"
	<VirtualHost>
	起作用的就是这句php_admin_value,它可以定义php.ini里面的参数，除此之外像error_log之类的也可以定义。这样就可以实现，一个虚拟主机定义一个open_basedir。
4、PHP动态扩展模块安装
	编译httpd时，有涉及动态和静态模块，其实PHP也一样有这样的说法。本章讲PHP安装时，所有的模块全部都为静态，并没有任何动态的模块。所谓动态，就是独立存在的.so文件，在httpd中PHP就是以动态模块的形式被加载的。PHP一旦编译完成后，要想再增加一个功能模块的话，要么重新编译PHP，要么直接编译一个扩展模块（生成一个.so文件），然后在php.ini中配置一下，就可以被加载使用了。查看PHP加载了哪些功能模块：
	#	/usr/local/php/bin/php -m
	下面安装一个PHP的redis扩展模块：
	#	cd /usr/local/src/
	#	wget https://codeload.github.com/phpredis/phpredis/zip/develop （下载后改名phpredis-develop.zip）
	#	mv develop phpredis-develop.zip
	#	unzip !$	//	yum -y install unzip;unzip phpredis-develop.zip
	#	cd phpredis-develop/
	#	/usr/local/php/bin/phpize	//目的是生成configure文件
	//运行后可以看到上面有一个错误cannot find autoconf,这需要安装一些autoconf
	#	yum install -y autoconf
	#	/usr/local/php/bin/phpize	//再次执行不再提示警告信息。
	#	./configure --with-php-config=/usr/local/php/bin/php-config
	#	make
	#	make install
	//make install的时候会把编译好的redis.so放到这个目录下面，这个目录也是扩展模块存放目录
	#	/usr/local/php/bin/php -i|grep extension_dir	//查看扩展模块存放目录，我们可以在php.ini中自定义该路径
	#	ls	/usr/local/php/lib/php/extensions/no-debug-zts-20131226 //可以看到redis.so
	#	vim /usr/local/php/etc/php.ini	//增加一行配置（可以放到文件最后一行）
	extension = redis.so
	#	/usr/local/php/bin/php -m|grep redis	//查看是否加载了redis模块
	另外，要想在PHP网站使用redis模块，还需要重启一下httpd服务。