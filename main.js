// 故事渲染器将在HTML中通过script标签引入

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

// 滚动到故事区域并尽量让图片居中
function scrollToStorySection() {
    const target = elements.storyContainer || document.getElementById('storySection');
    if (target) {
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}

function centerCurrentImage() {
    if (!elements.storyPages) return;
    const img = elements.storyPages.querySelector('.story-image');
    if (!img) return;
    const center = () => img.scrollIntoView({ behavior: 'smooth', block: 'center' });
    if (img.complete) {
        center();
    } else {
        img.addEventListener('load', center, { once: true });
    }
}

// 初始化
function init() {
    console.log('🚀 初始化AI英文绘本应用...');
    
    // 获取DOM元素
    elements.storyInput = document.getElementById('storyInput');
    elements.generateBtn = document.getElementById('generateBtn');
    elements.storyContainer = document.getElementById('storySection'); // 修正为实际存在的ID
    elements.emptyState = null; // 当前HTML中不存在
    elements.loadingOverlay = document.getElementById('loadingOverlay');
    elements.storyTitle = document.getElementById('storyTitle');
    elements.storyPages = document.getElementById('storyContent'); // 修正为实际存在的ID
    elements.prevBtn = document.getElementById('prevBtn');
    elements.nextBtn = document.getElementById('nextBtn');
    elements.regenerateBtn = null; // 当前HTML中不存在
    elements.currentPageSpan = document.getElementById('pageIndicator'); // 修正为实际存在的ID
    elements.totalPagesSpan = null; // 当前HTML中不存在
    elements.audioPlayer = null; // 当前HTML中不存在，需要创建

    // 创建音频播放器元素
    if (!elements.audioPlayer) {
        const audioElement = document.createElement('audio');
        audioElement.id = 'audioPlayer';
        audioElement.style.display = 'none';
        document.body.appendChild(audioElement);
        elements.audioPlayer = audioElement;
        console.log('✅ 音频播放器元素已创建');
    }

    // 确保加载覆盖层在初始化时是隐藏的
    if (elements.loadingOverlay) {
        elements.loadingOverlay.classList.add('hidden');
        console.log('✅ 加载覆盖层已隐藏');
    } else {
        console.error('❌ 未找到加载覆盖层元素');
    }

    audioPlayer = elements.audioPlayer;
    
    // 调试：检查storyPages元素
    console.log('🔍 检查storyPages元素:', elements.storyPages);
    console.log('🔍 storyPages元素类型:', typeof elements.storyPages);
    console.log('🔍 storyPages是否为null:', elements.storyPages === null);
    
    if (elements.storyPages) {
        storyRenderer = new StoryRenderer(elements.storyPages);
        console.log('✅ storyRenderer创建成功:', storyRenderer);
    } else {
        console.error('❌ storyPages元素不存在，无法创建storyRenderer');
        // 尝试重新获取元素
        const retryElement = document.getElementById('storyContent');
        console.log('🔄 重新获取storyContent元素:', retryElement);
        if (retryElement) {
            storyRenderer = new StoryRenderer(retryElement);
            console.log('✅ 使用重新获取的元素创建storyRenderer成功');
        }
    }

    // 绑定事件
    bindEvents();

    // 添加装饰元素
    addDecorations();
    
    // 移动端优化
    optimizeForMobile();
    
    console.log('✅ 应用初始化完成');
}

// 绑定事件
function bindEvents() {
    // 生成故事按钮
    if (elements.generateBtn) {
        elements.generateBtn.addEventListener('click', handleGenerate);
    }

    // 输入框回车
    if (elements.storyInput) {
        elements.storyInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                handleGenerate();
            }
        });
    }

    // 导航按钮
    if (elements.prevBtn) {
        elements.prevBtn.addEventListener('click', handlePrevPage);
    }
    if (elements.nextBtn) {
        elements.nextBtn.addEventListener('click', handleNextPage);
    }

    // 重新生成按钮（如果存在）
    if (elements.regenerateBtn) {
        elements.regenerateBtn.addEventListener('click', handleRegenerate);
    }

    // 音频播放结束事件
    if (audioPlayer) {
        audioPlayer.addEventListener('ended', handleAudioEnded);
    }

    // 使用事件委托处理播放按钮点击
    if (elements.storyPages) {
        elements.storyPages.addEventListener('click', (e) => {
        const playButton = e.target.closest('.play-button');
        if (playButton) {
            const audioUrl = playButton.dataset.audio;
            if (audioUrl) {
                console.log('🎵 播放按钮被点击，音频URL:', audioUrl);
                // 直接播放音频
                if (!audioPlayer.paused && audioPlayer.src === audioUrl) {
                    console.log('⏸️ 暂停音频');
                    audioPlayer.pause();
                    playButton.classList.remove('playing');
                    playButton.innerHTML = '▶️';
                } else {
                    console.log('▶️ 开始播放音频');
                    stopAudio();
                    audioPlayer.src = audioUrl;
                    audioPlayer.play().catch(error => {
                        console.error('❌ 音频播放失败:', error);
                        alert('音频播放失败，请重试！');
                    });
                    playButton.classList.add('playing');
                    playButton.innerHTML = '⏸️';
                }
            } else {
                console.warn('⚠️ 播放按钮没有音频URL');
            }
        }
        });
    }
}

