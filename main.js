// 导入故事渲染器
import { StoryRenderer } from './storyRenderer.js';

// 全局状态
let currentStoryData = null;
let currentPage = 0;
let audioPlayer = null;
let storyRenderer = null;

// DOM元素
const elements = {
    storyInput: null,
    generateBtn: null,
    storyContainer: null,
    emptyState: null,
    loadingOverlay: null,
    storyTitle: null,
    storyPages: null,
    prevBtn: null,
    nextBtn: null,
    regenerateBtn: null,
    currentPageSpan: null,
    totalPagesSpan: null,
    audioPlayer: null
};

// 初始化
function init() {
    console.log('🚀 初始化AI英文绘本应用...');
    
    // 获取DOM元素
    elements.storyInput = document.getElementById('storyInput');
    elements.generateBtn = document.getElementById('generateBtn');
    elements.storyContainer = document.getElementById('storyContainer');
    elements.emptyState = document.getElementById('emptyState');
    elements.loadingOverlay = document.getElementById('loadingOverlay');
    elements.storyTitle = document.getElementById('storyTitle');
    elements.storyPages = document.getElementById('storyPages');
    elements.prevBtn = document.getElementById('prevBtn');
    elements.nextBtn = document.getElementById('nextBtn');
    elements.regenerateBtn = document.getElementById('regenerateBtn');
    elements.currentPageSpan = document.getElementById('currentPage');
    elements.totalPagesSpan = document.getElementById('totalPages');
    elements.audioPlayer = document.getElementById('audioPlayer');

    // 确保加载覆盖层在初始化时是隐藏的
    if (elements.loadingOverlay) {
        elements.loadingOverlay.classList.add('hidden');
        console.log('✅ 加载覆盖层已隐藏');
    } else {
        console.error('❌ 未找到加载覆盖层元素');
    }

    audioPlayer = elements.audioPlayer;
    storyRenderer = new StoryRenderer(elements.storyPages);

    // 绑定事件
    bindEvents();

    // 添加装饰元素
    addDecorations();
    
    console.log('✅ 应用初始化完成');
}

// 绑定事件
function bindEvents() {
    // 生成故事按钮
    elements.generateBtn.addEventListener('click', handleGenerate);

    // 输入框回车
    elements.storyInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            handleGenerate();
        }
    });

    // 导航按钮
    elements.prevBtn.addEventListener('click', handlePrevPage);
    elements.nextBtn.addEventListener('click', handleNextPage);

    // 重新生成按钮
    elements.regenerateBtn.addEventListener('click', handleRegenerate);

    // 音频播放结束事件
    audioPlayer.addEventListener('ended', handleAudioEnded);

    // 使用事件委托处理播放按钮点击
    elements.storyPages.addEventListener('click', (e) => {
        const playButton = e.target.closest('.play-button');
        if (playButton) {
            const audioUrl = playButton.dataset.audio;
            if (audioUrl) {
                // 直接播放音频
                if (!audioPlayer.paused && audioPlayer.src === audioUrl) {
                    audioPlayer.pause();
                    playButton.classList.remove('playing');
                    playButton.textContent = '▶️';
                } else {
                    stopAudio();
                    audioPlayer.src = audioUrl;
                    audioPlayer.play().catch(error => {
                        console.error('音频播放失败:', error);
                        alert('音频播放失败，请重试！');
                    });
                    playButton.classList.add('playing');
                    playButton.textContent = '⏸️';
                }
            }
        }
    });
}

// 处理生成故事
async function handleGenerate() {
    const input = elements.storyInput.value.trim();
    
    if (!input) {
        alert('请输入故事主题！');
        return;
    }

    showLoading(true);

    try {
        // 使用后端API
        const response = await fetch('/api/generate-story', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ input })
        });

        const result = await response.json();
        
        if (!result.success) {
            throw new Error(result.error || '生成故事失败');
        }

        const data = result.data;
        currentStoryData = data;
        currentPage = 0;
        displayStory(data);
        showLoading(false);
        
        // 如果使用的是模拟数据，给用户提示
        if (data.title.includes('的冒险故事')) {
            showNotification('当前使用演示数据展示效果。如需使用真实AI生成，请检查API配置。', 'info');
        }
    } catch (error) {
        console.error('生成故事失败:', error);
        showLoading(false);
        hideDecorations(); // 生成失败时隐藏装饰元素
        
        // 更友好的错误提示
        if (error.message.includes('认证失败') || error.message.includes('401')) {
            alert('⚠️ API认证失败\n\n当前将使用演示数据展示页面效果。\n\n如需使用真实AI生成功能，请联系管理员更新API Token。');
        } else {
            alert('生成故事失败，请重试！\n\n错误信息：' + error.message);
        }
    }
}

