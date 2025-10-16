/**
 * 故事渲染器类
 * 负责将故事数据渲染成HTML元素
 */
export class StoryRenderer {
    constructor(container) {
        this.container = container;
        this.currentPage = 0;
        this.storyData = null;
    }

    /**
     * 渲染完整故事
     * @param {Object} data - 故事数据
     */
    render(data) {
        if (!data || !data.story || !data.images) {
            console.error('故事数据不完整');
            return;
        }

        // 保存故事数据
        this.storyData = data;
        this.currentPage = 0;

        // 清空容器
        this.container.innerHTML = '';

        // 只渲染第一页
        this.renderCurrentPage();
    }

    /**
     * 渲染当前页面
     */
    renderCurrentPage() {
        if (!this.storyData) return;

        const { story, images, voice } = this.storyData;
        const text = story[this.currentPage];
        const imageUrl = images[this.currentPage];
        const audioUrl = voice && voice[this.currentPage];

        // 清空容器
        this.container.innerHTML = '';

        // 创建当前页面
        const pageElement = this.createPage(text, imageUrl, this.currentPage, audioUrl);
        this.container.appendChild(pageElement);
    }

    /**
     * 显示下一页
     */
    nextPage() {
        if (!this.storyData) return false;
        
        if (this.currentPage < this.storyData.story.length - 1) {
            this.currentPage++;
            this.renderCurrentPage();
            return true;
        }
        return false;
    }

    /**
     * 显示上一页
     */
    prevPage() {
        if (!this.storyData) return false;
        
        if (this.currentPage > 0) {
            this.currentPage--;
            this.renderCurrentPage();
            return true;
        }
        return false;
    }

    /**
     * 跳转到指定页面
     * @param {number} pageIndex - 页面索引
     */
    goToPage(pageIndex) {
        if (!this.storyData) return false;
        
        if (pageIndex >= 0 && pageIndex < this.storyData.story.length) {
            this.currentPage = pageIndex;
            this.renderCurrentPage();
            return true;
        }
        return false;
    }

    /**
     * 获取当前页面索引
     */
    getCurrentPage() {
        return this.currentPage;
    }

    /**
     * 获取总页面数
     */
    getTotalPages() {
        return this.storyData ? this.storyData.story.length : 0;
    }

    /**
     * 创建单个故事页面
     * @param {string} text - 故事文本（包含中英文）
     * @param {string} imageUrl - 图片URL
     * @param {number} index - 页面索引
     * @param {string} audioUrl - 音频URL（可选）
     * @returns {HTMLElement} 页面元素
     */
    createPage(text, imageUrl, index, audioUrl = null) {
        const page = document.createElement('div');
        page.className = 'story-page';
        page.dataset.page = index;

        // 解析中英文文本
        const { english, chinese } = this.parseText(text);

        // 创建页面内容
        page.innerHTML = `
            <div class="page-indicator">
                📖 第 ${index + 1} 页
            </div>
            
            <div class="story-image-container">
                <img src="${imageUrl}" alt="Story illustration ${index + 1}" class="story-image" loading="lazy">
            </div>
            
            <div class="story-text-container">
                ${audioUrl ? `<div class="play-button" data-audio="${audioUrl}" title="播放音频">
                    ▶️
                </div>` : ''}
                <div class="english-text">${this.escapeHtml(english)}</div>
                <div class="chinese-text">${this.escapeHtml(chinese)}</div>
            </div>
        `;

        return page;
    }

    /**
     * 解析文本，分离中英文
     * @param {string} text - 原始文本
     * @returns {Object} 包含英文和中文的对象
     */
    parseText(text) {
        // 匹配格式: "English text（中文文本）"
        const match = text.match(/^(.+?)（(.+?)）$/);
        
        if (match) {
            return {
                english: match[1].trim(),
                chinese: match[2].trim()
            };
        }

        // 如果格式不匹配，尝试其他分隔符
        const match2 = text.match(/^(.+?)\((.+?)\)$/);
        if (match2) {
            return {
                english: match2[1].trim(),
                chinese: match2[2].trim()
            };
        }

        // 如果都不匹配，返回原文
        return {
            english: text,
            chinese: ''
        };
    }

    /**
     * HTML转义，防止XSS
     * @param {string} text - 待转义的文本
     * @returns {string} 转义后的文本
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    /**
     * 更新单个页面
     * @param {number} index - 页面索引
     * @param {Object} data - 新的页面数据
     */
    updatePage(index, data) {
        const page = this.container.querySelector(`[data-page="${index}"]`);
        if (!page) return;

        const { english, chinese } = this.parseText(data.text);
        
        const englishElement = page.querySelector('.english-text');
        const chineseElement = page.querySelector('.chinese-text');
        const imageElement = page.querySelector('.story-image');

        if (englishElement) englishElement.textContent = english;
        if (chineseElement) chineseElement.textContent = chinese;
        if (imageElement && data.image) imageElement.src = data.image;
    }

    /**
     * 清空容器
     */
    clear() {
        this.container.innerHTML = '';
    }

    /**
     * 获取页面数量
     * @returns {number} 页面数量
     */
    getPageCount() {
        return this.container.querySelectorAll('.story-page').length;
    }

    /**
     * 获取指定页面元素
     * @param {number} index - 页面索引
     * @returns {HTMLElement|null} 页面元素
     */
    getPage(index) {
        return this.container.querySelector(`[data-page="${index}"]`);
    }
}

export default StoryRenderer;