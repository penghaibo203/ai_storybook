/**
 * 故事渲染器类
 * 负责将故事数据渲染成HTML元素
 */
class StoryRenderer {
    constructor(container) {
        this.container = container;
        this.currentPage = 0;
        this.storyData = null;
        this.initialized = false;
        this.refs = {
            pageIndicator: null,
            image: null,
            playButton: null,
            english: null,
            chinese: null
        };
    }

    /**
     * 渲染完整故事
     * @param {Object} data - 故事数据
     */
    render(data) {
        console.log('🎨 StoryRenderer.render 被调用');
        console.log('📊 传入的数据:', data);
        console.log('📊 container元素:', this.container);
        
        if (!data || !data.story || !data.images) {
            console.error('❌ 故事数据不完整:', data);
            return;
        }

        // 保存故事数据
        this.storyData = data;
        this.currentPage = 0;
        console.log('📊 保存的故事数据:', this.storyData);

        // 若未初始化，创建一次静态骨架
        if (!this.initialized) {
            this.buildPageSkeleton();
            this.initialized = true;
        }

        // 更新到第一页内容
        this.updatePageContent();
        console.log('✅ 第一页渲染完成（无整页刷新，仅内容切换）');
    }

    /**
     * 渲染当前页面
     */
    renderCurrentPage() {
        // 兼容旧接口：改为仅更新内容
        this.updatePageContent();
    }

    /**
     * 创建一次性的页面骨架（只创建DOM结构，不含具体内容）
     */
    buildPageSkeleton() {
        this.container.innerHTML = '';
        const wrapper = document.createElement('div');
        wrapper.className = 'story-page';
        wrapper.dataset.page = '0';

        wrapper.innerHTML = `
            <div class="page-indicator">📖 第 1 页</div>
            <div class="story-image-container">
                <img class="story-image" alt="Story illustration" loading="lazy">
            </div>
            <div class="story-text-container">
                <div class="play-button" title="播放音频">▶️</div>
                <div class="english-text"></div>
                <div class="chinese-text"></div>
            </div>
        `;

        this.container.appendChild(wrapper);

        // 保存引用，后续只更新内容
        this.refs.pageIndicator = wrapper.querySelector('.page-indicator');
        this.refs.image = wrapper.querySelector('.story-image');
        this.refs.playButton = wrapper.querySelector('.play-button');
        this.refs.english = wrapper.querySelector('.english-text');
        this.refs.chinese = wrapper.querySelector('.chinese-text');
    }

    /**
     * 根据当前页数据更新DOM内容（不重建结构）
     */
    updatePageContent() {
        if (!this.storyData) return;

        const { story, images, voice } = this.storyData;
        const text = story[this.currentPage];
        const imageUrl = images[this.currentPage];
        const audioUrl = voice && voice[this.currentPage];

        const { english, chinese } = this.parseText(text);

        if (this.refs.image) {
            this.refs.image.src = imageUrl || '';
            this.refs.image.alt = `Story illustration ${this.currentPage + 1}`;
        }

        if (this.refs.english) {
            this.refs.english.textContent = english || '';
        }
        if (this.refs.chinese) {
            this.refs.chinese.textContent = chinese || '';
        }

        if (this.refs.playButton) {
            if (audioUrl) {
                this.refs.playButton.dataset.audio = audioUrl;
                this.refs.playButton.style.display = '';
            } else {
                // 无音频则清空data并隐藏按钮（不移除，保持结构稳定）
                delete this.refs.playButton.dataset.audio;
                this.refs.playButton.style.display = 'none';
            }
        }

        if (this.refs.pageIndicator) {
            this.refs.pageIndicator.textContent = `📖 第 ${this.currentPage + 1} 页`;
        }
    }

    /**
     * 显示下一页
     */
    nextPage() {
        if (!this.storyData) return false;
        
        if (this.currentPage < this.storyData.story.length - 1) {
            this.currentPage++;
            this.updatePageContent();
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
            this.updatePageContent();
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
            this.updatePageContent();
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

// 将StoryRenderer类暴露到全局作用域
window.StoryRenderer = StoryRenderer;