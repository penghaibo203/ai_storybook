#!/usr/bin/env node

/**
 * 检查 Coze API Token 配置
 */

import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';

// 加载环境变量
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.join(__dirname, '..', '.env') });

console.log('🔍 检查 Coze API Token 配置...\n');

// 检查环境变量
const token = process.env.COZE_API_TOKEN;
const workflowId = process.env.COZE_WORKFLOW_ID || '7561291747888807978';
const baseURL = process.env.COZE_BASE_URL || 'https://api.coze.cn';

console.log('📋 配置信息:');
console.log(`   Base URL: ${baseURL}`);
console.log(`   Workflow ID: ${workflowId}`);
console.log(`   Token: ${token ? (token.substring(0, 20) + '...' + token.substring(token.length - 10)) : '❌ 未设置'}`);

if (!token || token === 'your_coze_api_token_here') {
    console.log('\n❌ 错误: 未配置有效的 Coze API Token');
    console.log('\n💡 解决方案:');
    console.log('   1. 创建 .env 文件（如果不存在）');
    console.log('   2. 在 .env 文件中添加以下配置:');
    console.log('      COZE_API_TOKEN=your_actual_token_here');
    console.log('      COZE_WORKFLOW_ID=your_workflow_id');
    console.log('      COZE_BASE_URL=https://api.coze.cn');
    console.log('\n   3. 重启服务器使配置生效');
    process.exit(1);
}

console.log('\n✅ Token 配置存在');
console.log('\n💡 如果仍然遇到认证失败，请检查:');
console.log('   1. Token 是否有效且未过期');
console.log('   2. Token 是否有访问指定 Workflow 的权限');
console.log('   3. Workflow ID 是否正确');
console.log('   4. 服务器是否已重启以加载新的环境变量');

