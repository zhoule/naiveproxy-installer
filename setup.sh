#!/bin/bash

# NaiveProxy Docker-Compose 安装脚本
# 用于快速部署基于 Caddy2 的 NaiveProxy 服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}NaiveProxy Docker-Compose 安装向导${NC}"
echo -e "${GREEN}==================================${NC}"
echo

# 检测 Linux 发行版
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        echo -e "${RED}无法检测操作系统类型${NC}"
        exit 1
    fi
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}提示: 建议使用 root 用户运行此脚本${NC}"
        echo -e "${YELLOW}或使用: sudo ./setup.sh${NC}"
        read -p "是否继续? (y/n): " CONTINUE
        if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# 安装 Docker (Ubuntu/Debian)
install_docker_debian() {
    echo -e "${YELLOW}正在为 Ubuntu/Debian 安装 Docker...${NC}"

    # 更新软件包索引
    apt-get update -y

    # 安装必要的依赖
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # 添加 Docker 官方 GPG 密钥
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # 设置 Docker 仓库
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 安装 Docker Engine
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 启动 Docker 服务
    systemctl start docker
    systemctl enable docker

    echo -e "${GREEN}Docker 安装完成!${NC}"
}

# 安装 Docker (CentOS/RHEL)
install_docker_rhel() {
    echo -e "${YELLOW}正在为 CentOS/RHEL 安装 Docker...${NC}"

    # 安装必要的依赖
    yum install -y yum-utils

    # 添加 Docker 仓库
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    # 安装 Docker Engine
    yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 启动 Docker 服务
    systemctl start docker
    systemctl enable docker

    echo -e "${GREEN}Docker 安装完成!${NC}"
}

# 检查并安装 Docker
check_install_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓ Docker 已安装${NC}"
        docker --version
        return 0
    fi

    echo -e "${YELLOW}! Docker 未安装${NC}"
    read -p "是否自动安装 Docker? (y/n): " INSTALL_DOCKER

    if [[ $INSTALL_DOCKER =~ ^[Yy]$ ]]; then
        detect_os
        case $OS in
            ubuntu|debian)
                install_docker_debian
                ;;
            centos|rhel|rocky|almalinux)
                install_docker_rhel
                ;;
            *)
                echo -e "${RED}不支持的操作系统: $OS${NC}"
                echo -e "${YELLOW}请手动安装 Docker: https://docs.docker.com/engine/install/${NC}"
                exit 1
                ;;
        esac
    else
        echo -e "${RED}Docker 是必需的，请手动安装后再运行此脚本${NC}"
        echo -e "${YELLOW}安装文档: https://docs.docker.com/engine/install/${NC}"
        exit 1
    fi
}

# 检查并安装 Docker Compose
check_install_docker_compose() {
    # 检查 Docker Compose V2 (docker compose)
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✓ Docker Compose 已安装 (V2)${NC}"
        docker compose version
        return 0
    fi

    # 检查 Docker Compose V1 (docker-compose)
    if command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}✓ Docker Compose 已安装 (V1)${NC}"
        docker-compose --version
        return 0
    fi

    echo -e "${YELLOW}! Docker Compose 未安装${NC}"

    # 如果 Docker 已安装且包含 compose 插件，则不需要额外安装
    if command -v docker &> /dev/null; then
        echo -e "${YELLOW}尝试使用 Docker Compose V2...${NC}"
        if docker compose version &> /dev/null 2>&1; then
            echo -e "${GREEN}✓ Docker Compose V2 可用${NC}"
            return 0
        fi
    fi

    read -p "是否安装 Docker Compose? (y/n): " INSTALL_COMPOSE

    if [[ $INSTALL_COMPOSE =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}正在安装 Docker Compose V2...${NC}"

        # 下载并安装 docker-compose (standalone)
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

        echo -e "${GREEN}Docker Compose 安装完成!${NC}"
        docker-compose --version
    else
        echo -e "${RED}Docker Compose 是必需的，请手动安装后再运行此脚本${NC}"
        exit 1
    fi
}

# 检查端口占用
check_port() {
    local port=$1
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$port "; then
            return 0
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":$port "; then
            return 0
        fi
    fi
    return 1
}

# 检查必要的端口
check_ports() {
    echo -e "${BLUE}检查端口占用情况...${NC}"

    # 检查 443 端口
    if check_port 443; then
        echo -e "${YELLOW}⚠ 警告: 端口 443 已被占用${NC}"
        echo -e "${YELLOW}请确保其他服务未使用此端口，或先停止占用该端口的服务${NC}"
        read -p "是否继续? (y/n): " CONTINUE
        if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
            exit 0
        fi
    else
        echo -e "${GREEN}✓ 端口 443 可用${NC}"
    fi
}

# 安装基础工具
install_basic_tools() {
    echo -e "${BLUE}检查基础工具...${NC}"

    local tools_needed=()

    # 检查必要的工具
    command -v curl &> /dev/null || tools_needed+=("curl")
    command -v wget &> /dev/null || tools_needed+=("wget")

    if [ ${#tools_needed[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ 基础工具已就绪${NC}"
        return 0
    fi

    echo -e "${YELLOW}需要安装以下工具: ${tools_needed[*]}${NC}"

    detect_os
    case $OS in
        ubuntu|debian)
            apt-get update -y
            apt-get install -y "${tools_needed[@]}"
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y "${tools_needed[@]}"
            ;;
        *)
            echo -e "${YELLOW}请手动安装: ${tools_needed[*]}${NC}"
            ;;
    esac
}

