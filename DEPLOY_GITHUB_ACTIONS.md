# 🚀 GitHub Actions 一键部署指南

> **核心优势**：代码推送到 `main` 分支 → 自动构建镜像 → 服务器自动拉取部署 → **全程零手工操作**

---

## 📋 前置准备（一次性）

### 1. 服务器要求
- **系统**：Ubuntu 20.04+/Debian 11+/CentOS 7+/Rocky/AlmaLinux
- **配置**：2核 4G 内存起步（建议 4核 8G）
- **磁盘**：30GB+ 可用空间
- **网络**：公网 IP，开放 80/443/22 端口

### 2. 域名准备（需提前解析到服务器 IP）
| 域名 | 用途 | 示例 |
|------|------|------|
| `API_DOMAIN` | 后端 API | `api.love.example.com` |
| `WEB_DOMAIN` | 前端网站 | `love.example.com` |
| `ADMIN_DOMAIN` | 后台管理 | `admin.love.example.com` |

### 3. 服务器一次性初始化
```bash
# 1. 登录服务器
ssh root@your-server-ip

# 2. 下载并运行初始化脚本
cd /www/wwwroot/love
# 上传项目文件到此目录（含 server-setup.sh）
chmod +x server-setup.sh
./server-setup.sh
```

脚本会自动：
- ✅ 安装 Docker + Docker Compose + 配置国内镜像源
- ✅ 创建项目目录 `/www/wwwroot/love`
- ✅ 检查 `.env` 配置
- ✅ 首次拉取镜像并启动全栈服务
- ✅ 配置每日自动清理旧镜像

---

## 🔐 GitHub Secrets 配置（关键步骤）

在 GitHub 仓库 **Settings → Secrets and variables → Actions** 中添加：

| Secret 名称 | 必填 | 说明 | 示例 |
|-------------|------|------|------|
| `SERVER_HOST` | ✅ | 服务器公网 IP | `1.2.3.4` |
| `SERVER_USER` | ✅ | SSH 用户名 | `root` |
| `SERVER_SSH_KEY` | ✅ | 服务器私钥（`cat ~/.ssh/id_rsa`） | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `SERVER_PORT` | ❌ | SSH 端口（默认 22） | `22` |
| `GITHUB_TOKEN` | ✅ | **自动提供**，无需手动添加 | - |

> ⚠️ **SSH 密钥生成**：`ssh-keygen -t ed25519 -C "github-actions-deploy"` → 公钥加到服务器 `~/.ssh/authorized_keys`

---

## 📦 项目文件结构（部署相关）

```
Kirameku-Love/
├── .github/workflows/deploy.yml    # GitHub Actions 工作流
├── docker-compose.prod.yml         # 生产环境编排
├── .env.example                    # 环境变量模板
├── .dockerignore
├── server-setup.sh                 # 服务器一次性初始化脚本
├── nginx/
│   └── nginx.conf                  # Nginx 统一入口配置
├── backend/
│   ├── Dockerfile
│   └── entrypoint.sh               # 自动迁移、创建超管
├── frontend/
│   ├── Dockerfile
│   └── next.config.js              # output: standalone
└── admin/
    ├── Dockerfile
    └── nginx.conf                  # SPA 回退配置
```

---

## 🚀 部署流程

### 首次部署
```bash
# 1. 克隆/上传项目到服务器 /www/wwwroot/love
# 2. 配置环境变量
cp .env.example .env
vim .env  # 填入所有必填项

# 3. 运行服务器初始化（仅首次）
chmod +x server-setup.sh
./server-setup.sh

# 4. 推送代码触发自动部署
git add .
git commit -m "feat: initial deploy config"
git push origin main
```

### 日常部署
```bash
# 只需推送代码
git push origin main
# 或手动触发：GitHub Actions → Deploy to Production → Run workflow
```

---

## ⚙️ 环境变量说明（.env 必填项）

