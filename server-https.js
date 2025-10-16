import express from 'express';
import path from 'path';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import dotenv from 'dotenv';
import https from 'https';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { dataManager } from './dataManager.js';

// ES模块中获取__dirname的替代方案
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const HTTPS_PORT = process.env.HTTPS_PORT || 3443;

// 安全中间件 - 严格CSP策略，完全阻止Google Analytics
const cspDirectives = {
  defaultSrc: ["'self'"],
  styleSrc: ["'self'", "'unsafe-inline'", "https://cdn.tailwindcss.com", "https://cdnjs.cloudflare.com"],
  scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", "https:", "http:", "blob:", "data:"],
  scriptSrcElem: ["'self'", "'unsafe-inline'", "https:", "http:", "blob:", "data:"],
  fontSrc: ["'self'", "https://cdnjs.cloudflare.com"],
  imgSrc: ["'self'", "data:", "https:", "http:"],
  connectSrc: ["'self'", "https:", "http:", "ws:", "wss:"], // 允许所有连接
  mediaSrc: ["'self'", "https:", "http:"],
  workerSrc: ["'self'", "blob:"],
  childSrc: ["'self'", "blob:"],
  // 明确阻止Google Analytics相关域名
  frameAncestors: ["'none'"],
  baseUri: ["'self'"],
  formAction: ["'self'"],
  objectSrc: ["'none'"],
  scriptSrcAttr: ["'unsafe-inline'"]
};

// CSP策略已简化，不再需要Google Analytics支持

app.use(helmet({
  contentSecurityPolicy: {
    directives: cspDirectives
  },
  crossOriginOpenerPolicy: { policy: "same-origin-allow-popups" },
  originAgentCluster: false
}));

// CORS配置
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://hypersmart.work', 'https://www.hypersmart.work', 'https://129.226.121.30:3443'] 
    : ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://localhost:3443', 'https://localhost:3443'],
  credentials: true
}));

// HTTPS重定向中间件
app.use((req, res, next) => {
  if (req.secure || req.header('x-forwarded-proto') === 'https') {
    next();
  } else {
    res.redirect(`https://${req.header('host')}${req.url}`);
  }
});

// 压缩中间件
app.use(compression());

// 解析JSON和URL编码
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 静态文件服务
app.use(express.static(path.join(__dirname), {
  maxAge: process.env.NODE_ENV === 'production' ? '1d' : 0, // 生产环境启用缓存
  etag: true,
  lastModified: true,
  setHeaders: (res, path) => {
    // 为JS和CSS文件设置正确的MIME类型
    if (path.endsWith('.js')) {
      res.setHeader('Content-Type', 'application/javascript');
    } else if (path.endsWith('.css')) {
      res.setHeader('Content-Type', 'text/css');
    }
  }
}));

// 专门的public目录服务
app.use('/css', express.static(path.join(__dirname, 'public', 'css'), {
  maxAge: 0, // 禁用CSS缓存用于调试
  etag: false,
  lastModified: false
}));

// favicon服务
app.use('/favicon.ico', express.static(path.join(__dirname, 'public', 'favicon.ico'), {
  maxAge: process.env.NODE_ENV === 'production' ? '1y' : '0',
  etag: true,
  lastModified: true
}));

// 健康检查路由
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// API路由 - 代理Coze API请求
app.post('/api/generate-story', async (req, res) => {
  // 设置更长的超时时间
  req.setTimeout(120000); // 2分钟
  res.setTimeout(120000); // 2分钟
  
  try {
    const { input } = req.body;
    
    if (!input || typeof input !== 'string') {
      return res.status(400).json({ 
        success: false,
        error: '请提供有效的故事主题' 
      });
    }

    // 导入API模块
    const { generateStory } = await import('./api.js');
    
    console.log(`📝 收到故事生成请求: "${input}"`);
    
    const storyData = await generateStory(input);
    
    console.log('✅ 故事生成成功');
    
    // 保存绘本记录
    try {
      const savedRecord = dataManager.saveRecord(storyData, input);
      console.log('💾 绘本记录已保存:', savedRecord.id);
      
      res.json({
        success: true,
        data: storyData,
        recordId: savedRecord.id
      });
    } catch (saveError) {
      console.error('⚠️ 保存绘本记录失败，但故事生成成功:', saveError);
      res.json({
        success: true,
        data: storyData,
        warning: '故事生成成功，但保存记录失败'
      });
    }
  } catch (error) {
    console.error('❌ 生成故事API错误:', error);
    res.status(500).json({
      success: false,
      error: error.message || '服务器内部错误'
    });
  }
});

