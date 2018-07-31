一、安装httpd	
	#	cd /usr/local/src
	#	wget http://mirrors.cnnic.cn/apache/httpd/httpd-2.4.34.tar.gz
	#	wget http://mirrors.cnnic.cn/apache/apr/apr-1.6.3.tar.gz
	#	wget http://mirrors.cnnic.cn/apache/apr/apr-util-1.6.1.tar.gz
	#	yum install -y bzip2
	#	tar zxvf httpd-2.4.34.tar.gz
	#	tar zxvf apr-1.6.3.tar.gz
	#	tar zxvf apr-util-1.6.1.tar.gz
	其中apr、apr-util可以理解成一个通用的函数库，主要为上层应用提供支持。httpd依赖apr和apr-util的。
	#	cd /usr/local/src/apr-1.6.3
	#	./configure --prefix=/usr/local/apr
	#	make && make install
	#	cd /usr/local/src/apr-util-1.6.1
	# 	./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr
	#	yum install -y expat-devel
	#	make && make install
	#	cd /usr/local/src/httpd-2.4.34
	#	./configure \
	--prefix=/usr/local/apache2.4 \
	--with-apr=/usr/local/apr \
	--with-apr-util=/usr/local/apr-util \
	--enable-so \
	--enable-mods-shared=most
	这里，--prefix指定安装目录，--enable-so表示启用DSO。DSO的意思是，把某些功能以模块（一个功能模块就是一个so文件，这些文件在编译完httpd后会看到）的形式展现出来。enable-mods-shared=most表示以共享的方式安装大多数功能模块，安装后会在modules目录下面看到这些文件。
	# 	yum install -y pcre pcre-devel
	报错
	collect2:error:ld returned 1 exit status 
	make[2]:***[htpasswd]错误1
	解决办法
	#	cd /usr/local/src
	#	cp -r apr-1.6.3 /usr/local/src/httpd-2.4.29/srclib/apr
	#	cp -r apr-util-1.6.1 /usr/local/src/httpd-2.4.29/srclib/apr-util
	#	cd /usr/local/src/httpd-2.4.29
	最后编译和安装
	#	make
	#	make install
	#	ls /usr/local/apache2.4/	
	#	ls /usr/local/apache2.4/modules/	//下面有很多绿色的.so文件，这些就是上面说的模块，之所以会有这么多，就是因为定义了most参数
	这些模块并不会全部加载，如果你想使用哪个模块，在配置文件里面配置即可。查看加载了哪些模块，使用命令：
	#	/usr/local/apache2.4/bin/apachectl -M
	这些带有shared字样的，表示该模块为动态共享模块；当然还有static字样的，它表示以静态的形式存在。动态和静态的区别在于，静态模块直接和主程序（/usr/local/apache2.4/bin/httpd)绑定在一起，我们看不到，而动态的模块都是一个个独立存在的文件（modules目录下面的.so文件即是）
	
	启动httpd之前需要先检验配置文件是否正确，如下所示：
	#	/usr/local/apache2.4/bin/apachectl -t
	#	/usr/local/apache2.4/bin/apachectl start
	查看是否启动命令如下：
	#	netstat -lnp|grep httpd
	
二、httpd配置
1、默认虚拟主机
	#	vim /usr/local/apache2.4/conf/httpd.conf/httpd
	//搜索关键词httpd-vhost，找到这行把行首的井号删除
	#	vim /usr/local/apache2.4/conf/extra/httpd-vhosts.conf
	//这个配置文件就是虚拟主机配置文件了
	该文件最后面的两段（以<VirtualHost>开头，以</VirtualHost>结尾），这样一段就是一个虚拟主机，在这里面可以定义网站的域名和对应的网站程序所在目录。
	默认虚拟主机就是第一个配置段，该配置文件里面的两段</VirtualHost>重新编辑如下：
<VirtualHost *:80>
    ServerAdmin admin@aminglinux.com
    DocumentRoot "/data/wwwroot/aming.com"
    ServerName aming.com
    ServerAlias www.aming.com
    ErrorLog "logs/aming.com-error_log"
    CustomLog "logs/aming.com-access_log" common
</VirtualHost>

<VirtualHost *:80>
    DocumentRoot "/data/wwwroot/www.123.com"
    ServerName www.123.com
