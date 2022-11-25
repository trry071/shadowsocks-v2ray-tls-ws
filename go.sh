init(){
	#删除之前的文件
	rm -rf libsodium-1.0.16 shadowsocks-libev mbedtls-mbedtls-2.6.0
	yum remove nginx -y
	yum install epel-release gcc pcre-devel libsodium-devel mbedtls-devel gettext autoconf libtool automake make asciidoc xmlto c-ares-devel libev-devel git -y
}

installation_nginx(){
	rpm -Uvh  http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
	yum install nginx -y
	
	#启动nginx服务
	systemctl start nginx
	
	#将服务设置为开机启动
	systemctl enable nginx.service
	
	#开启443端口
	firewall-cmd --zone=public --add-port=443/tcp --permanent

	#开启80端口
	firewall-cmd --zone=public --add-port=80/tcp --permanent
	
	#重启防火墙
	systemctl restart firewalld.service
	
	#写出配置
	installation_nginx_conf1 $1
}

installation_libsodium(){
	# installation of libsodium
	libsodium_ver=1.0.16
	wget https://download.libsodium.org/libsodium/releases/old/libsodium-$libsodium_ver.tar.gz
	tar xvf libsodium-$libsodium_ver.tar.gz
	rm -rf libsodium-$libsodium_ver.tar.gz
	pushd libsodium-$libsodium_ver
	./configure --prefix=/usr && make
	make install
	popd
	ldconfig
}

installation_mbedtls(){
	# installation of mbedtls
	mbedtls_ver=2.6.0
	wget https://github.com/mbed-tls/mbedtls/archive/refs/tags/mbedtls-$mbedtls_ver.tar.gz
	tar xvf mbedtls-$mbedtls_ver.tar.gz
	rm -rf mbedtls-$mbedtls_ver.tar.gz
	pushd mbedtls-mbedtls-$mbedtls_ver
	make shared=1 cflags="-o2 -fpic"
	make destdir=/usr install
	popd
	ldconfig
}

installation_shadowsocks_libev(){
	git clone https://github.com/CItext/shadowsocks-libev
	pushd shadowsocks-libev
	git submodule update --init --recursive
	./autogen.sh && ./configure && make
	make install
	popd
}

installation_v2ray_plugin(){
	wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
	tar xvf v2ray-plugin-linux-amd64-v1.3.2.tar.gz
	rm -rf v2ray-plugin-linux-amd64-v1.3.2.tar.gz
	mv v2ray-plugin_linux_amd64 shadowsocks-libev/src/
}

installation_nginx_conf1(){

#nignx 配置
	conf="
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
	worker_connections  1024;
}

http{

	include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
                      '\$status \$body_bytes_sent \"\$http_referer\" '
                      '\"\$http_user_agent\" \"\$http_x_forwarded_for\"';
    access_log  /var/log/nginx/access.log  main;

	server {
		listen       80;
		server_name  $1;

		location / {
			root   /usr/share/nginx/html;
			index  index.html index.htm;
		}
	}
}
"
	#写出配置
	echo "$conf">/etc/nginx/nginx.conf
	
	systemctl restart nginx
}

installation_nginx_conf2(){

#nignx 配置
	conf="
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
	worker_connections  1024;
}

http{

	include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
                      '\$status \$body_bytes_sent \"\$http_referer\" '
                      '\"\$http_user_agent\" \"\$http_x_forwarded_for\"';
    access_log  /var/log/nginx/access.log  main;

	server {
		listen       80;
		server_name  $1;

		location / {
			root   /usr/share/nginx/html;
			index  index.html index.htm;
		}
	}
	
	server {
		listen 443 ssl;
		server_name  $1;
		ssl_certificate /etc/nginx/cert/${1//./_}_cert.pem;
		ssl_certificate_key /etc/nginx/cert/${1//./_}_key.pem;
		ssl_session_timeout 5m;
		ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
		ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
		ssl_prefer_server_ciphers on;
	   

       location / {
			proxy_pass https://127.0.0.1:4431;
			proxy_redirect      off;
			proxy_http_version  1.1;
			proxy_set_header    Host \$http_host;
			proxy_set_header    Upgrade \$http_upgrade;
			proxy_set_header    Connection \"upgrade\";
		}
		
    }
}
"
	#写出配置
	echo "$conf">/etc/nginx/nginx.conf
	
	systemctl restart nginx
}

#添加开机启动
add_boot_up(){
	config="
[Unit]
Description=$1
After=network.target
[Service]
Type=simple
ExecStart=$2
PrivateTmp=true
[Install]
WantedBy=multi-user.target"

echo "$config">/lib/systemd/system/$1.service

systemctl enable $1.service

}


main(){
	#设置域名，请提前将域名解析到本服务器
	domain="a.example.com"

	#进入local目录
	cd /usr/local

	#初始化软件环境
	init
	
	#安装nginx
	installation_nginx $domain
	
	#安装libsodium
	installation_libsodium

	#安装mbedtls
	installation_mbedtls
	
	#安装shadowsocks-libev
	installation_shadowsocks_libev
	
	#安装v2ray-plugin
	installation_v2ray_plugin

	#进入ss-server所在目录
	pushd shadowsocks-libev/src/
	

	#ss配置
	config='{
		"server":["[::0]","0.0.0.0"],
		"server_port":4431,
		"password":"fuckkillgfw",
		"method":"aes-256-gcm",
		"plugin":"/usr/local/shadowsocks-libev/src/v2ray-plugin_linux_amd64",
		"plugin_opts":"server;tls;host='"$domain"';"
	}'

	#写出ss配置到当前目录
	echo $config>config.json
	popd

	#为域名申请证书的一些操作
	curl https://get.acme.sh | sh -s email=my@example.com
	
	#生成证书
	~/.acme.sh/acme.sh --issue -d $domain --nginx
	
	#创建证书目录
	mkdir /etc/nginx/cert
	
	#安装证书
	~/.acme.sh/acme.sh --install-cert -d $domain \
	--key-file       /etc/nginx/cert/${domain//./_}_key.pem  \
	--fullchain-file /etc/nginx/cert/${domain//./_}_cert.pem \
	--reloadcmd     "systemctl restart nginx"
	
	#判断证书是否生成成功
	if [ -f /etc/nginx/cert/${domain//./_}_cert.pem ]
	then
	#再次配置nginx，配置https
	installation_nginx_conf2 $domain
	cd /usr/local/shadowsocks-libev/src
	
	#给ss添加开机启动
	add_boot_up "ss-server" "/usr/local/shadowsocks-libev/src/ss-server -c /usr/local/shadowsocks-libev/src/config.json"
	
	#关闭selinux
	sed -i 's/^ *SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	
	echo "Installation ok pleace peboot!"
	else
	echo "Installation cert Fail!"
	fi
}

main