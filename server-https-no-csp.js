import express from 'express';
import path from 'path';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import https from 'https';
import http from 'http';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const HTTPS_PORT = process.env.HTTPS_PORT || 3443;

// 完全禁用CSP进行调试
app.use(helmet({
  contentSecurityPolicy: false,
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
  maxAge: process.env.NODE_ENV === 'production' ? '1d' : 0,
  etag: true,
  lastModified: true,
  setHeaders: (res, path) => {
    if (path.endsWith('.js')) {
      res.setHeader('Content-Type', 'application/javascript');
    } else if (path.endsWith('.css')) {
      res.setHeader('Content-Type', 'text/css');
    }
  }
}));

// 专门的public目录服务
app.use('/css', express.static(path.join(__dirname, 'public', 'css'), {
  maxAge: 0,
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
    environment: process.env.NODE_ENV || 'development',
    csp: 'disabled'
  });
});

// API路由 - 代理Coze API请求
app.post('/api/generate-story', async (req, res) => {
  try {
    const { input } = req.body;
    
    if (!input) {
      return res.status(400).json({ error: '输入内容不能为空' });
    }

    console.log('📝 收到故事生成请求:', input);

    // 导入Coze API
    const { CozeAPI } = await import('@coze/api');
    
    const apiClient = new CozeAPI({
      token: process.env.COZE_API_TOKEN,
      baseURL: process.env.COZE_BASE_URL || 'https://api.coze.cn'
    });

    console.log('🚀 开始调用Coze API生成故事...');
    console.log('📝 输入主题:', input);
    console.log('🔑 使用Token:', process.env.COZE_API_TOKEN?.substring(0, 20) + '...');
    console.log('🆔 Workflow ID:', process.env.COZE_WORKFLOW_ID);

    const workflowId = process.env.COZE_WORKFLOW_ID || '7561291747888807978';
    
    const response = await apiClient.workflows.runs.stream({
      workflow_id: workflowId,
      parameters: {
        input: input
      }
    });

    console.log('📡 API响应:', response);

    let fullContent = '';
    
    for await (const chunk of response) {
      console.log('📦 收到数据块:', chunk);
      
      if (chunk.event === 'Message' && chunk.data?.content) {
        fullContent += chunk.data.content;
        console.log('📄 收到内容:', chunk.data.content);
      }
    }

    if (!fullContent) {
      throw new Error('API返回内容为空');
    }

    // 解析JSON内容
    let storyData;
    try {
      storyData = JSON.parse(fullContent);
      console.log('✅ 解析成功:', storyData);
    } catch (parseError) {
      console.error('❌ JSON解析失败:', parseError);
      throw new Error('API返回数据格式错误');
    }

    // 验证必要字段
    if (!storyData.story || !storyData.images) {
      throw new Error('API返回数据不完整');
    }

    console.log('🎉 故事生成成功:', storyData);

    res.json({
      success: true,
      data: storyData
    });

  } catch (error) {
    console.error('❌ 故事生成失败:', error);
    res.status(500).json({
      error: error.message || '故事生成失败'
    });
  }
});

// 启动服务器
const startServer = () => {
  // 创建HTTPS服务器
  let httpsServer;
  try {
    const sslOptions = {
      key: fs.readFileSync(path.join(__dirname, 'ssl', 'hypersmart.work.key')),
      cert: fs.readFileSync(path.join(__dirname, 'ssl', 'hypersmart.work_bundle.crt'))
    };
    
    httpsServer = https.createServer(sslOptions, app);
    httpsServer.listen(HTTPS_PORT, () => {
      console.log('✅ SSL证书加载成功');
      console.log(`🔒 HTTPS服务器运行在端口 ${HTTPS_PORT}`);
      console.log(`🌐 访问地址: https://localhost:${HTTPS_PORT}`);
      console.log(`🌐 生产地址: https://hypersmart.work`);
    });
  } catch (error) {
    console.error('❌ SSL证书加载失败:', error.message);
    console.log('🔄 使用HTTP模式启动...');
  }

  // 创建HTTP服务器
  const httpServer = http.createServer(app);
  httpServer.listen(PORT, () => {
    console.log(`🌐 HTTP服务器运行在端口 ${PORT}`);
    console.log(`📱 访问地址: http://localhost:${PORT}`);
  });

  // 优雅关闭
  const gracefulShutdown = (signal) => {
    console.log(`🛑 收到${signal}信号，正在关闭服务器...`);
    
    if (httpsServer) {
      httpsServer.close(() => {
        console.log('✅ HTTPS服务器已关闭');
      });
    }
    
    httpServer.close(() => {
      console.log('✅ HTTP服务器已关闭');
      process.exit(0);
    });
  };

  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
};

startServer();