# 主安装流程
main() {
    # 检查 root 权限
    check_root

    # 安装基础工具
    install_basic_tools

    # 检查并安装 Docker
    check_install_docker

    # 检查并安装 Docker Compose
    check_install_docker_compose

    # 检查端口
    check_ports

    echo
    echo -e "${GREEN}✓ 所有依赖已就绪!${NC}"
    echo

    # 创建必要的目录
    echo -e "${YELLOW}创建必要的目录...${NC}"
    mkdir -p caddy/caddy_data caddy/caddy_config

    # 确保 Caddyfile 不是目录
    if [ -d "caddy/Caddyfile" ]; then
        echo -e "${YELLOW}检测到 caddy/Caddyfile 是目录，正在删除...${NC}"
        rm -rf caddy/Caddyfile
    fi

    # 获取用户配置
    echo
    echo -e "${YELLOW}请输入配置信息:${NC}"
    echo

    read -p "请输入您的域名 [jzhou.fun]: " DOMAIN
    DOMAIN=${DOMAIN:-jzhou.fun}
    while [ -z "$DOMAIN" ]; do
        echo -e "${RED}域名不能为空${NC}"
        read -p "请输入您的域名: " DOMAIN
    done

    read -p "请输入您的邮箱 (用于 SSL 证书) [jack.zxzhou@gmail.com]: " EMAIL
    EMAIL=${EMAIL:-jack.zxzhou@gmail.com}
    while [ -z "$EMAIL" ]; do
        echo -e "${RED}邮箱不能为空${NC}"
        read -p "请输入您的邮箱: " EMAIL
    done

    read -p "请输入代理用户名 [zhoule]: " USERNAME
    USERNAME=${USERNAME:-zhoule}
    while [ -z "$USERNAME" ]; do
        echo -e "${RED}用户名不能为空${NC}"
        read -p "请输入代理用户名: " USERNAME
    done

    read -sp "请输入代理密码: " PASSWORD
    echo
    while [ -z "$PASSWORD" ]; do
        echo -e "${RED}密码不能为空${NC}"
        read -sp "请输入代理密码: " PASSWORD
        echo
    done

    read -p "请输入反向代理目标 [https://demo.cloudreve.org]: " REVERSE_PROXY
    REVERSE_PROXY=${REVERSE_PROXY:-https://demo.cloudreve.org}

    # 创建 .env 文件
    echo -e "${YELLOW}创建环境变量文件...${NC}"
    cat > .env << EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF

    # 创建 docker-compose.yml
    echo -e "${YELLOW}创建 docker-compose.yml 配置...${NC}"
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  caddy2:
    image: pocat/naiveproxy:latest
    container_name: caddy2
    restart: always
    network_mode: "host"
    volumes:
      - ./caddy/Caddyfile:/etc/naiveproxy/Caddyfile
      - ./caddy/caddy_data:/data
      - ./caddy/caddy_config:/config
    environment:
      - DOMAIN=${DOMAIN:-example.com}
      - EMAIL=${EMAIL:-admin@example.com}
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

    # 创建 .gitignore
    echo -e "${YELLOW}创建 .gitignore 文件...${NC}"
    cat > .gitignore << 'EOF'
# 环境变量文件（包含敏感信息）
.env

# Caddy 运行时数据
caddy/caddy_data/
caddy/caddy_config/

# 日志文件
*.log

# 临时文件
*.tmp
*.swp
*~

# macOS
.DS_Store

# IDE
.vscode/
.idea/
*.iml
EOF

    echo
    echo -e "${GREEN}配置完成!${NC}"
    echo
    echo -e "${YELLOW}重要提示:${NC}"
    echo -e "1. 请确保域名 ${GREEN}$DOMAIN${NC} 已解析到本服务器的IP地址"
    echo -e "   服务器IP: ${GREEN}$(curl -s ifconfig.me || echo '请手动查询')${NC}"
    echo -e "2. 请确保防火墙开放了 ${GREEN}443${NC} 端口"
    echo
    read -p "是否现在启动服务? (y/n): " START_NOW

    if [[ $START_NOW =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}启动服务...${NC}"

        # 检查 docker-compose.yml 是否存在
        if [ ! -f "docker-compose.yml" ]; then
            echo -e "${RED}错误: docker-compose.yml 文件不存在${NC}"
            echo -e "${YELLOW}当前目录: $(pwd)${NC}"
            exit 1
        fi

        # 启动服务
        if docker compose version &> /dev/null; then
            docker compose up -d
        else
            docker-compose up -d
        fi

        echo
        echo -e "${GREEN}✓ 服务启动成功!${NC}"
        echo
        echo -e "${YELLOW}==================================${NC}"
        echo -e "${YELLOW}NaiveProxy 配置信息:${NC}"
        echo -e "${YELLOW}==================================${NC}"
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
        echo
        echo -e "${YELLOW}查看服务状态:${NC}"
        if docker compose version &> /dev/null; then
            docker compose ps
        else
            docker-compose ps
        fi
    else
        echo
        echo -e "${YELLOW}配置已完成，您可以稍后手动启动服务:${NC}"
        echo "docker-compose up -d"
    fi

    echo
    echo -e "${GREEN}==================================${NC}"
    echo -e "${GREEN}安装完成!${NC}"
    echo -e "${GREEN}==================================${NC}"
}

# 执行主流程
main
