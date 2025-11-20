// 导入Coze官方SDK
import { CozeAPI } from '@coze/api';

// API配置
const API_CONFIG = {
    token: (typeof process !== 'undefined' && process.env?.COZE_API_TOKEN) || 'your_coze_api_token_here',
    baseURL: (typeof process !== 'undefined' && process.env?.COZE_BASE_URL) || 'https://api.coze.cn',
    workflowId: (typeof process !== 'undefined' && process.env?.COZE_WORKFLOW_ID) || '7561291747888807978',
    timeout: 60000 // 60秒超时
};

// 验证Token配置
function validateToken() {
    if (!API_CONFIG.token || API_CONFIG.token === 'your_coze_api_token_here') {
        throw new Error('API认证失败：未配置有效的Coze API Token。请在环境变量中设置 COZE_API_TOKEN，或创建 .env 文件并配置 Token。');
    }
    return true;
}

// 创建Coze API客户端（延迟创建，确保环境变量已加载）
function getApiClient() {
    validateToken();
    return new CozeAPI({
        token: API_CONFIG.token,
        baseURL: API_CONFIG.baseURL
    });
}

/**
 * 生成故事
 * @param {string} input - 用户输入的故事主题
 * @returns {Promise<Object>} 故事数据
 */
export async function generateStory(input) {
    try {
        // 验证Token
        validateToken();
        
        // 获取API客户端
        const apiClient = getApiClient();
        
        console.log('🚀 开始调用Coze API生成故事...');
        console.log('📝 输入主题:', input);
        console.log('🔑 使用Token:', API_CONFIG.token.substring(0, 20) + '...');
        console.log('🆔 Workflow ID:', API_CONFIG.workflowId);
        console.log('🌐 Base URL:', API_CONFIG.baseURL);

        // 使用官方SDK调用workflow
        const res = await apiClient.workflows.runs.stream({
            workflow_id: API_CONFIG.workflowId,
            parameters: {
                input: input
            }
        });

        console.log('📡 API响应:', res);

        // 处理流式响应
        let result = null;
        let buffer = '';

        for await (const chunk of res) {
            console.log('📦 收到数据块:', chunk);
            
            // 处理流式数据
            if (chunk.event === 'Message' && chunk.data?.content) {
                const content = chunk.data.content;
                console.log('📄 收到内容:', content);
                
                // 解析JSON内容
                try {
                    const storyData = JSON.parse(content);
                    result = {
                        title: storyData.title,
                        story: storyData.story,
                        images: storyData.images,
                        voice: storyData.voice || [] // 如果没有音频，使用空数组
                    };
                    console.log('✅ 解析成功:', result);
                    break;
                } catch (parseError) {
                    console.error('❌ JSON解析失败:', parseError);
                    console.error('原始内容:', content);
                    throw new Error('故事数据格式错误');
                }
            } else if (chunk.event === 'Done' && chunk.data) {
                console.log('✅ 工作流完成，数据:', chunk.data);
                result = parseStoryContent(chunk.data);
                break;
            } else if (chunk.event === 'Error') {
                console.error('❌ API错误:', chunk);
                throw new Error(`API错误: ${chunk.error?.message || '未知错误'}`);
            }
        }

        if (!result) {
            throw new Error('未能从API获取有效的故事数据');
        }

        console.log('🎉 故事生成成功:', result);
        return result;

    } catch (error) {
        console.error('❌ API调用错误:', error);
        console.error('错误详情:', {
            message: error.message,
            code: error.code,
            status: error.status,
            response: error.response
        });
        
        // 检查是否是Token配置问题
        if (error.message?.includes('未配置有效的Coze API Token')) {
            throw error;
        }
        
        // 如果是认证错误，抛出明确的错误信息
        if (error.message?.includes('authentication') || 
            error.message?.includes('401') || 
            error.message?.includes('Unauthorized') ||
            error.message?.includes('logid') ||
            error.status === 401 ||
            (error.response && error.response.status === 401)) {
            console.warn('🔐 API认证失败，请检查Token是否有效');
            throw new Error('API认证失败：Token可能无效或已过期。请检查环境变量 COZE_API_TOKEN 是否正确配置。');
        }
        
        // 如果是403错误，可能是权限问题
        if (error.status === 403 || (error.response && error.response.status === 403)) {
            throw new Error('API权限不足：请检查Token是否有访问该Workflow的权限。');
        }
        
        // 如果是404错误，可能是Workflow ID错误
        if (error.status === 404 || (error.response && error.response.status === 404)) {
            throw new Error('Workflow不存在：请检查环境变量 COZE_WORKFLOW_ID 是否正确。');
        }
        
        throw error; // 其他错误直接抛出
    }
}

/**
 * 解析故事内容
 * @param {string} content - API返回的内容
 * @returns {Object} 解析后的故事数据
 */
function parseStoryContent(content) {
    try {
        // 尝试直接解析JSON
        if (typeof content === 'object') {
            return validateStoryData(content);
        }

        // 如果是字符串，尝试提取JSON
        if (typeof content === 'string') {
            // 查找JSON对象
            const jsonMatch = content.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                const data = JSON.parse(jsonMatch[0]);
                return validateStoryData(data);
            }
        }

        throw new Error('无法解析故事内容');
    } catch (error) {
        console.error('解析故事内容失败:', error);
        throw error;
    }
}

/**
 * 验证故事数据格式
 * @param {Object} data - 待验证的数据
 * @returns {Object} 验证后的数据
 */
function validateStoryData(data) {
    if (!data.title || !data.story || !data.images) {
        throw new Error('故事数据格式不完整');
    }

    if (!Array.isArray(data.story) || !Array.isArray(data.images)) {
        throw new Error('故事数据格式错误');
    }

    if (data.story.length === 0) {
        throw new Error('故事内容为空');
    }

    // 如果没有voice字段，添加空数组
    if (!data.voice) {
        data.voice = [];
    }

    return data;
}

/**
 * 获取模拟数据（用于测试）
 * @param {string} input - 用户输入
 * @returns {Object} 模拟的故事数据
 */
function getMockData(input) {
    return {
        title: `${input}的冒险故事`,
        images: [
            "https://images.unsplash.com/photo-1425082661705-1834bfd09dca?w=800",
            "https://images.unsplash.com/photo-1535930891776-0c2dfb7fda1a?w=800",
            "https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=800",
            "https://images.unsplash.com/photo-1518791841217-8f162f1e1131?w=800",
            "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800",
            "https://images.unsplash.com/photo-1573865526739-10c1dd7aa5c8?w=800",
            "https://images.unsplash.com/photo-1548681528-6a5c45b66b42?w=800",
            "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=800",
            "https://images.unsplash.com/photo-1574158622682-e40e69881006?w=800",
            "https://images.unsplash.com/photo-1517849845537-4d257902454a?w=800"
        ],
        story: [
            `A little ${input} lives on a farm.（一只小${input}住在农场里。）`,
            `He likes to play with balls.（他喜欢玩球。）`,
            `One day he lost his ball.（有一天他丢了球。）`,
            `He asked his friends for help.（他向朋友们求助。）`,
            `The duck found it in the pond.（鸭子在池塘里找到了它。）`,
            `The ${input} was very happy.（小${input}非常开心。）`,
            `He thanked his friend.（他感谢了他的朋友。）`,
            `Then they played together.（然后他们一起玩。）`,
            `They had a great time.（他们玩得很开心。）`,
            `The ${input} loves his farm.（小${input}爱他的农场。）`
        ],
        voice: [
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        ]
    };
}

export { API_CONFIG };