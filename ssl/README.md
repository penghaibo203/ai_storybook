# SSL证书配置

此目录用于存放SSL证书文件。

## 证书文件说明

### 生产环境证书
- `fullchain.pem` - 完整证书链（包含服务器证书和中间证书）
- `privkey.pem` - 私钥文件
- `cert.pem` - 服务器证书
- `chain.pem` - 中间证书链

### 开发环境证书（可选）
- `dev-cert.pem` - 开发环境自签名证书
- `dev-key.pem` - 开发环境私钥

## 获取SSL证书

### 1. Let's Encrypt（推荐）
```bash
# 使用certbot获取免费SSL证书
sudo certbot certonly --webroot -w /var/www/html -d hypersmart.work -d www.hypersmart.work
```

### 2. 商业证书
从证书颁发机构（如DigiCert、GlobalSign等）购买SSL证书。

### 3. 自签名证书（仅用于开发）
```bash
# 生成自签名证书
openssl req -x509 -newkey rsa:4096 -keyout dev-key.pem -out dev-cert.pem -days 365 -nodes
```

## 安全注意事项

- ⚠️ **私钥文件必须保密**，不要提交到Git仓库
- 🔒 设置适当的文件权限：`chmod 600 privkey.pem`
- 📁 定期更新证书，避免过期
- 🛡️ 使用强密码保护私钥文件

## 证书更新

### Let's Encrypt自动更新
```bash
# 设置自动更新
sudo crontab -e
# 添加以下行：
0 12 * * * /usr/bin/certbot renew --quiet
```

### 手动更新
```bash
# 更新证书
sudo certbot renew
# 重启Nginx
sudo systemctl reload nginx
```
