# NaiveProxy 一键安装脚本 (Docker Compose 版)

基于 Docker Compose 的 NaiveProxy 快速部署方案，使用 Caddy2 + ForwardProxy 插件。

## 特性

- ✅ 一键安装部署，无需手动编译
- ✅ 自动检测并安装 Docker 和 Docker Compose
- ✅ 支持多种 Linux 发行版（Ubuntu/Debian/CentOS/RHEL等）
- ✅ 基于 Docker，环境隔离，易于管理
- ✅ 自动申请和续期 SSL 证书
- ✅ 支持流量伪装（反向代理）
- ✅ 完整的代理功能（hide_ip, hide_via, probe_resistance）
- ✅ 自动检查端口占用和环境配置

## 环境要求

- Linux 系统（支持 Ubuntu/Debian/CentOS/RHEL/Rocky/AlmaLinux）
- Root 权限或 sudo 权限
- 一个已解析到服务器的域名
- 开放 443 端口

**注意：** 安装脚本会自动检测并安装 Docker 和 Docker Compose，无需手动安装

## 快速开始

### 方法一：使用一键安装脚本（推荐）

```bash
wget https://raw.githubusercontent.com/zhoule/naiveproxy-installer/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

安装脚本会自动完成：
- ✅ 检测操作系统类型
- ✅ 检测并安装 Docker（如果未安装）
- ✅ 检测并安装 Docker Compose（如果未安装）
- ✅ 检查端口占用情况
- ✅ 引导配置域名、邮箱、代理账户等信息
- ✅ 自动生成配置文件并启动服务

### 方法二：手动配置

1. **克隆仓库**

```bash
git clone https://github.com/zhoule/naiveproxy-installer.git
cd naiveproxy-installer
```

2. **配置环境变量**

```bash
cp .env.example .env
# 编辑 .env 文件，填入您的域名和邮箱
```

3. **编辑 Caddyfile**

编辑 `caddy/Caddyfile` 文件，修改以下内容：
- 将 `example.com` 改为您的域名
- 将 `your-email@example.com` 改为您的邮箱
- 将 `user password` 改为您的代理用户名和密码

4. **创建必要的目录**

```bash
mkdir -p caddy/caddy_data caddy/caddy_config
```

5. **启动服务**

```bash
docker-compose up -d
```

## 依赖自动安装

setup.sh 脚本会自动检测并安装所需依赖：

### 支持的操作系统

- Ubuntu 18.04+
- Debian 10+
- CentOS 7+
- RHEL 7+
- Rocky Linux 8+
- AlmaLinux 8+

### 自动安装的组件

1. **Docker** - 如果未安装，脚本会询问是否自动安装
2. **Docker Compose** - 自动安装最新版本
3. **基础工具** - curl, wget 等必要工具

### 手动安装 Docker（可选）

如果您希望手动安装 Docker：

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sh

# CentOS/RHEL
curl -fsSL https://get.docker.com | sh
```

## 域名解析

在启动服务之前，请确保您的域名已正确解析到服务器IP地址：

```
类型: A
主机记录: @ 或 www
记录值: 您的服务器IP
```

您可以使用以下命令查看服务器公网IP：
```bash
curl ifconfig.me
```

## Docker Compose 常用命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f caddy2

# 查看服务状态
docker-compose ps

# 更新镜像
docker-compose pull
docker-compose up -d
```

## 配置文件说明

### docker-compose.yml

定义了服务的配置，包括：
- 使用 `ericwang2006/caddy2` 镜像（已编译 ForwardProxy 插件）
- 使用 host 网络模式
- 挂载 Caddyfile 和数据目录

### caddy/Caddyfile

Caddy 的配置文件，包含：
- TLS 证书配置
- ForwardProxy 代理配置
- 反向代理伪装配置

## 客户端配置

配置完成后，您可以使用以下信息配置客户端：

```
协议: HTTPS
服务器: your-domain.com
端口: 443
用户名: [您设置的用户名]
密码: [您设置的密码]
```

推荐客户端：
- Windows/macOS/Linux: [Qv2ray](https://github.com/Qv2ray/Qv2ray) + NaiveProxy 插件
- Android: [SagerNet](https://github.com/SagerNet/SagerNet)

## 故障排查

### 1. Docker 安装失败

如果自动安装 Docker 失败，请手动安装：

```bash
# 使用官方脚本
curl -fsSL https://get.docker.com | sh

# 或访问官方文档
# https://docs.docker.com/engine/install/
```

### 2. 端口 443 被占用

检查占用 443 端口的进程：

```bash
# 使用 netstat
netstat -tlnp | grep 443

# 或使用 ss
ss -tlnp | grep 443

# 或使用 lsof
lsof -i:443
```

停止占用端口的服务后再运行安装脚本。

### 3. 查看容器日志

```bash
docker-compose logs -f caddy2
```

### 4. 检查容器状态

```bash
docker-compose ps
```

### 5. 检查域名解析

```bash
# 检查域名是否解析到正确的IP
nslookup your-domain.com

# 或使用 dig
dig your-domain.com
```

### 6. 测试证书申请

确保域名已正确解析，并且 80、443 端口可访问。

### 7. 防火墙配置

确保防火墙开放了 443 端口：

```bash
# Ubuntu/Debian (ufw)
ufw allow 443/tcp

# CentOS/RHEL (firewalld)
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

# iptables
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

### 8. 重新生成配置

```bash
docker-compose down
rm -rf caddy/caddy_data caddy/caddy_config
./setup.sh
```

## 安全建议

1. 使用强密码作为代理认证密码
2. 定期更新 Docker 镜像
3. 配置防火墙，仅开放必要端口
4. 定期备份配置文件

## 旧版安装方式

如果您需要使用传统的编译安装方式，请查看 `install_script.sh`：

```bash
wget https://raw.githubusercontent.com/zhoule/naiveproxy-installer/main/install_script.sh && chmod +x install_script.sh && ./install_script.sh
```

## 许可证

MIT License

## 相关链接

- [NaiveProxy](https://github.com/klzgrad/naiveproxy)
- [Caddy](https://caddyserver.com/)
- [ForwardProxy](https://github.com/caddyserver/forwardproxy)