</VirtualHost>
	ServerAdmin指定管理员邮箱，没有实质作用。DocumentRoot为该虚拟主机站点根目录，网站的程序就放在这个目录下面。ServerName为网站的域名，ServerAlias为网站的第二域名，ServerAlias后面的域名可以写多个，用空格分隔，但ServerName后面的域名不支持写多个。ErrorLog为站点的错误日志，CustomLog为站点的访问日志。
	假如在虚拟主机配置文件中，我们只定义了两个站点--aming.com和123.com，那么当把第三个域名abc.com指向本机的时候，当在浏览器访问abc.com是，会去访问aming.com，也就是默认虚拟主机。
	#	mkdir -p /data/wwwroot/aming /data/wwwroot/www.123.com
	#	echo "aming.com" > /data/wwwroot/aming.com/index.html
	#	echo "123.com" > /data/wwwroot/123.com/index.html
	#	/usr/local/apache2.4/bin/apachectl -t
	#	/usr/local/apache2.4/bin/apachectl graceful
	#	curl -x127.0.0.1:80 aming.com
	aming.com
	#	curl -x127.0.0.1:80 www.123.com
	123.com
	#	curl -x127.0.0.1:80 www.abc.com
	aming.com
2、用户认证
	这个功能就是在用户访问网站的时候，需要输入用户名密码才能顺利访问。先对123.com站点做一个全站的用户认证：
	#	vim /usr/local/apache2.4/conf/extra/httpd-vhosts.conf
	//把123.com那个虚拟主机编辑如下内容
<VirtualHost *:80>
	DocumentRoot "/data/wwwroot/www.123.com"
	ServerName www.123.com
	<Directory /data/wwwroot/www.123.com>	//指定认证的目录
	AllowOverride AuthConfig				//这个相当于打开认证的开关
	AuthName "123.com user auth"			//自定义认证的名字，作用不大
	AuthType Basic							//认证的类型，一般为Basic
	AuthUserFile /data/.htpasswd			//指定密码文件所在位置
	require valid-user						//指定需要认证的用户为全部可用用户
	</Directory>
</VirtualHost>
	创建密码文件，操作步骤如下：
	#	/usr/local/apache2.4/bin/htpasswd -cm /data/.htpasswd aming
	//htpasswd命令为创建用户的工具，-c为create（创建），-m指定密码加密方式为MD5，
	/data/.htpasswd为密码文件，aming为要创建的用户。第一次执行该命令需要加-c，第二次再创建新的用户时，就不用加-c了，否则/data/.htpasswd文件会被重置，之前的用户被清空
	配置完成后，需要宿主机（真实电脑windows）上去修改hosts文件。保存hosts文件后，就可以用windows的浏览器去访问www.123.com了。
	其实也可以针对某个目录或者某个文件进行认证，比如要对www.123.com/admin/目录进行认证，只需要把<Directory /data/wwwroot/www.123.com>改为<Directory /data/wwwroot/www.123.com/admin/>。如果是一个文件，比如www.123.com/admin.php,则需要修改如下：
	<VirtualHost *:80>
		DocumentRoot "/data/wwwroot/www.123.com"
		ServerName www.123.com
		<FilesMatch admin.php>
		AllowOverride AuthConfig
		AuthType Basic
		AuthName "123.com user auth"
		AuthUserFile /data/.htpasswd
		require valid-user
		</FilesMatch>
	</VirtualHost>
	但是网址中带有admin.php的链接都会弹出认证窗口
3、配置域名跳转
	实现123.com域名跳转到www.123.com，配置如下：
	<VirtualHost *:80>
		DocumentRoot "/data/wwwroot/www.123.com"
		ServerName www.123.com
		ServerAlias 123.com
		<IfModule mod_rewrite.c>					//需要mod_rewrite模块支持
			RewriteEngine on						//打开rewrite功能
			RewriteCond %{HTTP_HOST} !^www.123.com$
			//定义rewrite的条件，当主机名（域名）不是www.123.com时满足条件
			RewriteRule ^/(.*)$ http://www.123.com/$1 [R=301,L]
			//定义rewrite规则，当满足上面的条件时，这条规则才会执行
		</IfModule>
	</VirtualHost>
	在RewriteRule里是有正则表达式存在的。
	RewriteRule后面由空格分成三部分，第一部分为当前的URL，不过这个URL是不把主机头算在内的。第二部分为要跳转的目标地址，这个地址可以写全（包含了主机头），当然也可以不加主机头，默认就是前面定义的ServerName。第三部分为一些选项，需要用方括号括起来，301为状态码，它称作”永久重定向“（302为临时重定向），L表示“last”，意思是跳转一次就结束了。要实现域名跳转，需要rewrite模块支持，所以先查看httpd是否已经加载该模块，如果没有还需要配置：
	#	/usr/local/apache2.4/bin/apachectl -M|grep -i rewrite
	//如果没有任何输出，则需要编辑配置文件
	#	vim /usr/local/apache2.4/conf/httpd.conf //搜索rewrite，找到那行把前面的#删除
	#	/usr/local/apache2.4/bin/apachectl graceful
	#	/usr/local/apache2.4/bin/apachectl -M|grep -i rewrite
	rewrite_module (shared) //有这一行输出，说明正常加载rewrite模块
