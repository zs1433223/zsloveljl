# 📘 Kirameku-Love 一键部署操作手册

> **目标**：帮助您快速、准确地完成从零开始的自动化部署

---

## 📦 第一步：准备部署环境

### 1.1 上传部署包
将 `Kirameku-Love-DeployConfig.zip` 解压到您的 GitHub 仓库根目录，确保以下文件存在：

```
Kirameku-Love/
├── .github/workflows/deploy.yml
├── server-setup.sh
├── .env
├── DEPLOY_GITHUB_ACTIONS.md
└── ...
```

### 1.2 仓库设置
在 GitHub 仓库的 **Settings → Secrets and variables → Actions** 中添加以下 Secrets：

| Secret 名称 | 值 | 说明 |
|-------------|----|------|
| `SERVER_HOST` | `43.108.37.63` | 服务器公网 IP |
| `SERVER_USER` | `root` | SSH 登录用户名 |
| `SERVER_SSH_KEY` | `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC08xg9sYORhQATnJ2aDOj80VJszfLiU18+Lh6vNE+d/7siL5iXLN7u/bKv6A2F41Jueuv+Y0I/0t0JEnxdudNN49VNXNb0/on5Fpv5ea924X5yaqPXTJyONTol5CjH+JeBiN+i4zxVc20WqpGOqq07jbV9c7UqXiRTOQFZeoNnvyz4lyOXR44qqjz/YJpmCvgt72RpMT8WCkPvQamo8xszGPm8JJAEJZ2Q2+n0pKuuhWpKTvJk6ijXl7mRGeNRioBSiOKxeTCAfvpInhNiI0NoEGrRST7m3OOZlPXCwUyAwuMHaQ/65PYH0Rnn7UNy+fkUfWPz8TxrO1aP6FcsitgN skp-mj72vgao0s8hakwuwcdk` | 服务器 SSH 私钥 |
| `SERVER_PORT` | `22` | SSH 端口（默认值，可选） |

> ⚠️ **重要提示**：`SERVER_SSH_KEY` 必须是完整的 SSH 私钥内容，包括 `-----BEGIN OPENSSH PRIVATE KEY-----` 和 `-----END OPENSSH PRIVATE KEY-----`。

---

## 🚀 第二步：首次部署

### 2.1 推送代码
```bash
git add .
git commit -m "feat: initial deploy config"
git push origin main
```

### 2.2 观察部署过程
- 转到 GitHub 仓库的 **Actions** 标签页
- 查看 `Deploy to Production` 工作流的执行情况
- 等待其变为绿色（✅），表示部署成功

### 2.3 验证部署结果
```bash
# 1. 查看部署日志
# 在 Actions 页面点击成功的工作流，查看日志详情

# 2. 检查服务状态
# 在服务器上执行：
docker compose -f docker-compose.prod.yml ps

# 3. 访问应用
# 浏览器打开：https://www.zsljl.cn
# 应该能看到 Kirameku-Love 的首页
```

---

## 🛠️ 第三步：日常维护

### 3.1 日常部署
```bash
git push origin main
```

任何对 `main` 分支的推送都会自动触发部署，无需任何额外操作。

### 3.2 查看日志
```bash
# 查看所有服务的日志
docker compose -f docker-compose.prod.yml logs -f

# 查看特定服务的日志
docker compose -f docker-compose.prod.yml logs -f backend
```

### 3.3 重启服务
```bash
# 重启所有服务
docker compose -f docker-compose.prod.yml restart

# 重启单个服务
docker compose -f docker-compose.prod.yml restart frontend
```

### 3.4 数据库备份
```bash
# 进入 PostgreSQL 容器
docker exec -it love-postgres psql -U love_user -d love_db

# 或者直接导出备份
docker exec -i love-postgres pg_dump -U love_user love_db > backup_$(date +%F).sql
```

---

## 🛑 第四步：故障排查

| 现象 | 解决方案 |
|------|----------|
| **Actions 部署失败** | 检查 `SERVER_SSH_KEY` 格式是否正确，服务器 22 端口是否开放 |
| **前端页面 404/白屏** | 检查 `NEXT_PUBLIC_API_BASE` 是否正确，Nginx 配置是否生效 |
| **后端 502 错误** | `docker logs love-backend` 查看错误日志，检查数据库连接 |
| **SSL 证书错误** | 服务器宝塔面板申请证书并部署到 `/www/server/panel/vhost/cert/www.zsljl.cn/` |
| **媒体文件无法访问** | 检查 `STORAGE_TYPE` 配置，Nginx `/uploads/` 代理是否正确 |

---

## 📝 附录：常用命令汇总

```bash
# 项目根目录

# 查看服务状态
docker compose -f docker-compose.prod.yml ps

# 查看日志
docker compose -f docker-compose.prod.yml logs -f

# 重启服务
docker compose -f docker-compose.prod.yml restart

# 停止服务
docker compose -f docker-compose.prod.yml down

# 重建服务
docker compose -f docker-compose.prod.yml up -d --build --force-recreate

# 进入容器
docker exec -it love-backend bash

# 数据库备份
docker exec -i love-postgres pg_dump -U love_user love_db > backup_$(date +%F).sql

# 数据库恢复
docker exec -i love-postgres psql -U love_user -d love_db < backup_2024-01-15.sql
```

---

## 🎉 结束语

恭喜您！现在您已经成功搭建了一个全自动化的 CI/CD 部署流水线。未来所有的代码更新都将通过简单的 `git push` 来完成，真正实现了“推送即部署”的极致体验！

如有任何问题，请随时联系技术支持。祝您使用愉快！