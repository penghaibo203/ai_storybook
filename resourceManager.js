import fs from 'fs';
import path from 'path';
import https from 'https';
import http from 'http';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export class ResourceManager {
  constructor() {
    this.publicDir = path.join(__dirname, 'public');
    this.storiesDir = path.join(this.publicDir, 'stories');
    this.ensureDirectory(this.storiesDir);
  }

  ensureDirectory(dir) {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }

  async downloadFile(url, filepath) {
    return new Promise((resolve, reject) => {
      // 处理空URL
      if (!url) {
          reject(new Error('URL is empty'));
          return;
      }

      const protocol = url.startsWith('https') ? https : http;
      
      const file = fs.createWriteStream(filepath);
      
      // 选项：忽略SSL证书错误（开发环境或自签名证书）
      const options = {
        rejectUnauthorized: false
      };

      const request = protocol.get(url, options, (response) => {
        if (response.statusCode === 301 || response.statusCode === 302) {
             // 处理重定向
             if (response.headers.location) {
                 this.downloadFile(response.headers.location, filepath)
                     .then(resolve)
                     .catch(reject);
                 return;
             }
        }

        if (response.statusCode !== 200) {
          file.close();
          fs.unlink(filepath, () => {}); // 删除空文件
          reject(new Error(`Failed to download file: ${response.statusCode}`));
          return;
        }
        
        response.pipe(file);
        
        file.on('finish', () => {
          file.close();
          resolve(filepath);
        });
      });
      
      request.on('error', (err) => {
        file.close();
        fs.unlink(filepath, () => {});
        reject(err);
      });
      
      file.on('error', (err) => {
        file.close();
        fs.unlink(filepath, () => {});
        reject(err);
      });
      
      // 设置超时
      request.setTimeout(30000, () => {
          request.destroy();
          file.close();
          fs.unlink(filepath, () => {});
          reject(new Error('Download timeout'));
      });
    });
  }

  async saveStoryResources(recordId, storyData) {
    const storyDir = path.join(this.storiesDir, recordId);
    const imagesDir = path.join(storyDir, 'images');
    const audioDir = path.join(storyDir, 'audio');
    
    this.ensureDirectory(imagesDir);
    this.ensureDirectory(audioDir);
    
    // 下载图片
    const localImages = [];
    if (storyData.images && Array.isArray(storyData.images)) {
      console.log(`🖼️ 开始下载 ${storyData.images.length} 张图片...`);
      for (let i = 0; i < storyData.images.length; i++) {
        const url = storyData.images[i];
        if (!url) {
            localImages.push('');
            continue;
        }
        
        // 尝试推断扩展名，默认 jpg
        let ext = '.jpg';
        if (url.includes('.png')) ext = '.png';
        else if (url.includes('.webp')) ext = '.webp';
        else if (url.includes('.jpeg')) ext = '.jpeg';
        
        const fileName = `${i + 1}${ext}`;
        const filePath = path.join(imagesDir, fileName);
        const publicPath = `/public/stories/${recordId}/images/${fileName}`;
        
        try {
          // console.log(`  📥 下载图片 ${i+1}/${storyData.images.length}`);
          await this.downloadFile(url, filePath);
          localImages.push(publicPath);
        } catch (error) {
          console.error(`  ❌ 图片 ${i+1} 下载失败: ${error.message} (URL: ${url.substring(0, 50)}...)`);
          localImages.push(url); // 失败则保留原 URL
        }
      }
    }
    
    // 下载音频
    const localVoice = [];
    if (storyData.voice && Array.isArray(storyData.voice)) {
      console.log(`🎵 开始下载 ${storyData.voice.length} 个音频...`);
      for (let i = 0; i < storyData.voice.length; i++) {
        const url = storyData.voice[i];
        if (!url) {
            localVoice.push('');
            continue;
        }
        
        // 尝试推断扩展名，默认 mp3
        let ext = '.mp3';
        if (url.includes('.wav')) ext = '.wav';
        else if (url.includes('.m4a')) ext = '.m4a';
        else if (url.includes('.aac')) ext = '.aac';
        
        const fileName = `${i + 1}${ext}`;
        const filePath = path.join(audioDir, fileName);
        const publicPath = `/public/stories/${recordId}/audio/${fileName}`;
        
        try {
          // console.log(`  📥 下载音频 ${i+1}/${storyData.voice.length}`);
          await this.downloadFile(url, filePath);
          localVoice.push(publicPath);
        } catch (error) {
          console.error(`  ❌ 音频 ${i+1} 下载失败: ${error.message} (URL: ${url.substring(0, 50)}...)`);
          localVoice.push(url); // 失败则保留原 URL
        }
      }
    }
    
    return {
      ...storyData,
      images: localImages.length > 0 ? localImages : storyData.images,
      voice: localVoice.length > 0 ? localVoice : storyData.voice
    };
  }
}

export const resourceManager = new ResourceManager();
export default resourceManager;