4、配置访问日志
	打开主配置文件
	#	vim /usr/local/apache2.4/conf/httpd.conf	//搜索LogFormat
	LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
	LogFormat "%h %l %u %t \"%r\" %>s %b" common
	可以看到2个格式的日志，建议使用第一个。%h为访问网站的IP;%l为远程登录名，这个字段基本尚未"-";%u为用户名，当使用用户认证时，这个字段为认证的用户名；%t为时间；%r为请求的动作（比如用curl -I时就为HEADE);%s为请求的状态码，写成%>s为最后的状态码；%b为传输数据大小;%{Referer}i为referer信息（请求本次地址上一次的地址就为referer,比如在百度中搜索阿铭linux，然后通过百度访问到阿铭的论坛，那访问阿铭论坛的这次请求的referer就是百度）；%{User-Agent}i为浏览器表示。
	然后继续编辑虚拟主机配置文件：
	#	vim /usr/local/apache2.4/conf/extra/httpd-vhosts.conf	//把123.com虚拟主机改写如下
	<VirtualHost *:80>
		DocumentRoot "/data/wwwroot/www.123.com"
		ServerName www.123.com
		ServerAlias 123.com
		<IfModule mod_rewrite.c>
			RewriteEngine on
			RewriteCond %{HTTP_HOST} !^www.123.com$
			RewriteRule ^/(.*)$ http://www.123.com/$1 [R=301,L]
		</IfModule>
		CustomLog "logs/123.com-access_log" combined
	</virtualHost>
	保存配置文件后，测试语法并重新加载配置：
	#	/usr/local/apache2.4/bin/apachectl -t
	#	/usr/local/apache2.4/bin/apachectl graceful
	#	curl -x127.0.0.1:80 -I 123.com //再次curl
	#	tail /usr/local/apache2.4/logs/123.com-access_log
	发现生成了日志，并且有相关的日志记录。另外，用Firefox浏览器访问一下，再次查看日志，多了一行。
	图片、js、css等静态的文件非常多，可以限制这些静态元素去记录日志，并且需要把日志按天归档，一天一个日志。配置如下：
	#	vim /usr/local/apache2.4/conf/extra/httpd-vhosts.conf	//把123.com虚拟主机改为
	<VirtualHost *:80>
		DocumentRoot "/data/wwwroot/www.123.com"
		ServerName www.123.com
		ServerAlias 123.com
		<IfModule mod_rewrite.c>
			RewriteEngine on
			RewriteCond %{HTTP_HOST} !^www.123.com$
			RewriteRule ^/(.*)$http://www.123.com/$1 [R=301,L]
		</IfModule>
		SetEnvIf Request_URI ".*\.gif$" image-request
		SetEnvIf Request_URI ".*\.jpg$" image-request
		SetEnvIf Request_URI ".*\.png$" image-request
		SetEnvIf Request_URI ".*\.bmp$" image-request
		SetEnvIf Request_URI ".*\.swf$" image-request
		SetEnvIf Request_URI ".*\.js$" image-request
		SetEnvIf Request_URI ".*\.css$" image-request
		CustomLog "|/usr/local/apache2.4/bin/rotatelogs -l logs/123.com-access_%Y%m%d.log 86400"
	combined env=!image-request
	</VirtualHost>
	先定义了一个image-request环境变量，把gif、jpg、png、bmp、swf、js、css等格式的文件全部贵类到image-request里，后面的env=!image-request有用到一个"!",这相当域取反了，意思是把image-request以外的类型文件记录到日志里。
	正常应该CustomLog后面为日志文件名，但在这里阿铭用了一个管道，它会把日志内容交给后面的rotatelogs命令处理。这个rotetelogs为httpd自带切割日志的工具，它会把访问日志按我们定义的文件名格式进行切割，其中86400单位是“秒”，相当于”一天“。
	#	/usr/local/apache2.4/bin/apachectl -t
	#	/usr/local/apache2.4/bin/apachectl graceful
	#	curl -x127.0.0.1:80 -I 123.com
	#	ls /usr/local/apache2.4/logs/123
