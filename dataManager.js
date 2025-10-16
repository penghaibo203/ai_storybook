import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * 数据管理器 - 负责绘本记录的存储和读取
 */
export class DataManager {
  constructor() {
    this.dataDir = path.join(__dirname, 'data');
    this.recordsFile = path.join(this.dataDir, 'storybook-records.json');
    this.ensureDataDirectory();
  }

  /**
   * 确保数据目录存在
   */
  ensureDataDirectory() {
    if (!fs.existsSync(this.dataDir)) {
      fs.mkdirSync(this.dataDir, { recursive: true });
      console.log('📁 创建数据目录:', this.dataDir);
    }
  }

  /**
   * 读取所有绘本记录
   * @returns {Array} 绘本记录数组
   */
  getAllRecords() {
    try {
      if (!fs.existsSync(this.recordsFile)) {
        return [];
      }
      
      const data = fs.readFileSync(this.recordsFile, 'utf8');
      const records = JSON.parse(data);
      
      // 按创建时间倒序排列（最新的在前）
      return records.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    } catch (error) {
      console.error('❌ 读取绘本记录失败:', error);
      return [];
    }
  }

  /**
   * 根据ID获取单个绘本记录
   * @param {string} id - 记录ID
   * @returns {Object|null} 绘本记录或null
   */
  getRecordById(id) {
    try {
      const records = this.getAllRecords();
      return records.find(record => record.id === id) || null;
    } catch (error) {
      console.error('❌ 获取绘本记录失败:', error);
      return null;
    }
  }

  /**
   * 保存新的绘本记录
   * @param {Object} storyData - 故事数据
   * @param {string} input - 用户输入的主题
   * @returns {Object} 保存的记录信息
   */
  saveRecord(storyData, input) {
    try {
      const records = this.getAllRecords();
      
      // 生成唯一ID
      const id = this.generateId();
      
      // 创建记录对象
      const record = {
        id,
        title: storyData.title || '未命名故事',
        input,
        story: storyData.story || [],
        images: storyData.images || [],
        voice: storyData.voice || [],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        pageCount: storyData.story ? storyData.story.length : 0
      };

      // 添加到记录数组
      records.unshift(record); // 添加到开头

      // 保存到文件
      fs.writeFileSync(this.recordsFile, JSON.stringify(records, null, 2), 'utf8');
      
      console.log('✅ 绘本记录保存成功:', {
        id: record.id,
        title: record.title,
        pageCount: record.pageCount
      });

      return record;
    } catch (error) {
      console.error('❌ 保存绘本记录失败:', error);
      throw error;
    }
  }

  /**
   * 删除绘本记录
   * @param {string} id - 记录ID
   * @returns {boolean} 是否删除成功
   */
  deleteRecord(id) {
    try {
      const records = this.getAllRecords();
      const filteredRecords = records.filter(record => record.id !== id);
      
      if (filteredRecords.length === records.length) {
        console.log('⚠️ 未找到要删除的记录:', id);
        return false;
      }

      fs.writeFileSync(this.recordsFile, JSON.stringify(filteredRecords, null, 2), 'utf8');
      console.log('✅ 绘本记录删除成功:', id);
      return true;
    } catch (error) {
      console.error('❌ 删除绘本记录失败:', error);
      return false;
    }
  }

  /**
   * 更新绘本记录
   * @param {string} id - 记录ID
   * @param {Object} updates - 要更新的字段
   * @returns {Object|null} 更新后的记录或null
   */
  updateRecord(id, updates) {
    try {
      const records = this.getAllRecords();
      const recordIndex = records.findIndex(record => record.id === id);
      
      if (recordIndex === -1) {
        console.log('⚠️ 未找到要更新的记录:', id);
        return null;
      }

      // 更新记录
      records[recordIndex] = {
        ...records[recordIndex],
        ...updates,
        updatedAt: new Date().toISOString()
      };

      fs.writeFileSync(this.recordsFile, JSON.stringify(records, null, 2), 'utf8');
      console.log('✅ 绘本记录更新成功:', id);
      
      return records[recordIndex];
    } catch (error) {
      console.error('❌ 更新绘本记录失败:', error);
      return null;
    }
  }

  /**
   * 获取记录统计信息
   * @returns {Object} 统计信息
   */
  getStats() {
    try {
      const records = this.getAllRecords();
      return {
        total: records.length,
        thisMonth: records.filter(record => {
          const recordDate = new Date(record.createdAt);
          const now = new Date();
          return recordDate.getMonth() === now.getMonth() && 
                 recordDate.getFullYear() === now.getFullYear();
        }).length,
        totalPages: records.reduce((sum, record) => sum + (record.pageCount || 0), 0)
      };
    } catch (error) {
      console.error('❌ 获取统计信息失败:', error);
      return { total: 0, thisMonth: 0, totalPages: 0 };
    }
  }

  /**
   * 生成唯一ID
   * @returns {string} 唯一ID
   */
  generateId() {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substr(2, 5);
    return `story_${timestamp}_${random}`;
  }

  /**
   * 清理旧记录（可选功能）
   * @param {number} daysToKeep - 保留天数
   * @returns {number} 删除的记录数量
   */
  cleanupOldRecords(daysToKeep = 30) {
    try {
      const records = this.getAllRecords();
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);
      
      const filteredRecords = records.filter(record => {
        return new Date(record.createdAt) > cutoffDate;
      });
      
      const deletedCount = records.length - filteredRecords.length;
      
      if (deletedCount > 0) {
        fs.writeFileSync(this.recordsFile, JSON.stringify(filteredRecords, null, 2), 'utf8');
        console.log(`✅ 清理了 ${deletedCount} 条旧记录`);
      }
      
      return deletedCount;
    } catch (error) {
      console.error('❌ 清理旧记录失败:', error);
      return 0;
    }
  }
}

// 创建单例实例
export const dataManager = new DataManager();
export default dataManager;
