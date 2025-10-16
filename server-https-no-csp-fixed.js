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
import { dataManager } from './dataManager.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const HTTPS_PORT = process.env.HTTPS_PORT || 3443;

// 完全禁用CSP和所有安全限制
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginOpenerPolicy: false,
  crossOriginResourcePolicy: false,
  crossOriginEmbedderPolicy: false,
  originAgentCluster: false,
  referrerPolicy: false,
  xssFilter: false,
  noSniff: false,
  frameguard: false,
  hsts: false
}));

// CORS配置 - 允许所有来源
app.use(cors({
  origin: true,
  credentials: true
}));

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
    csp: 'completely disabled'
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

// 故事生成函数
async function generateStory(input) {
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

  return storyData;
}

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
  console.log('📁 证书路径:', sslCertPath);
  console.log('📁 密钥路径:', sslKeyPath);
}

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