5、配置静态元素过期时间
	状态码304表示该文件已经缓存到用户的电脑里了。
	#	vim /usr/local/apache2.4/conf/extra/httpd-vhosts.conf	// 把123.com虚拟主机改为
	<VirtualHost *:80>
		DocumentRoot "/data/wwwroot/www.123.com"
		ServerName www.123.com
		ServerAlias 123.com
		<IfModule mod_rewrite.c>
			RewriteEngine on
			RewriteCond %{HTTP_HOST} !^www.123.com$
			RewriteRule ^/(.*)$http://www.123.com/$1 [R=301,L]
		</IfModule>
		SetEnvIf Request_URI ".*\.gif$" image-request
		SetEnvIf Request_URI ".*\.jpg$" image-request
		SetEnvIf Request_URI ".*\.png$" image-request
		SetEnvIf Request_URI ".*\.bmp$" image-request
		SetEnvIf Request_URI ".*\.swf$" image-request
		SetEnvIf Request_URI ".*\.js$" image-request
		SetEnvIf Request_URI ".*\.css$" image-request
		CustomLog "|/usr/local/apache2.4/bin/rotatelogs -l logs/123.com-access_%Y%m%d.log 86400"
			combined env=!image-request
		<IfModule mod_expires.c>
			ExpiresActive on	//打开该功能的开关
			ExpiresByType image/gif "access plus 1 days"
			ExpiresByType image/jpeg "access plus 24 hours"
			ExpiresByType image/png "access plus 24 hours"
			ExpiresByType text/css "now plus 2 hour"
			ExpiresByType application/x-javascript "now plus 2 hours"
			ExpiresByType application/javascript "now plus 2 hours"
			ExpiresByType application/x-shockwave-flash "now plus 2 hours"
			ExpiresDefault "now plus 0 min"
		</IfModule>
	</VirtualHost>
	这里gif、jpeg、png格式的文件过期时长为1天，css、js、flash格式的文件过期时长为2小时，其他文件过期时长为0，也就是不缓存。
	#	/usr/local/apache2.4/bin/apachectl -tail
	#	/usr/local/apache2.4/bin/apachectl graceful
	检查httpd是否加载expires模块：
	#	/usr/local/apache2.4/bin/apachectl -M|grep -i expires
	//没有任何输出，说明当前httpd并不支持expires模块，所以需要修改配置文件，打开该模块
	#	vim /usr/local/apache2.4/conf/httpd.conf	//搜索expires关键词
	#LoadModule expires_module modules/mod_expires.so
	//把本行最前面的#删除
	#	/usr/local/apache2.4/bin/apachectl graceful 
	#	/usr/local/apache2.4/bin/apachectl -M|grep -i expires
	expires_module (shared) //有这行输出，说明已经正确加载expires模块
6、配置防盗链
	#	vim /usr/local/apache2.4/conf/extra/httpd-vhosts.conf	//编辑虚拟主机配置文件
	<VirtualHost *:80>
		DocumentRoot "/data/wwwroot/www.123.com"
		ServerName www.123.com
		ServerAlias 123.com
		CustomLog "|/usr/local/apache2.4/bin/rotatelogs -l logs/123.com-access_%Y%m%d.log 86400"
	combined
		<Directory /data/wwwroot/www.123.com>
			SetEnvIfNoCase Referer "http://www.123.com" local_ref
			SetEnvIfNoCase Referer "http://123.com" local_ref
			SetEnvIfNoCase Referer "^$" local_ref
			<filesmatch "\.(txt|doc|mp3|zip|rar|jpg|gif)">
				Order Allow,Deny
				Allow from env=local_ref
			</filesmatch>
		</Directory>
	</VirtualHost>
	首先定义允许访问链接的referer，其中^$为空referer，当直接在浏览器里输入图片地址去访问它时，它的referer就为空。然后又使用filesmatch来定义需要保护的文件类型，访问txt、doc、MP3、zip、rar、jpg、gif格式的文件，当访问这样类型的文件时就会被限制。
7、访问控制
	#	vim /usr/local/apache2.4/conf/extra/httpd-vhosts.conf	//改成如下内容
	<VirtualHost *:80>
		DocumentRoot "/data/wwwroot/www.123.com"
		ServerName www.123.com
		ServerAlias 123.com
		CustomLog "|/usr/local/apache2.4/bin/rotatelogs -l logs/123.com-access_%Y%m%d.log 86400" combined
		<Directory /data/wwwroot/www.123.com/admin/>
			Order deny,allow
			Deny from allow
			Allow from 127.0.0.1
		</Directory>
	</VirtualHost>
	
