# naiveproxy-installer

### 1. Install Go
```
apt update -y && apt install -y curl && apt install -y wget

wget https://go.dev/dl/go1.19.3.linux-amd64.tar.gz

tar -C /usr/local -xzf go1.19.3.linux-amd64.tar.gz
```

### 2. Config go environment
```
vi ~/.profile

export PATH=$PATH:/usr/local/go/bin

. ~/.profile
```

### 3. Install caddy
```
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive

cp caddy /usr/bin
```

### 4. Create Caddyfile
```
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
```

### 5. caddy常用指令：

前台运行caddy：./caddy run

后台运行caddy：./caddy start

停止caddy：./caddy stop

重载配置：./caddy reload
