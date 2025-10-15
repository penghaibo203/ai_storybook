# Nginx配置 - hypersmart.work

此目录包含用于hypersmart.work域名的Nginx配置文件。

## 配置文件说明

- `nginx.conf` - 主Nginx配置文件，包含HTTPS、SSL、代理等配置

## 部署步骤

### 1. 安装Nginx
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx

# CentOS/RHEL
sudo yum install nginx
```

### 2. 配置SSL证书
```bash
# 将SSL证书文件复制到指定位置
sudo cp ssl/fullchain.pem /etc/ssl/certs/hypersmart.work.crt
sudo cp ssl/privkey.pem /etc/ssl/private/hypersmart.work.key

# 设置正确的权限
sudo chmod 644 /etc/ssl/certs/hypersmart.work.crt
sudo chmod 600 /etc/ssl/private/hypersmart.work.key
```

### 3. 部署Nginx配置
```bash
# 复制配置文件
sudo cp hypersmart.work_nginx/nginx.conf /etc/nginx/sites-available/hypersmart.work

# 创建软链接启用站点
sudo ln -s /etc/nginx/sites-available/hypersmart.work /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
```

### 4. 配置防火墙
```bash
# 开放HTTP和HTTPS端口
sudo ufw allow 80
sudo ufw allow 443

# 检查防火墙状态
sudo ufw status
```

## 配置特性

### 🔒 SSL/TLS安全
- 支持TLS 1.2和TLS 1.3
- 强密码套件配置
- HSTS安全头
- 完美前向保密

### 🚀 性能优化
- HTTP/2支持
- Gzip压缩
- 静态文件缓存
- 连接池优化

### 🛡️ 安全头
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection
- Content-Security-Policy
- Strict-Transport-Security

### 🔄 代理配置
- 上游服务器负载均衡
- 健康检查端点
- API请求代理
- WebSocket支持

## 监控和维护

### 日志文件
- 访问日志：`/var/log/nginx/hypersmart.work_access.log`
- 错误日志：`/var/log/nginx/hypersmart.work_error.log`

### 常用命令
```bash
# 检查配置语法
sudo nginx -t

# 重新加载配置
sudo nginx -s reload

# 重启Nginx
sudo systemctl restart nginx

# 查看状态
sudo systemctl status nginx

# 查看日志
sudo tail -f /var/log/nginx/hypersmart.work_access.log
```

### SSL证书更新
```bash
# 使用certbot自动更新
sudo certbot renew --nginx

# 手动重启Nginx
sudo systemctl reload nginx
```

## 故障排除

### 常见问题

1. **SSL证书错误**
   - 检查证书文件路径和权限
   - 确认证书未过期
   - 验证证书链完整性

2. **代理连接失败**
   - 检查后端服务是否运行
   - 验证端口配置
   - 查看错误日志

3. **性能问题**
   - 检查gzip压缩是否启用
   - 优化缓存配置
   - 监控连接数

### 调试命令
```bash
# 检查端口占用
sudo netstat -tlnp | grep :443

# 测试SSL连接
openssl s_client -connect hypersmart.work:443

# 检查证书信息
openssl x509 -in /etc/ssl/certs/hypersmart.work.crt -text -noout
```
