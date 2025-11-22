#!/bin/bash

# NaiveProxy Docker-Compose 安装脚本
# 用于快速部署基于 Caddy2 的 NaiveProxy 服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}NaiveProxy Docker-Compose 安装向导${NC}"
echo -e "${GREEN}==================================${NC}"
echo

# 检查是否安装了 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    echo "请先安装 Docker: https://docs.docker.com/engine/install/"
    exit 1
fi

# 检查是否安装了 Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}错误: Docker Compose 未安装${NC}"
    echo "请先安装 Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# 创建必要的目录
echo -e "${YELLOW}创建必要的目录...${NC}"
mkdir -p caddy/caddy_data caddy/caddy_config

# 获取用户配置
echo
echo -e "${YELLOW}请输入配置信息:${NC}"
echo

read -p "请输入您的域名 (例如: example.com): " DOMAIN
read -p "请输入您的邮箱 (用于 SSL 证书): " EMAIL
read -p "请输入代理用户名: " USERNAME
read -sp "请输入代理密码: " PASSWORD
echo
read -p "请输入反向代理目标 (默认: https://demo.cloudreve.org): " REVERSE_PROXY
REVERSE_PROXY=${REVERSE_PROXY:-https://demo.cloudreve.org}

# 创建 .env 文件
echo -e "${YELLOW}创建环境变量文件...${NC}"
cat > .env << EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF

# 更新 Caddyfile
echo -e "${YELLOW}生成 Caddyfile 配置...${NC}"
cat > caddy/Caddyfile << EOF
:443, $DOMAIN
tls $EMAIL

route {
  forward_proxy {
    basic_auth $USERNAME $PASSWORD
    hide_ip
    hide_via
    probe_resistance
  }

  reverse_proxy $REVERSE_PROXY {
    header_up Host {upstream_hostport}
    header_up X-Forwarded-Host {host}
  }
}
EOF

echo
echo -e "${GREEN}配置完成!${NC}"
echo
echo -e "${YELLOW}重要提示:${NC}"
echo -e "1. 请确保域名 ${GREEN}$DOMAIN${NC} 已解析到本服务器的IP地址"
echo -e "2. 请确保防火墙开放了 ${GREEN}443${NC} 端口"
echo
read -p "是否现在启动服务? (y/n): " START_NOW

if [[ $START_NOW =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}启动服务...${NC}"

    # 尝试使用 docker compose 或 docker-compose
    if docker compose version &> /dev/null; then
        docker compose up -d
    else
        docker-compose up -d
    fi

    echo
    echo -e "${GREEN}服务启动成功!${NC}"
    echo
    echo -e "${YELLOW}NaiveProxy 配置信息:${NC}"
    echo -e "协议: ${GREEN}https${NC}"
    echo -e "地址: ${GREEN}$DOMAIN${NC}"
    echo -e "端口: ${GREEN}443${NC}"
    echo -e "用户名: ${GREEN}$USERNAME${NC}"
    echo -e "密码: ${GREEN}$PASSWORD${NC}"
    echo
    echo -e "${YELLOW}常用命令:${NC}"
    echo "查看日志: docker-compose logs -f caddy2"
    echo "停止服务: docker-compose down"
    echo "重启服务: docker-compose restart"
    echo "更新配置: 编辑 caddy/Caddyfile 后执行 docker-compose restart"
else
    echo
    echo -e "${YELLOW}配置已完成，您可以稍后手动启动服务:${NC}"
    echo "docker-compose up -d"
fi

echo
echo -e "${GREEN}安装完成!${NC}"
