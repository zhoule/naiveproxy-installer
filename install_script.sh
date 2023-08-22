#!/bin/bash

# 更新软件包列表并安装curl和wget
apt update -y
apt install -y curl wget

# 下载Go安装包
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz

# 解压Go安装包
tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz

# 将Go路径添加到.profile文件中
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile

# 使新的PATH变量生效
source ~/.profile

# 安装xcaddy
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# 构建caddy二进制文件
~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive

# 复制caddy到/usr/bin
cp caddy /usr/bin

# 创建Caddyfile
cat > Caddyfile << EOL
:443, bytemonster.cn 
tls xixi.zhou2016@gmail.com 
route {
  forward_proxy {
    basic_auth zhoule zhoule123*
    hide_ip
    hide_via
    probe_resistance
  }

  reverse_proxy  https://demo.cloudreve.org  { 
    header_up  Host  {upstream_hostport}
    header_up  X-Forwarded-Host  {host}
  }
}
EOL

# 提示用户手动编辑Caddyfile
echo "请使用您喜欢的文本编辑器手动编辑Caddyfile，然后启动Caddy服务。"