// 获取绘本记录列表
app.get('/api/records', (req, res) => {
  try {
    const records = dataManager.getAllRecords();
    const stats = dataManager.getStats();
    
    res.json({
      success: true,
      data: {
        records,
        stats
      }
    });
  } catch (error) {
    console.error('❌ 获取绘本记录失败:', error);
    res.status(500).json({
      success: false,
      error: '获取绘本记录失败'
    });
  }
});

// 获取单个绘本记录
app.get('/api/records/:id', (req, res) => {
  try {
    const { id } = req.params;
    const record = dataManager.getRecordById(id);
    
    if (!record) {
      return res.status(404).json({
        success: false,
        error: '绘本记录不存在'
      });
    }
    
    res.json({
      success: true,
      data: record
    });
  } catch (error) {
    console.error('❌ 获取绘本记录失败:', error);
    res.status(500).json({
      success: false,
      error: '获取绘本记录失败'
    });
  }
});

// 删除绘本记录
app.delete('/api/records/:id', (req, res) => {
  try {
    const { id } = req.params;
    const success = dataManager.deleteRecord(id);
    
    if (success) {
      res.json({
        success: true,
        message: '绘本记录删除成功'
      });
    } else {
      res.status(404).json({
        success: false,
        error: '绘本记录不存在'
      });
    }
  } catch (error) {
    console.error('❌ 删除绘本记录失败:', error);
    res.status(500).json({
      success: false,
      error: '删除绘本记录失败'
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

// 启动HTTP服务器
const httpServer = app.listen(PORT, () => {
  console.log(`🌐 HTTP服务器运行在端口 ${PORT}`);
  console.log(`📱 访问地址: http://localhost:${PORT}`);
});

// 启动HTTPS服务器
let httpsServer = null;

// 检查SSL证书文件
const sslCertPath = path.join(__dirname, 'ssl', 'hypersmart.work_bundle.crt');
const sslKeyPath = path.join(__dirname, 'ssl', 'hypersmart.work.key');

if (fs.existsSync(sslCertPath) && fs.existsSync(sslKeyPath)) {
  try {
    const sslOptions = {
      cert: fs.readFileSync(sslCertPath),
      key: fs.readFileSync(sslKeyPath)
    };

    httpsServer = https.createServer(sslOptions, app);
    
    httpsServer.listen(HTTPS_PORT, () => {
      console.log(`🔒 HTTPS服务器运行在端口 ${HTTPS_PORT}`);
      console.log(`🌐 访问地址: https://localhost:${HTTPS_PORT}`);
      console.log(`🌐 生产地址: https://hypersmart.work`);
    });

    console.log('✅ SSL证书加载成功');
  } catch (error) {
    console.error('❌ SSL证书加载失败:', error.message);
    console.log('⚠️  将仅启动HTTP服务器');
  }
} else {
  console.log('⚠️  SSL证书文件不存在，将仅启动HTTP服务器');
  console.log('📁 请确保以下文件存在:');
  console.log(`   - ${sslCertPath}`);
  console.log(`   - ${sslKeyPath}`);
}

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('🛑 收到SIGTERM信号，正在关闭服务器...');
  
  httpServer.close(() => {
    console.log('✅ HTTP服务器已关闭');
  });

  if (httpsServer) {
    httpsServer.close(() => {
      console.log('✅ HTTPS服务器已关闭');
      process.exit(0);
    });
  } else {
    process.exit(0);
  }
});

process.on('SIGINT', () => {
  console.log('🛑 收到SIGINT信号，正在关闭服务器...');
  
  httpServer.close(() => {
    console.log('✅ HTTP服务器已关闭');
  });

  if (httpsServer) {
    httpsServer.close(() => {
      console.log('✅ HTTPS服务器已关闭');
      process.exit(0);
    });
  } else {
    process.exit(0);
  }
});

export default app;
