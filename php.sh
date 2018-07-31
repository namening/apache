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