// 处理重新生成
function handleRegenerate() {
    const input = elements.storyInput.value.trim();
    if (input) {
        handleGenerate();
    } else {
        elements.storyContainer.classList.add('hidden');
        elements.emptyState.classList.remove('hidden');
    }
}

// 显示故事
function displayStory(data) {
    if (!data || !data.story || !data.images) {
        alert('故事数据格式错误！');
        hideDecorations(); // 隐藏装饰元素
        return;
    }

    // 隐藏空状态，显示故事容器
    elements.emptyState.classList.add('hidden');
    elements.storyContainer.classList.remove('hidden');

    // 设置标题
    elements.storyTitle.textContent = data.title || '我的故事';

    // 渲染故事页面
    storyRenderer.render(data);

    // 更新页面显示
    updatePageDisplay();

    // 显示装饰元素
    showDecorations();
}

// 显示指定页面
function showPage(pageIndex) {
    if (!currentStoryData) return;

    const totalPages = currentStoryData.story.length;
    
    // 边界检查
    if (pageIndex < 0 || pageIndex >= totalPages) return;

    currentPage = pageIndex;

    // 隐藏所有页面
    const allPages = elements.storyPages.querySelectorAll('.story-page');
    allPages.forEach(page => page.classList.remove('active'));

    // 显示当前页面
    const currentPageElement = allPages[pageIndex];
    if (currentPageElement) {
        currentPageElement.classList.add('active');
    }

    // 更新页码显示
    elements.currentPageSpan.textContent = pageIndex + 1;

    // 更新按钮状态
    elements.prevBtn.disabled = pageIndex === 0;
    elements.nextBtn.disabled = pageIndex === totalPages - 1;

    // 停止当前音频
    stopAudio();

    // 滚动到顶部
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// 处理上一页
function handlePrevPage() {
    console.log('⬅️ 上一页按钮被点击');
    if (storyRenderer && storyRenderer.prevPage()) {
        currentPage = storyRenderer.getCurrentPage();
        updatePageDisplay();
    }
}

// 处理下一页
function handleNextPage() {
    console.log('➡️ 下一页按钮被点击');
    if (storyRenderer && storyRenderer.nextPage()) {
        currentPage = storyRenderer.getCurrentPage();
        updatePageDisplay();
    }
}

// 更新页面显示
function updatePageDisplay() {
    if (!storyRenderer) return;
    
    const totalPages = storyRenderer.getTotalPages();
    const currentPageIndex = storyRenderer.getCurrentPage();
    
    // 更新页码显示
    elements.currentPageSpan.textContent = currentPageIndex + 1;
    elements.totalPagesSpan.textContent = totalPages;
    
    // 更新按钮状态
    elements.prevBtn.disabled = currentPageIndex === 0;
    elements.nextBtn.disabled = currentPageIndex === totalPages - 1;
    
    // 停止当前音频
    stopAudio();
    
    // 滚动到顶部
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// 导航页面（保留兼容性）
function navigatePage(direction) {
    if (direction === -1) {
        handlePrevPage();
    } else if (direction === 1) {
        handleNextPage();
    }
}

// 处理音频播放
function handlePlayAudio(pageIndex) {
    if (!currentStoryData || !currentStoryData.voice) return;

    const audioUrl = currentStoryData.voice[pageIndex];
    if (!audioUrl) return;

    const playButton = elements.storyPages.querySelector(`[data-audio="${audioUrl}"]`);
    
    // 如果正在播放当前音频，则暂停
    if (!audioPlayer.paused && audioPlayer.src === audioUrl) {
        audioPlayer.pause();
        if (playButton) {
            playButton.classList.remove('playing');
            playButton.textContent = '▶️';
        }
        return;
    }

    // 停止之前的音频
    stopAudio();

    // 播放新音频
    audioPlayer.src = audioUrl;
    audioPlayer.play().catch(error => {
        console.error('音频播放失败:', error);
        alert('音频播放失败，请重试！');
    });

    // 更新按钮状态
    if (playButton) {
        playButton.classList.add('playing');
        playButton.textContent = '⏸️';
    }
}

// 停止音频
function stopAudio() {
    if (!audioPlayer.paused) {
        audioPlayer.pause();
    }
    audioPlayer.currentTime = 0;

    // 重置所有播放按钮
    const allPlayButtons = elements.storyPages.querySelectorAll('.play-button');
    allPlayButtons.forEach(btn => {
        btn.classList.remove('playing');
        btn.textContent = '▶️';
    });
}

// 音频播放结束处理
function handleAudioEnded() {
    stopAudio();
}

// 显示/隐藏加载动画
function showLoading(show) {
    console.log(`🔄 设置加载状态: ${show ? '显示' : '隐藏'}`);
    if (show) {
        elements.loadingOverlay.classList.remove('hidden');
        console.log('✅ 加载覆盖层已显示');
    } else {
        elements.loadingOverlay.classList.add('hidden');
        console.log('✅ 加载覆盖层已隐藏');
    }
}

// 显示通知消息
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 z-50 px-6 py-4 rounded-lg shadow-lg transform transition-all duration-300 ${
        type === 'info' ? 'bg-blue-500' : 
        type === 'success' ? 'bg-green-500' : 
        type === 'warning' ? 'bg-yellow-500' : 
        'bg-red-500'
    } text-white max-w-md`;
    
    notification.innerHTML = `
        <div class="flex items-start gap-3">
            <i class="fas fa-info-circle text-xl"></i>
            <div class="flex-1">${message}</div>
            <button class="text-white hover:text-gray-200" onclick="this.parentElement.parentElement.remove()">
                <i class="fas fa-times"></i>
            </button>
        </div>
    `;
    
    document.body.appendChild(notification);
    
    // 3秒后自动消失
    setTimeout(() => {
        notification.style.opacity = '0';
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => notification.remove(), 300);
    }, 5000);
}

// 添加装饰元素
function addDecorations() {
    // 检查是否已经存在装饰元素
    if (document.querySelector('.star-decoration')) {
        return;
    }

    const decorations = ['⭐', '✨', '🌟', '💫', '🎨', '🎭', '🎪', '🎡'];
    const container = document.createElement('div');
    container.className = 'star-decoration';
    container.style.display = 'none'; // 初始隐藏

    for (let i = 0; i < 15; i++) {
        const star = document.createElement('div');
        star.className = 'star';
        star.textContent = decorations[Math.floor(Math.random() * decorations.length)];
        star.style.left = Math.random() * 100 + '%';
        star.style.top = Math.random() * 100 + '%';
        star.style.animationDelay = Math.random() * 3 + 's';
        container.appendChild(star);
    }

    document.body.appendChild(container);
}

// 显示装饰元素
function showDecorations() {
    const decorationContainer = document.querySelector('.star-decoration');
    if (decorationContainer) {
        decorationContainer.style.display = 'block';
        console.log('✨ 装饰元素已显示');
    }
}

// 隐藏装饰元素
function hideDecorations() {
    const decorationContainer = document.querySelector('.star-decoration');
    if (decorationContainer) {
        decorationContainer.style.display = 'none';
        console.log('✨ 装饰元素已隐藏');
    }
}

// 检查URL参数中的记录ID
function checkForRecordId() {
    const urlParams = new URLSearchParams(window.location.search);
    const recordId = urlParams.get('record');
    
    if (recordId) {
        console.log('🔍 检测到记录ID:', recordId);
        loadRecordById(recordId);
    }
}

// 根据ID加载历史记录
async function loadRecordById(recordId) {
    try {
        showLoading(true);
        console.log('📖 正在加载历史记录:', recordId);
        
        const response = await fetch(`/api/records/${recordId}`);
        if (!response.ok) {
            throw new Error('记录不存在');
        }
        
        const result = await response.json();
        if (result.success) {
            const record = result.data;
            console.log('✅ 历史记录加载成功:', record.title);
            
            // 设置输入框的值
            elements.storyInput.value = record.input;
            
            // 显示故事
            currentStoryData = {
                title: record.title,
                story: record.story,
                images: record.images,
                voice: record.voice
            };
            currentPage = 0;
            
            displayStory(currentStoryData);
            showNotification(`已加载历史绘本: ${record.title}`, 'success');
            
            // 清除URL参数
            window.history.replaceState({}, document.title, window.location.pathname);
        } else {
            throw new Error(result.error || '加载记录失败');
        }
    } catch (error) {
        console.error('❌ 加载历史记录失败:', error);
        showNotification(`加载历史记录失败: ${error.message}`, 'error');
        hideDecorations(); // 加载失败时隐藏装饰元素
    } finally {
        showLoading(false);
    }
}

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', () => {
    init();
    checkForRecordId();
});

export { currentStoryData, currentPage };