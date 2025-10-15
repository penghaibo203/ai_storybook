# 原生部署指南

本文档介绍如何将AI英文绘本应用部署到生产环境，使用PM2进程管理和Nginx反向代理，无需Docker。

## 🚀 快速开始

### 1. 基础部署（HTTP）

```bash
# 设置环境变量
export COZE_API_TOKEN=your_token_here

# 运行原生部署脚本
./scripts/deploy-native.sh
```

### 2. HTTPS部署（需要root权限）

```bash
# 设置环境变量
export COZE_API_TOKEN=your_token_here

# 运行HTTPS部署脚本（需要root权限）
sudo ./scripts/deploy-https-native.sh
```

## 📋 部署选项

### 选项1：简单部署（推荐新手）

```bash
# 1. 设置环境变量
export COZE_API_TOKEN=your_token_here

# 2. 安装依赖
npm install

# 3. 启动应用
npm run start:production
```

### 选项2：完整部署（推荐生产环境）

```bash
# 1. 设置环境变量
export COZE_API_TOKEN=your_token_here

# 2. 运行部署脚本
./scripts/deploy-native.sh

# 3. 配置Nginx（可选）
# 脚本会生成nginx.conf.template文件
```

### 选项3：HTTPS部署（推荐生产环境）

```bash
# 1. 设置环境变量
export COZE_API_TOKEN=your_token_here

# 2. 准备SSL证书
# 确保以下文件存在：
# - ssl/hypersmart.work_bundle.crt
# - ssl/hypersmart.work.key

# 3. 运行HTTPS部署
sudo ./scripts/deploy-https-native.sh
```

## 🔧 系统要求

### 基础要求
- **Node.js**: >= 16.0.0
- **npm**: >= 8.0.0
- **PM2**: 进程管理器
- **内存**: >= 512MB
- **磁盘**: >= 1GB

### HTTPS部署额外要求
- **Nginx**: Web服务器
- **SSL证书**: 有效的SSL证书
- **Root权限**: 配置系统服务

## 📦 安装依赖

### 1. 安装Node.js

```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# CentOS/RHEL
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# macOS
brew install node
```

### 2. 安装PM2

```bash
npm install -g pm2
```

### 3. 安装Nginx（HTTPS部署需要）

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y nginx

# CentOS/RHEL
sudo yum install -y nginx

# 启动Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

## 🚀 部署步骤

### 步骤1：准备环境

```bash
# 克隆项目
git clone <your-repo-url>
cd ai-storybook

# 设置环境变量
export COZE_API_TOKEN=your_token_here

# 安装依赖
npm install --production
```

### 步骤2：配置应用

```bash
# 创建环境配置文件
cat > .env << EOF
NODE_ENV=production
PORT=3000
COZE_API_TOKEN=$COZE_API_TOKEN
COZE_BASE_URL=https://api.coze.cn
COZE_WORKFLOW_ID=7561291747888807978
EOF
```

### 步骤3：启动应用

```bash
# 使用PM2启动
pm2 start ecosystem.config.js --env production

# 保存PM2配置
pm2 save

# 设置开机自启
pm2 startup
```

### 步骤4：配置Nginx（可选）

```bash
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

# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
```

## 🔧 管理命令

### PM2管理

```bash
# 查看状态
pm2 status

# 查看日志
pm2 logs ai-storybook

# 重启应用
pm2 restart ai-storybook

# 停止应用
pm2 stop ai-storybook

# 删除应用
pm2 delete ai-storybook

# 监控面板
pm2 monit

# 重载配置
pm2 reload ai-storybook
```

### 系统管理

```bash
# 查看Nginx状态
sudo systemctl status nginx

# 查看Nginx日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# 重启Nginx
sudo systemctl restart nginx

# 查看应用日志
tail -f logs/combined.log
tail -f logs/error.log
```

## 📊 监控和维护

### 1. 健康检查

```bash
# 检查应用健康状态
curl http://localhost:3000/health

# 检查PM2状态
pm2 status

# 检查系统资源
htop
```

### 2. 日志管理

```bash
# 查看应用日志
pm2 logs ai-storybook --lines 100

# 查看错误日志
pm2 logs ai-storybook --err --lines 50

# 实时监控日志
pm2 logs ai-storybook --follow
```

### 3. 性能监控

```bash
# PM2监控面板
pm2 monit

# 系统资源监控
htop
iostat -x 1
```

## 🔒 HTTPS配置

### 1. 获取SSL证书

```bash
# 使用Let's Encrypt（推荐）
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com

# 或使用自签名证书
./scripts/generate-ssl.sh
```

### 2. 配置HTTPS

```bash
# 运行HTTPS部署脚本
sudo ./scripts/deploy-https-native.sh
```

### 3. 验证HTTPS

```bash
# 测试HTTPS连接
curl -k https://your-domain.com/health

# 检查SSL证书
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

## 🚨 故障排除

### 常见问题

1. **应用无法启动**
   ```bash
   # 检查端口是否被占用
   netstat -tlnp | grep :3000
   
   # 检查PM2状态
   pm2 status
   
   # 查看错误日志
   pm2 logs ai-storybook --err
   ```

2. **Nginx配置错误**
   ```bash
   # 测试Nginx配置
   sudo nginx -t
   
   # 查看Nginx错误日志
   sudo tail -f /var/log/nginx/error.log
   ```

3. **SSL证书问题**
   ```bash
   # 检查证书文件
   ls -la ssl/
   
   # 验证证书
   openssl x509 -in ssl/hypersmart.work_bundle.crt -text -noout
   ```

### 日志位置

- **应用日志**: `logs/combined.log`
- **错误日志**: `logs/error.log`
- **PM2日志**: `~/.pm2/logs/`
- **Nginx日志**: `/var/log/nginx/`

## 📈 性能优化

### 1. PM2配置优化

```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'ai-storybook',
    script: 'server.js',
    instances: 'max', // 使用所有CPU核心
    exec_mode: 'cluster',
    max_memory_restart: '1G',
    node_args: '--max-old-space-size=1024'
  }]
};
```

### 2. Nginx优化

```nginx
# 启用gzip压缩
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

# 设置缓存
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## 🔄 更新部署

### 1. 更新应用

```bash
# 拉取最新代码
git pull origin main

# 安装新依赖
npm install --production

# 重启应用
pm2 restart ai-storybook
```

### 2. 回滚部署

```bash
# 回滚到上一个版本
git checkout HEAD~1

# 重启应用
pm2 restart ai-storybook
```

## 📞 技术支持

如果遇到问题，请检查：

1. **环境变量**是否正确设置
2. **端口**是否被占用
3. **日志文件**中的错误信息
4. **系统资源**是否充足

更多帮助请参考：
- [PM2官方文档](https://pm2.keymetrics.io/docs/)
- [Nginx官方文档](https://nginx.org/en/docs/)
- [Node.js官方文档](https://nodejs.org/docs/)
