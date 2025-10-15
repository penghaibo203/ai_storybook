# AI英文绘本故事生成器

一个基于Coze API的AI英文绘本故事生成和阅读平台，专为儿童设计。

## 功能特性

- 🤖 **AI故事生成** - 使用Coze API生成个性化的英文故事
- 🎨 **图片生成** - 每页故事都配有AI生成的精美插图
- 🔊 **语音合成** - 支持TTS语音朗读功能
- 📖 **翻页阅读** - 流畅的翻页体验
- 🌍 **双语支持** - 英文故事配中文翻译
- 🎯 **儿童友好** - 专为儿童设计的界面和内容

## 技术栈

- **后端**: Node.js + Express.js
- **前端**: 原生JavaScript + HTML5 + CSS3
- **AI服务**: Coze API
- **部署**: 支持Docker、Vercel等平台

## 快速开始

### 1. 环境检查

```bash
# 检查部署环境
./scripts/check-environment.sh

# 快速部署（交互式）
./scripts/quick-deploy.sh
```

### 2. 安装依赖

```bash
npm install
```

### 3. 配置环境变量

创建 `.env` 文件并配置以下变量：

```bash
# Coze API 配置
COZE_API_TOKEN=your_coze_api_token_here
COZE_BASE_URL=https://api.coze.cn
COZE_WORKFLOW_ID=7561291747888807978

# 服务器配置
PORT=3000
NODE_ENV=development
```

### 4. 启动应用

```bash
# 开发模式
npm run dev

# 生产模式
npm start
```

### 5. 访问应用

打开浏览器访问 `http://localhost:3000`

## 📚 详细部署文档

查看 [DEPLOYMENT.md](./DEPLOYMENT.md) 获取完整的部署指南，包括：
- 开发环境部署
- 生产环境部署  
- HTTPS部署
- Docker部署
- Vercel部署
- 故障排除

## API配置说明

### 获取Coze API Token

1. 访问 [Coze开放平台](https://www.coze.cn/open)
2. 创建应用并获取API Token
3. 将Token配置到环境变量中

### Workflow ID

当前使用的Workflow ID: `7561291747888807978`

## 部署

### HTTPS部署（推荐）

#### 1. 准备SSL证书
```bash
# 运行SSL证书生成脚本
./scripts/generate-ssl.sh

# 选择证书类型：
# 1) 开发环境自签名证书
# 2) 生产环境Let's Encrypt证书
# 3) 导入现有证书
```

#### 2. 部署到生产环境
```bash
# 设置环境变量
export COZE_API_TOKEN=your_token_here

# 运行HTTPS部署脚本
./scripts/deploy-https.sh
```

#### 3. 验证部署
```bash
# 检查服务状态
docker-compose -f docker-compose.https.yml ps

# 测试HTTPS连接
curl -k https://hypersmart.work

# 查看日志
docker-compose -f docker-compose.https.yml logs -f
```

### Docker部署（HTTP）

```bash
# 构建镜像
docker build -t ai-storybook .

# 运行容器
docker run -p 3000:3000 -e COZE_API_TOKEN=your_token ai-storybook
```

### Vercel部署

1. 将代码推送到GitHub
2. 在Vercel中导入项目
3. 配置环境变量
4. 部署

## 项目结构

```
ai_storybook/
├── server.js          # Express服务器
├── api.js             # Coze API集成
├── main.js            # 前端主逻辑
├── storyRenderer.js   # 故事渲染器
├── style.css          # 样式文件
├── index.html         # 主页面
├── package.json       # 项目配置
├── Dockerfile         # Docker配置
├── docker-compose.yml # Docker Compose配置
└── vercel.json        # Vercel部署配置
```

## 开发说明

### 环境变量安全

- 请勿将真实的API Token提交到Git仓库
- 使用 `.env` 文件管理本地环境变量
- 生产环境通过平台的环境变量配置

### API调用流程

1. 用户输入故事主题
2. 前端发送请求到 `/api/generate-story`
3. 后端调用Coze API生成故事
4. 返回包含标题、故事、图片、音频的完整数据
5. 前端渲染故事页面

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request！