import express from 'express';
import path from 'path';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';

// ES模块中获取__dirname的替代方案
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// 安全中间件
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://cdn.tailwindcss.com", "https://cdnjs.cloudflare.com"],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", "https://cdn.tailwindcss.com", "blob:", "https://infird.com"],
      scriptSrcElem: ["'self'", "'unsafe-inline'", "https://cdn.tailwindcss.com", "blob:", "https://infird.com"],
      fontSrc: ["'self'", "https://cdnjs.cloudflare.com"],
      imgSrc: ["'self'", "data:", "https:", "http:"],
      connectSrc: ["'self'", "https://api.coze.cn", "https://www.google-analytics.com", "https://analytics.google.com"],
      mediaSrc: ["'self'", "https:", "http:"],
      workerSrc: ["'self'", "blob:"],
      childSrc: ["'self'", "blob:"]
    }
  },
  crossOriginOpenerPolicy: { policy: "same-origin-allow-popups" },
  originAgentCluster: false
}));

// CORS配置
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://hypersmart.work', 'https://www.hypersmart.work', 'https://129.226.121.30:3000'] 
    : ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://129.226.121.30:3000'],
  credentials: true
}));

// HTTPS重定向中间件（生产环境）
if (process.env.NODE_ENV === 'production') {
  app.use((req, res, next) => {
    if (req.header('x-forwarded-proto') !== 'https') {
      res.redirect(`https://${req.header('host')}${req.url}`);
    } else {
      next();
    }
  });
}

// 压缩中间件
app.use(compression());

// 解析JSON和URL编码
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 静态文件服务
app.use(express.static(path.join(__dirname), {
  maxAge: process.env.NODE_ENV === 'production' ? '1d' : '0',
  etag: true,
  lastModified: true
}));

// 专门的public目录服务
app.use('/css', express.static(path.join(__dirname, 'public', 'css'), {
  maxAge: process.env.NODE_ENV === 'production' ? '1y' : '0',
  etag: true,
  lastModified: true
}));

// favicon服务
app.use('/favicon.ico', express.static(path.join(__dirname, 'public', 'favicon.ico'), {
  maxAge: process.env.NODE_ENV === 'production' ? '1y' : '0',
  etag: true,
  lastModified: true
}));

// API路由 - 代理Coze API请求
app.post('/api/generate-story', async (req, res) => {
  try {
    const { input } = req.body;
    
    if (!input || typeof input !== 'string') {
      return res.status(400).json({ 
        error: '请提供有效的故事主题' 
      });
    }

    // 导入API模块
    const { generateStory } = await import('./api.js');
    
    // 调用生成故事函数
    const storyData = await generateStory(input);
    
    res.json({
      success: true,
      data: storyData
    });
    
  } catch (error) {
    console.error('生成故事API错误:', error);
    
    res.status(500).json({
      success: false,
      error: error.message || '生成故事失败，请重试'
    });
  }
});

// 健康检查端点
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '1.0.0'
  });
});

// 根路径 - 返回主页面
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// 404处理
app.use('*', (req, res) => {
  res.status(404).json({
    error: '页面未找到',
    message: '请检查URL是否正确'
  });
});

// 错误处理中间件
app.use((error, req, res, next) => {
  console.error('服务器错误:', error);
  
  res.status(500).json({
    error: '服务器内部错误',
    message: process.env.NODE_ENV === 'production' 
      ? '请稍后重试' 
      : error.message
  });
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`🚀 AI绘本服务器启动成功！`);
  console.log(`📍 本地访问: http://localhost:${PORT}`);
  console.log(`🌍 环境: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📚 应用: AI英文绘本故事生成器`);
});

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('收到SIGTERM信号，正在关闭服务器...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('收到SIGINT信号，正在关闭服务器...');
  process.exit(0);
});

export default app;
