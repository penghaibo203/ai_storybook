// ES模块版本的PM2配置文件
export default {
  apps: [{
    name: 'ai-storybook',
    script: 'server.js',
    instances: 'max', // 使用所有CPU核心
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'development',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    // 日志配置
    log_file: './logs/combined.log',
    out_file: './logs/out.log',
    error_file: './logs/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // 自动重启配置
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    
    // 健康检查
    health_check_grace_period: 3000,
    
    // 进程管理
    min_uptime: '10s',
    max_restarts: 10,
    
    // 环境变量
    env_file: '.env',
    
    // 高级配置
    kill_timeout: 5000,
    listen_timeout: 3000,
    shutdown_with_message: true
  }]
};
