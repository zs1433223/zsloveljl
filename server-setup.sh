#!/bin/bash
# ===========================================
# 服务器一次性初始化脚本
# 在目标服务器上运行 **一次** 即可
# 支持：Ubuntu 20.04/22.04/24.04, Debian 11/12, CentOS 7/8/9, Rocky/AlmaLinux
# ===========================================

set -e

echo "🔧 Kirameku-Love 服务器环境初始化"

# ---------- 1. 检测系统 ----------
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "❌ 无法检测操作系统"
    exit 1
fi

echo "📋 检测到: $PRETTY_NAME"

# ---------- 2. 安装 Docker & Docker Compose ----------
install_docker() {
    if command -v docker &> /dev/null && command -v docker compose &> /dev/null; then
        echo "✅ Docker 已安装: $(docker --version)"
        echo "✅ Docker Compose 已安装: $(docker compose version)"
        return
    fi

    echo "📦 安装 Docker..."
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    systemctl enable --now docker

    # 验证
    docker --version
    docker compose version
    echo "✅ Docker 安装完成"
}

install_docker

# ---------- 3. 配置 Docker 镜像加速（国内服务器必需） ----------
configure_docker_registry() {
    echo "⚡ 配置 Docker 镜像加速..."
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
    systemctl daemon-reload
    systemctl restart docker
    echo "✅ Docker 加速配置完成"
}

configure_docker_registry

# ---------- 4. 创建项目目录 ----------
PROJECT_DIR="/www/wwwroot/love"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "📁 项目目录: $PROJECT_DIR"

# ---------- 5. 生成 docker-compose.prod.yml（如果不存在） ----------
if [ ! -f docker-compose.prod.yml ]; then
    echo "📝 请先上传项目文件到 $PROJECT_DIR"
    echo "   包含: docker-compose.prod.yml, .env, nginx/, backend/, frontend/, admin/, init_db.sql"
    exit 1
fi

# ---------- 6. 检查 .env ----------
if [ ! -f .env ]; then
    echo "⚠️  请复制 .env.example 为 .env 并填入真实配置："
    echo "   cp .env.example .env"
    echo "   vim .env"
    exit 1
fi

# ---------- 7. 加载环境变量 ----------
set -a
source .env
set +a

# ---------- 8. 登录 GHCR（如果需要拉取私有镜像） ----------
if [ -n "$GHCR_TOKEN" ] && [ -n "$GHCR_USER" ]; then
    echo "🔐 登录 GHCR..."
    echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
fi

# ---------- 9. 首次拉取并启动 ----------
echo "🚀 首次启动全栈服务..."
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --remove-orphans

# ---------- 10. 等待服务健康 ----------
echo "⏳ 等待服务就绪..."
sleep 10

# 检查后端健康
for i in {1..30}; do
    if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ 后端健康检查通过"
        break
    fi
    sleep 2
done

# ---------- 11. 配置定时清理 ----------
echo "🧹 配置每日镜像清理..."
(crontab -l 2>/dev/null; echo "0 3 * * * docker image prune -af --filter \"until=168h\" > /var/log/docker-prune.log 2>&1") | crontab -

# ---------- 12. 完成 ----------
echo ""
echo "==========================================="
echo "🎉 服务器初始化完成！"
echo "==========================================="
echo ""
echo "📋 后续部署方式："
echo "   1. 推送代码到 GitHub main 分支"
echo "   2. 或在 GitHub Actions 页面手动点击「Run workflow」"
echo ""
echo "🔗 访问地址（需域名解析 + SSL 证书）："
echo "   前端:  https://${WEB_DOMAIN}"
echo "   后端:  https://${API_DOMAIN}"
echo "   后台:  https://${ADMIN_DOMAIN}"
echo ""
echo "📂 常用命令："
echo "   查看日志: docker compose -f docker-compose.prod.yml logs -f"
echo "   重启:     docker compose -f docker-compose.prod.yml restart"
echo "   停止:     docker compose -f docker-compose.prod.yml down"
echo "   更新:     git pull && docker compose -f docker-compose.prod.yml up -d --build"
echo ""
echo "⚠️  重要提醒："
echo "   - 确保域名已解析到服务器 IP"
echo "   - 宝塔面板申请 SSL 证书并部署到 /www/server/panel/vhost/cert/<域名>/"
echo "   - 首次部署后检查数据库是否自动初始化（查看 postgres 容器日志）"