```bash
# 数据库密码（强密码）
DB_PASSWORD=your_strong_db_password

# JWT 密钥（生产环境必须修改，32+ 随机字符）
SECRET_KEY=your_super_secret_key_min_32_chars

# 三个域名（已解析到服务器 IP）
API_DOMAIN=api.yourdomain.com
WEB_DOMAIN=love.yourdomain.com
ADMIN_DOMAIN=admin.yourdomain.com

# CORS 允许的前端域名
CORS_ORIGINS=https://love.yourdomain.com,https://admin.yourdomain.com

# 微信开放平台（头像获取必需）
WECHAT_APPID=your_appid
WECHAT_SECRET=your_secret

# 高德地图（地图模块必需）
AMAP_WEB_SERVICE_KEY=your_amap_key

# 存储类型：local 或 oss
STORAGE_TYPE=local
# OSS 配置（如用 OSS 必填）
OSS_ACCESS_KEY_ID=
OSS_ACCESS_KEY_SECRET=
OSS_BUCKET_NAME=
OSS_ENDPOINT=oss-cn-hangzhou.aliyuncs.com

# 首次自动创建超管
CREATE_SUPERUSER=true
SUPERUSER_EMAIL=admin@yourdomain.com
SUPERUSER_PASSWORD=your_admin_password
```

---

## 🔧 常用运维命令

```bash
cd /www/wwwroot/love

# 查看所有服务状态
docker compose -f docker-compose.prod.yml ps

# 查看实时日志
docker compose -f docker-compose.prod.yml logs -f [service_name]

# 重启单个服务
docker compose -f docker-compose.prod.yml restart backend

# 完全重建（配置变更后）
docker compose -f docker-compose.prod.yml up -d --build --force-recreate

# 回滚到上一版本
docker compose -f docker-compose.prod.yml down
# 修改 docker-compose.prod.yml 中镜像 tag 为旧版本
docker compose -f docker-compose.prod.yml up -d

# 进入容器调试
docker exec -it love-backend bash
docker exec -it love-frontend sh
docker exec -it love-postgres psql -U love_user -d love_db

# 手动跑迁移（如有 schema 变更）
docker exec -it love-backend alembic upgrade head

# 备份数据库
docker exec love-postgres pg_dump -U love_user love_db > backup_$(date +%F).sql

# 恢复数据库
docker exec -i love-postgres psql -U love_user -d love_db < backup_2024-01-15.sql
```

---

## 🛠️ 故障排查

| 现象 | 排查步骤 |
|------|----------|
| **Actions 部署卡住** | 检查 `SERVER_SSH_KEY` 格式、服务器 22 端口、SSH 免密登录 |
| **前端 404/白屏** | 检查 `NEXT_PUBLIC_API_BASE`、Nginx 配置、Next.js `output: standalone` |
| **后端 502** | `docker logs love-backend` 查看、检查数据库连接、健康检查端点 |
| **数据库连接失败** | 检查 `DB_PASSWORD` 是否一致、postgres 容器健康状态 |
| **SSL 证书报错** | 宝塔申请证书 → 部署到 `/www/server/panel/vhost/cert/<域名>/` → `docker restart love-nginx` |
| **媒体文件不显示** | 检查 `STORAGE_TYPE`、OSS 配置、Nginx `/uploads/` 代理、挂载卷权限 |

---

## 🔄 更新流程

### 代码更新
```bash
git push origin main  # 自动触发构建+部署
```

### 环境变量更新
1. 服务器修改 `.env`
2. `docker compose -f docker-compose.prod.yml up -d --force-recreate`

### 数据库 Schema 变更
1. 后端代码生成迁移：`alembic revision --autogenerate -m "msg"`
2. 推送代码 → Actions 自动部署 → 入口脚本自动跑 `alembic upgrade head`

### 域名/SSL 变更
1. 修改 `.env` 域名
2. 宝塔重新申请证书
3. `docker restart love-nginx`

---

## 📊 监控建议

- **健康检查**：`curl https://api.yourdomain.com/health`
- **日志聚合**：Loki + Promtail 或 ELK
- **指标监控**：Prometheus + Grafana（Node Exporter + cAdvisor）
- **告警**：钉钉/企微/飞书 Webhook

---

## ✅ 清单确认

部署前逐项核对：

- [ ] 服务器已运行 `server-setup.sh` 且无报错
- [ ] GitHub Secrets 全部配置正确
- [ ] 三个域名已解析到服务器 IP
- [ ] 宝塔已申请并部署三个域名的 SSL 证书
- [ ] `.env` 所有必填项已填入真实值
- [ ] 微信开放平台配置了授权回调域名
- [ ] 高德地图 Key 已配置 HTTP 服务白名单
- [ ] 推送代码触发 Actions 绿色通过
- [ ] 三个域名均可正常访问，功能测试通过

---

## 🎉 完成！

之后每次只需：
```bash
git push origin main
```

**享受推送即部署的丝滑体验！** 🚀