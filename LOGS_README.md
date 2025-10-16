# 📋 服务日志获取工具使用说明

## 🛠️ 工具概览

本项目提供了三个强大的日志获取和监控工具：

1. **`get-logs.sh`** - 功能完整的日志获取工具
2. **`logs.sh`** - 简化的日志查看工具  
3. **`monitor.sh`** - 服务监控和调试工具

## 📊 工具详细说明

### 1. get-logs.sh - 完整日志工具

功能最全面的日志获取工具，支持多种日志源和过滤选项。

#### 基本用法
```bash
./scripts/get-logs.sh [选项]
```

#### 主要选项
- `-h, --help` - 显示帮助信息
- `-a, --all` - 显示所有日志
- `-e, --error` - 只显示错误日志
- `-w, --warn` - 显示警告和错误日志
- `-i, --info` - 显示信息、警告和错误日志
- `-f, --follow` - 实时跟踪日志
- `-n, --lines N` - 显示最后N行日志
- `-g, --grep PATTERN` - 过滤包含指定模式的日志
- `-o, --output FILE` - 将日志输出到文件
- `--pm2` - 显示PM2进程日志
- `--nginx` - 显示Nginx日志
- `--system` - 显示系统日志

#### 使用示例
```bash
# 实时跟踪所有日志
./scripts/get-logs.sh -f

# 显示最后100行错误日志
./scripts/get-logs.sh -e -n 100

# 过滤包含'error'的日志并保存到文件
./scripts/get-logs.sh -g 'error' -o error_logs.txt

# 显示PM2进程日志
./scripts/get-logs.sh --pm2 -f

# 显示指定时间之后的日志
./scripts/get-logs.sh -s '2024-01-01'
```

### 2. logs.sh - 简化日志工具

轻量级的日志查看工具，适合日常使用。

#### 基本用法
```bash
./scripts/logs.sh [选项]
```

#### 主要选项
- `-h, --help` - 显示帮助
- `-f, --follow` - 实时跟踪日志
- `-n N` - 显示最后N行（默认50行）
- `-e, --error` - 只显示错误日志
- `-g PATTERN` - 过滤包含指定内容的日志

#### 使用示例
```bash
# 显示最后50行日志
./scripts/logs.sh

# 实时跟踪日志
./scripts/logs.sh -f

# 显示最后100行错误日志
./scripts/logs.sh -e -n 100

# 过滤包含'error'的日志
./scripts/logs.sh -g 'error'
```

### 3. monitor.sh - 监控调试工具

全面的服务监控和调试工具，提供多种监控功能。

#### 基本用法
```bash
./scripts/monitor.sh [命令]
```

#### 可用命令
- `status` - 显示服务状态
- `logs` - 显示实时日志
- `errors` - 显示错误日志
- `restart` - 重启服务
- `health` - 健康检查
- `performance` - 性能监控
- `debug` - 调试信息
- `clean` - 清理日志
- `backup` - 备份日志

#### 使用示例
```bash
# 查看服务状态
./scripts/monitor.sh status

# 实时查看日志
./scripts/monitor.sh logs

# 查看错误日志
./scripts/monitor.sh errors

# 重启服务
./scripts/monitor.sh restart

# 健康检查
./scripts/monitor.sh health

# 性能监控
./scripts/monitor.sh performance

# 调试信息
./scripts/monitor.sh debug

# 清理日志
./scripts/monitor.sh clean

# 备份日志
./scripts/monitor.sh backup
```

## 🎯 使用场景

### 日常监控
```bash
# 快速查看服务状态
./scripts/monitor.sh status

# 查看最近错误
./scripts/monitor.sh errors

# 实时监控日志
./scripts/logs.sh -f
```

### 问题排查
```bash
# 查看详细错误信息
./scripts/get-logs.sh -e -n 200

# 过滤特定错误
./scripts/get-logs.sh -g 'API认证失败'

# 查看系统日志
./scripts/get-logs.sh --system -g 'ai-storybook'
```

### 性能分析
```bash
# 性能监控
./scripts/monitor.sh performance

# 查看调试信息
./scripts/monitor.sh debug

# 健康检查
./scripts/monitor.sh health
```

### 维护操作
```bash
# 重启服务
./scripts/monitor.sh restart

# 清理日志
./scripts/monitor.sh clean

# 备份日志
./scripts/monitor.sh backup
```

## 📁 日志文件位置

### PM2日志
- 输出日志: `~/.pm2/logs/ai-storybook-out.log`
- 错误日志: `~/.pm2/logs/ai-storybook-error.log`

### 应用日志
- 应用日志: `./logs/app.log`
- 错误日志: `./logs/error.log`
- 综合日志: `./logs/combined.log`

### 系统日志
- Nginx日志: `/var/log/nginx/`
- 系统日志: `journalctl`

## 🔧 故障排除

### 常见问题

1. **权限问题**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **PM2未安装**
   ```bash
   npm install -g pm2
   ```

3. **日志文件不存在**
   - 检查服务是否正在运行
   - 确认日志目录权限

4. **无法访问系统日志**
   ```bash
   sudo ./scripts/get-logs.sh --system
   ```

### 调试步骤

1. **检查服务状态**
   ```bash
   ./scripts/monitor.sh status
   ```

2. **查看错误日志**
   ```bash
   ./scripts/monitor.sh errors
   ```

3. **健康检查**
   ```bash
   ./scripts/monitor.sh health
   ```

4. **查看调试信息**
   ```bash
   ./scripts/monitor.sh debug
   ```

## 📝 最佳实践

1. **定期监控**
   - 使用 `monitor.sh status` 定期检查服务状态
   - 使用 `monitor.sh health` 进行健康检查

2. **日志管理**
   - 定期使用 `monitor.sh clean` 清理日志
   - 使用 `monitor.sh backup` 备份重要日志

3. **问题排查**
   - 先查看错误日志确定问题类型
   - 使用过滤功能快速定位问题
   - 结合系统日志进行综合分析

4. **性能优化**
   - 使用 `monitor.sh performance` 监控资源使用
   - 根据日志分析优化应用性能

## 🚀 快速开始

1. **首次使用**
   ```bash
   # 查看帮助
   ./scripts/monitor.sh help
   
   # 检查服务状态
   ./scripts/monitor.sh status
   ```

2. **日常监控**
   ```bash
   # 实时日志
   ./scripts/logs.sh -f
   
   # 错误检查
   ./scripts/monitor.sh errors
   ```

3. **问题排查**
   ```bash
   # 详细错误日志
   ./scripts/get-logs.sh -e -n 100
   
   # 重启服务
   ./scripts/monitor.sh restart
   ```

这些工具将帮助您更好地监控和管理AI英文绘本应用的服务状态！
