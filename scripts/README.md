# AI英文绘本服务端启动脚本

本目录包含了AI英文绘本应用的服务端启动和管理脚本。

## 📁 脚本文件说明

### 🚀 启动脚本

#### `start-server.sh` - 完整启动脚本
功能最全面的启动脚本，包含环境检查、依赖安装、多种启动模式选择。

```bash
./scripts/start-server.sh
```

**特性：**
- ✅ 自动检查Node.js和PM2环境
- ✅ 自动安装缺失的依赖
- ✅ 支持多种启动模式（HTTP/HTTPS/开发/集群）
- ✅ 自动测试服务健康状态
- ✅ 可选配置Nginx反向代理
- ✅ 可选设置开机自启

#### `quick-start.sh` - 快速启动脚本
简化版启动脚本，适合快速启动服务。

```bash
./scripts/quick-start.sh
```

**特性：**
- ⚡ 快速启动HTTP服务
- 🔄 自动停止现有进程
- 📊 显示服务状态

### 🏭 部署脚本

#### `deploy-production.sh` - 生产环境部署脚本
完整的生产环境部署脚本，包含系统检查、依赖安装、服务配置等。

```bash
./scripts/deploy-production.sh
```

**特性：**
- 🖥️ 系统环境检查
- 📦 生产依赖安装
- 🔧 环境配置检查
- 🚀 集群模式启动
- 🌐 可选Nginx配置
- 🔄 开机自启设置

### 🛠️ 管理脚本

#### `service-manager.sh` - 服务管理脚本
提供完整的服务管理功能。

```bash
# 启动服务
./scripts/service-manager.sh start

# 停止服务
./scripts/service-manager.sh stop

# 重启服务
./scripts/service-manager.sh restart

# 查看状态
./scripts/service-manager.sh status

# 查看日志
./scripts/service-manager.sh logs
./scripts/service-manager.sh logs --lines 100

# 监控面板
./scripts/service-manager.sh monitor

# 健康检查
./scripts/service-manager.sh health

# 更新服务
./scripts/service-manager.sh update

# 备份数据
./scripts/service-manager.sh backup

# 显示帮助
./scripts/service-manager.sh help
```

### 🔧 修复脚本

#### `fix-module-error.sh` - ES6模块错误修复脚本
修复前端JavaScript的ES6模块语法错误。

```bash
./scripts/fix-module-error.sh
```

#### `deploy-h5-mobile.sh` - H5移动端优化部署脚本
部署H5移动端优化版本。

```bash
./scripts/deploy-h5-mobile.sh
```

## 🚀 快速开始

### 1. 首次部署

```bash
# 使用生产环境部署脚本
./scripts/deploy-production.sh
```

### 2. 日常管理

```bash
# 启动服务
./scripts/service-manager.sh start

# 查看状态
./scripts/service-manager.sh status

# 查看日志
./scripts/service-manager.sh logs
```

### 3. 快速重启

```bash
# 使用快速启动脚本
./scripts/quick-start.sh
```

## 📋 环境要求

- **Node.js**: >= 16.0.0
- **PM2**: 最新版本
- **操作系统**: Linux/macOS
- **内存**: >= 512MB
- **磁盘**: >= 1GB

## 🔧 配置说明

### 环境变量 (.env)

```bash
# Coze API配置
COZE_API_TOKEN=your_api_token_here

# 服务器配置
NODE_ENV=production
PORT=3000

# 日志配置
LOG_LEVEL=info
```

### PM2配置 (ecosystem.config.cjs)

```javascript
module.exports = {
  apps: [{
    name: 'ai-storybook',
    script: 'server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
}
```

## 📊 监控和维护

### 查看服务状态

```bash
pm2 status
pm2 monit
```

### 查看日志

```bash
pm2 logs
pm2 logs --lines 100
```

### 重启服务

```bash
pm2 restart all
```

### 停止服务

```bash
pm2 stop all
```

## 🆘 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 查看端口占用
   lsof -i :3000
   
   # 停止占用进程
   pm2 delete all
   ```

2. **服务启动失败**
   ```bash
   # 查看错误日志
   pm2 logs --err
   
   # 检查环境变量
   cat .env
   ```

3. **内存不足**
   ```bash
   # 减少实例数量
   pm2 start server.js --name ai-storybook --instances 2
   ```

### 日志位置

- PM2日志: `~/.pm2/logs/`
- 应用日志: `./logs/`
- 错误日志: `pm2 logs --err`

## 📞 技术支持

如果遇到问题，请：

1. 查看日志文件
2. 检查环境配置
3. 运行健康检查脚本
4. 联系技术支持

---

**注意**: 请确保在运行脚本前已正确配置环境变量和API Token。
