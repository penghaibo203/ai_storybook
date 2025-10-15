# AI英文绘本应用 - 完整部署指南

本文档提供了AI英文绘本应用的完整部署步骤，包括开发环境、生产环境和HTTPS部署。

## 📋 目录

- [环境要求](#环境要求)
- [开发环境部署](#开发环境部署)
- [生产环境部署](#生产环境部署)
- [HTTPS部署](#https部署)
- [Docker部署](#docker部署)
- [Vercel部署](#vercel部署)
- [故障排除](#故障排除)
- [监控和维护](#监控和维护)

## 🔧 环境要求

### 系统要求
- **操作系统**: Linux (Ubuntu 20.04+), macOS, Windows
- **Node.js**: 18.0.0 或更高版本
- **npm**: 8.0.0 或更高版本
- **Docker**: 20.10.0+ (可选)
- **Docker Compose**: 2.0.0+ (可选)

### 服务要求
- **Coze API**: 有效的API Token
- **域名**: hypersmart.work (HTTPS部署)
- **SSL证书**: Let's Encrypt 或商业证书

## 🚀 开发环境部署

### 1. 克隆项目
```bash
git clone https://github.com/你的用户名/ai-storybook.git
cd ai-storybook
```

### 2. 安装依赖
```bash
npm install
```

### 3. 配置环境变量
```bash
# 创建环境变量文件
cp env.example .env

# 编辑环境变量
nano .env
```

`.env` 文件内容：
```bash
# Coze API 配置
COZE_API_TOKEN=your_coze_api_token_here
COZE_BASE_URL=https://api.coze.cn
COZE_WORKFLOW_ID=7561291747888807978

# 服务器配置
PORT=3000
NODE_ENV=development
```

### 4. 启动开发服务器
```bash
# 开发模式（自动重启）
npm run dev

# 或生产模式
npm start
```

### 5. 验证部署
```bash
# 检查服务状态
curl http://localhost:3000/health

# 测试API
curl -X POST http://localhost:3000/api/generate-story \
  -H "Content-Type: application/json" \
  -d '{"input":"小兔子"}'
```

## 🌐 生产环境部署

### 1. 服务器准备
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 安装PM2进程管理器
sudo npm install -g pm2
```

### 2. 部署应用
```bash
# 克隆项目
git clone https://github.com/你的用户名/ai-storybook.git
cd ai-storybook

# 安装依赖
npm install --production

# 配置环境变量
cp env.example .env
nano .env  # 编辑真实配置
```

### 3. 配置PM2
```bash
# 创建PM2配置文件
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'ai-storybook',
    script: 'server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
}
EOF

# 启动应用
pm2 start ecosystem.config.js --env production

# 保存PM2配置
pm2 save
pm2 startup
```

### 4. 配置Nginx反向代理
```bash
# 安装Nginx
sudo apt install nginx -y

# 创建Nginx配置
sudo tee /etc/nginx/sites-available/ai-storybook << EOF
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# 启用站点
sudo ln -s /etc/nginx/sites-available/ai-storybook /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 🔒 HTTPS部署

### 1. 准备SSL证书
```bash
# 运行SSL证书生成脚本
./scripts/generate-ssl.sh

# 选择证书类型：
# 1) 开发环境自签名证书
# 2) 生产环境Let's Encrypt证书
# 3) 导入现有证书
```

### 2. 配置Let's Encrypt证书
```bash
# 安装certbot
sudo apt install certbot python3-certbot-nginx -y

# 获取证书
sudo certbot --nginx -d hypersmart.work -d www.hypersmart.work

# 设置自动更新
sudo crontab -e
# 添加以下行：
# 0 12 * * * /usr/bin/certbot renew --quiet
```

### 3. 部署HTTPS应用
```bash
# 设置环境变量
export COZE_API_TOKEN=your_token_here

# 运行HTTPS部署脚本
./scripts/deploy-https.sh
```

### 4. 验证HTTPS部署
```bash
# 检查服务状态
docker-compose -f docker-compose.https.yml ps

# 测试HTTPS连接
curl -k https://hypersmart.work

# 查看日志
docker-compose -f docker-compose.https.yml logs -f
```

## 🐳 Docker部署

### 1. 构建镜像
```bash
# 构建应用镜像
docker build -t ai-storybook .

# 查看镜像
docker images | grep ai-storybook
```

### 2. 运行容器
```bash
# 基本运行
docker run -d \
  --name ai-storybook \
  -p 3000:3000 \
  -e COZE_API_TOKEN=your_token_here \
  ai-storybook

# 使用Docker Compose
docker-compose up -d
```

### 3. HTTPS Docker部署
```bash
# 使用HTTPS配置
docker-compose -f docker-compose.https.yml up -d

# 检查服务
docker-compose -f docker-compose.https.yml ps
```

## ☁️ Vercel部署

### 1. 准备Vercel配置
项目已包含 `vercel.json` 配置文件，无需额外配置。

### 2. 连接GitHub
1. 访问 [Vercel Dashboard](https://vercel.com/dashboard)
2. 点击 "New Project"
3. 导入GitHub仓库
4. 选择 `ai-storybook` 项目

### 3. 配置环境变量
在Vercel Dashboard中设置环境变量：
```
COZE_API_TOKEN=your_token_here
COZE_BASE_URL=https://api.coze.cn
COZE_WORKFLOW_ID=7561291747888807978
NODE_ENV=production
```

### 4. 部署
1. 点击 "Deploy" 按钮
2. 等待部署完成
3. 访问提供的URL

## 🔧 故障排除

### 常见问题

#### 1. API认证失败
```bash
# 检查Token是否有效
curl -H "Authorization: Bearer $COZE_API_TOKEN" \
  https://api.coze.cn/v1/user/profile

# 更新Token
export COZE_API_TOKEN=new_token_here
```

#### 2. 端口占用
```bash
# 检查端口占用
sudo netstat -tlnp | grep :3000

# 杀死占用进程
sudo kill -9 PID
```

#### 3. SSL证书问题
```bash
# 检查证书有效期
openssl x509 -in ssl/fullchain.pem -text -noout | grep -E "(Not Before|Not After)"

# 更新证书
sudo certbot renew
```

#### 4. Docker容器问题
```bash
# 查看容器日志
docker logs ai-storybook

# 重启容器
docker restart ai-storybook

# 清理容器
docker-compose down
docker system prune -f
```

### 调试命令

```bash
# 检查应用状态
curl http://localhost:3000/health

# 检查API响应
curl -X POST http://localhost:3000/api/generate-story \
  -H "Content-Type: application/json" \
  -d '{"input":"测试"}' | jq .

# 检查SSL连接
openssl s_client -connect hypersmart.work:443

# 查看系统资源
htop
df -h
free -h
```

## 📊 监控和维护

### 1. 日志管理
```bash
# 应用日志
pm2 logs ai-storybook

# Nginx日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Docker日志
docker-compose logs -f
```

### 2. 性能监控
```bash
# PM2监控
pm2 monit

# 系统监控
htop
iotop
nethogs
```

### 3. 备份策略
```bash
# 备份应用代码
tar -czf ai-storybook-backup-$(date +%Y%m%d).tar.gz /path/to/ai-storybook

# 备份SSL证书
sudo cp -r /etc/letsencrypt /backup/ssl-$(date +%Y%m%d)
```

### 4. 更新部署
```bash
# 拉取最新代码
git pull origin main

# 重新安装依赖
npm install

# 重启应用
pm2 restart ai-storybook

# 或使用Docker
docker-compose down
docker-compose up -d --build
```

## 🔄 自动化部署

### GitHub Actions (可选)
创建 `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Deploy to server
      run: |
        # 部署脚本
        echo "Deploying to production..."
```

### 部署检查清单
- [ ] 环境变量配置正确
- [ ] SSL证书有效
- [ ] 域名解析正确
- [ ] 防火墙配置
- [ ] 监控和日志
- [ ] 备份策略
- [ ] 性能测试

## 📞 支持

如果遇到问题，请检查：
1. 日志文件
2. 系统资源使用情况
3. 网络连接
4. 证书有效期
5. API Token有效性

---

**🎉 部署完成！你的AI英文绘本应用现在应该可以正常访问了。**