// 处理生成故事
async function handleGenerate() {
    const input = elements.storyInput ? elements.storyInput.value.trim() : '';
    
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
            alert('很抱歉，今日Token已经消耗完，请查看我的绘本体验历史作品！');
        }
    }
}

// 处理重新生成
function handleRegenerate() {
    const input = elements.storyInput ? elements.storyInput.value.trim() : '';
    if (input) {
        handleGenerate();
    } else {
        if (elements.storyContainer) {
            elements.storyContainer.classList.add('hidden');
        }
        if (elements.emptyState) {
            elements.emptyState.classList.remove('hidden');
        }
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
    if (elements.emptyState) {
        elements.emptyState.classList.add('hidden');
    }
    if (elements.storyContainer) {
        elements.storyContainer.classList.remove('hidden');
        elements.storyContainer.classList.add('show'); // 添加show类来显示故事区域
        console.log('✅ 故事容器已显示，添加了show类');
    }

    // 设置标题
    if (elements.storyTitle) {
        elements.storyTitle.textContent = data.title || '我的故事';
    }

    // 渲染故事页面
    console.log('🎨 开始渲染故事页面...');
    console.log('📊 storyRenderer对象:', storyRenderer);
    console.log('📊 storyRenderer.container:', storyRenderer ? storyRenderer.container : 'undefined');
    if (storyRenderer) {
        storyRenderer.render(data);
        console.log('✅ 故事页面渲染完成');
    } else {
        console.error('❌ storyRenderer对象不存在');
    }

    // 更新页面显示
    updatePageDisplay();

    // 显示装饰元素
    showDecorations();

        // 渲染完成后滚动到故事区域并让图片居中
        scrollToStorySection();
        centerCurrentImage();
}

// 显示指定页面
function showPage(pageIndex) {
    if (!currentStoryData) return;

    const totalPages = currentStoryData.story.length;
    
    // 边界检查
    if (pageIndex < 0 || pageIndex >= totalPages) return;

    currentPage = pageIndex;

    // 隐藏所有页面
    if (elements.storyPages) {
        const allPages = elements.storyPages.querySelectorAll('.story-page');
        allPages.forEach(page => page.classList.remove('active'));

        // 显示当前页面
        const currentPageElement = allPages[pageIndex];
        if (currentPageElement) {
            currentPageElement.classList.add('active');
        }
    }

    // 更新页码显示
    if (elements.currentPageSpan) {
        elements.currentPageSpan.textContent = pageIndex + 1;
    }

    // 更新按钮状态
    if (elements.prevBtn) {
        elements.prevBtn.disabled = pageIndex === 0;
    }
    if (elements.nextBtn) {
        elements.nextBtn.disabled = pageIndex === totalPages - 1;
    }

    // 停止当前音频
    stopAudio();

    // 定位到故事区域并让图片居中
    scrollToStorySection();
    centerCurrentImage();
}

// 处理上一页
function handlePrevPage() {
    console.log('⬅️ 上一页按钮被点击');
    if (storyRenderer && storyRenderer.prevPage()) {
        currentPage = storyRenderer.getCurrentPage();
        updatePageDisplay();
        centerCurrentImage();
    }
}

// 处理下一页
function handleNextPage() {
    console.log('➡️ 下一页按钮被点击');
    if (storyRenderer && storyRenderer.nextPage()) {
        currentPage = storyRenderer.getCurrentPage();
        updatePageDisplay();
        centerCurrentImage();
    }
}

// 更新页面显示
function updatePageDisplay() {
    if (!storyRenderer) return;
    
    const totalPages = storyRenderer.getTotalPages();
    const currentPageIndex = storyRenderer.getCurrentPage();
    
    // 更新页码显示
    if (elements.currentPageSpan) {
        elements.currentPageSpan.textContent = `第 ${currentPageIndex + 1} 页`;
    }
    
    // 更新按钮状态
    if (elements.prevBtn) {
        elements.prevBtn.disabled = currentPageIndex === 0;
    }
    if (elements.nextBtn) {
        elements.nextBtn.disabled = currentPageIndex === totalPages - 1;
    }
    
    // 停止当前音频
    stopAudio();
    
    // 定位到故事区域
    scrollToStorySection();
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
            playButton.innerHTML = '▶️';
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
        playButton.innerHTML = '⏸️';
    }
}

