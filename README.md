# NaiveProxy 一键安装脚本 (Docker Compose 版)

基于 Docker Compose 的 NaiveProxy 快速部署方案，使用 Caddy2 + ForwardProxy 插件。

## 特性

- ✅ 一键安装部署，无需手动编译
- ✅ 基于 Docker，环境隔离，易于管理
- ✅ 自动申请和续期 SSL 证书
- ✅ 支持流量伪装（反向代理）
- ✅ 完整的代理功能（hide_ip, hide_via, probe_resistance）

## 环境要求

- Linux 系统
- 已安装 Docker 和 Docker Compose
- 一个已解析到服务器的域名
- 开放 443 端口

## 快速开始

### 方法一：使用一键安装脚本（推荐）

```bash
wget https://raw.githubusercontent.com/zhoule/naiveproxy-installer/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

安装脚本会引导您完成以下配置：
- 域名设置
- 邮箱设置（用于 SSL 证书）
- 代理用户名和密码
- 反向代理目标地址

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

## 域名解析

在启动服务之前，请确保您的域名已正确解析到服务器IP地址：

```
类型: A
主机记录: @ 或 www
记录值: 您的服务器IP
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

### 1. 查看容器日志

```bash
docker-compose logs -f caddy2
```

### 2. 检查容器状态

```bash
docker-compose ps
```

### 3. 检查端口是否监听

```bash
netstat -tlnp | grep 443
```

### 4. 测试证书申请

确保域名已正确解析，并且 80、443 端口可访问。

### 5. 重新生成配置

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
