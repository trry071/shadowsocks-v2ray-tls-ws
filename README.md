# shadowsocks-libev 一键安装脚本
shadowsocks-libev+v2ray+websocket+tls

每次安装 ss 都要照着它的 github 文档一个个的敲命令，我觉得这样很麻烦，于是就花了点时间写了这个脚本。此脚本对小白并不是很友好。

## 功能
自动安装配置 nginx、ssl证书、shadowsocks-libev、v2ray-plugin

## 准备
一台国外的vps（系统要求：centos 7）  
一个域名，并将其解析到主机上  

## 使用
编辑 go.sh 将 main 函数中的 domain 改成你的域名，以及 ss 的一些配置，保存运行，运行完毕后再重启系统就全部配置好了。