// 停止音频
function stopAudio() {
    if (!audioPlayer.paused) {
        audioPlayer.pause();
    }
    audioPlayer.currentTime = 0;

    // 重置所有播放按钮
    if (elements.storyPages) {
        const allPlayButtons = elements.storyPages.querySelectorAll('.play-button');
        allPlayButtons.forEach(btn => {
            btn.classList.remove('playing');
            btn.innerHTML = '▶️';
        });
    }
}

// 音频播放结束处理
function handleAudioEnded() {
    stopAudio();
}

// 显示/隐藏加载动画
function showLoading(show) {
    console.log(`🔄 设置加载状态: ${show ? '显示' : '隐藏'}`);
    if (elements.loadingOverlay) {
        if (show) {
            elements.loadingOverlay.classList.remove('hidden');
            console.log('✅ 加载覆盖层已显示');
        } else {
            elements.loadingOverlay.classList.add('hidden');
            console.log('✅ 加载覆盖层已隐藏');
        }
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

// 检查localStorage中的记录ID
function checkForRecordId() {
    const recordId = localStorage.getItem('currentRecordId');
    
    console.log('🔍 检查localStorage中的记录ID:', recordId);
    
    if (recordId) {
        console.log('🔍 检测到记录ID:', recordId);
        loadRecordById(recordId);
        // 清除localStorage中的记录ID，避免重复加载
        localStorage.removeItem('currentRecordId');
        console.log('🧹 已清除localStorage中的记录ID');
    } else {
        console.log('ℹ️ 没有检测到记录ID，显示默认页面');
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
        console.log('📦 API响应:', result);
        
        if (result.success) {
            const record = result.data;
            console.log('✅ 历史记录加载成功:', record.title);
            console.log('📋 记录数据结构:', record);
            
            // 设置输入框的值
            if (elements.storyInput) {
                elements.storyInput.value = record.input || record.inputPrompt || '';
                console.log('📝 设置输入框值:', elements.storyInput.value);
            }
            
            // 显示故事
            currentStoryData = {
                title: record.title,
                story: record.story,
                images: record.images,
                voice: record.voice
            };
            currentPage = 0;
            
            console.log('📚 准备显示故事数据:', currentStoryData);
            displayStory(currentStoryData);
            showNotification(`已加载历史绘本: ${record.title}`, 'success');
        // 查看故事后定位到展示区域并居中图片
        scrollToStorySection();
        centerCurrentImage();
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

// 移动端优化
function optimizeForMobile() {
    // 检测是否为移动设备
    const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    
    if (isMobile) {
        console.log('📱 检测到移动设备，应用移动端优化');
        
        // 防止双击缩放
        let lastTouchEnd = 0;
        document.addEventListener('touchend', function (event) {
            const now = (new Date()).getTime();
            if (now - lastTouchEnd <= 300) {
                event.preventDefault();
            }
            lastTouchEnd = now;
        }, false);
        
        // 优化触摸反馈
        const touchElements = document.querySelectorAll('.generate-btn, .nav-btn, .play-button, .action-btn');
        touchElements.forEach(element => {
            element.addEventListener('touchstart', function() {
                this.style.transform = 'scale(0.95)';
            });
            
            element.addEventListener('touchend', function() {
                this.style.transform = '';
            });
        });
        
        // 优化输入框
        if (elements.storyInput) {
            elements.storyInput.addEventListener('focus', function() {
                // 延迟滚动，确保键盘弹出后页面正确显示
                setTimeout(() => {
                    this.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }, 300);
            });
        }
        
        // 优化音频播放（移动端需要用户交互才能播放）
        if (audioPlayer) {
            audioPlayer.addEventListener('canplaythrough', function() {
                console.log('🎵 音频准备就绪');
            });
            
            audioPlayer.addEventListener('error', function(e) {
                console.error('❌ 音频加载失败:', e);
            });
        }
        
        // 添加触摸手势支持
        let startX = 0;
        let startY = 0;
        
        document.addEventListener('touchstart', function(e) {
            startX = e.touches[0].clientX;
            startY = e.touches[0].clientY;
        });
        
        document.addEventListener('touchend', function(e) {
            if (!startX || !startY) return;
            
            const endX = e.changedTouches[0].clientX;
            const endY = e.changedTouches[0].clientY;
            
            const diffX = startX - endX;
            const diffY = startY - endY;
            
            // 水平滑动切换页面
            if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 50) {
                if (diffX > 0 && elements.nextBtn && !elements.nextBtn.disabled) {
                    // 向左滑动，下一页
                    handleNextPage();
                } else if (diffX < 0 && elements.prevBtn && !elements.prevBtn.disabled) {
                    // 向右滑动，上一页
                    handlePrevPage();
                }
            }
            
            startX = 0;
            startY = 0;
        });
        
        console.log('✅ 移动端优化完成');
    }
}

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', () => {
    init();
    checkForRecordId();
});

// 导出变量供其他脚本使用
window.currentStoryData = currentStoryData;
window.currentPage = currentPage;