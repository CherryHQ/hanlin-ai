<h1 align="center">
  <a href="https://github.com/CherryHQ/AI_Hanlin">
    <img src="cherry_icon.png" width="90" height="90" alt="Cherry" style="margin-right: 25px; vertical-align: middle;" />
    <img src="logo_3_0.png" width="120" height="120" alt="AI翰林院" style="vertical-align: middle;" /><br>
    <span style="color: #FF6B6B;">Cherry Studio</span> · <span style="color: #4A90E2;">AI翰林院</span>
  </a>
</h1>

<p align="center">
  <strong>开启智能生活的次世代AI移动工作台</strong><br>
  <em>Next-generation AI mobile workstation for an intelligent lifestyle.</em>
</p>

<div align="center">

[![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)](https://developer.apple.com/ios/) [![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org) [![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

<div align="center">

[![SwiftData](https://img.shields.io/badge/SwiftData-Support-purple.svg)](https://developer.apple.com/xcode/swiftdata/) [![CloudKit](https://img.shields.io/badge/CloudKit-Sync-blue.svg)](https://developer.apple.com/icloud/cloudkit/)

</div>

## ✨ 特性

### 🤖 AI模型集成

- **20+ AI服务商支持**: 通义千问(Qwen)、智谱AI(GLM)、豆包(Doubao)、DeepSeek、百度文心(ERNIE)、腾讯混元、零一万物(Yi)、月之暗面(Kimi)、阶跃星辰(Step)、讯飞星火(Spark)、MiniMax、SiliconCloud、OpenAI、Claude、Google Gemini等
- **实时流式响应**: 支持流式对话和工具调用的实时交互体验，提供类似ChatGPT的用户体验
- **本地模型支持**: 集成LLM.swift框架，支持本地AI模型推理和部署


### 🔧 智能工具生态

- **🔍 智能搜索引擎**: 支持7大搜索引擎 (智谱AI、博查AI、EXA、Tavily、LangSearch、BRAVE、Perplexity)
- **🌐 网页内容提取**: 基于SwiftSoup的智能网页解析，自动提取标题、正文内容和图标，支持批量URL处理
- **🗺️ 地图定位服务**: 集成CoreLocation和MapKit，支持实时定位、地址解析、位置搜索和导航功能
- **🌤️ 多源天气服务**: 支持和风天气(QWeather)和OpenWeather API，提供实时天气、预报和气象数据
- **📅 系统日历集成**: 完整的EventKit集成，支持日历事件创建、查询、提醒事项管理和智能时间筛选
- **💪 健康数据分析**: HealthKit深度集成，支持步数、距离、卡路里、营养摄入等多维度健康数据读写
- **💻 代码执行服务**: 基于Piston API的在线代码执行环境，支持Python 3.10，具备Jupyter风格的智能输出
- **🎨 智能画布系统**: 支持多类型画布创建、版本历史管理、SwiftData持久化存储和协作编辑
- **🔊 多模式语音合成**: 集成系统TTS和外部API，支持多语言、多音色的语音合成，支持实时播放控制
- **🧠 长期记忆系统**: 智能记忆存储、检索和更新，支持关键词搜索和个性化对话上下文保持


### 📚 知识库管理

- **高级RAG检索系统**: 基于向量相似度的检索增强生成，支持多种嵌入模型(BAAI/bge-m3等)，智能匹配最相关知识片段
- **全格式文档解析**: 深度支持PDF(PDFKit)、Word/PPT(ZIPFoundation+XML解析)、Excel(CoreXLSX)、Markdown、纯文本等格式的智能内容提取
- **智能知识分块**: 自动将长文档切分为语义完整的知识片段，每个片段独立向量化存储，支持高效相似度检索
- **向量数据管理**: 自动生成1024维向量嵌入，支持批量向量化处理和实时检索优化


### 👁️ 视觉分析

- **专业相机系统**: 基于AVCaptureSession的相机引擎，支持三摄、双摄、单摄自适应配置，0.5x-15x智能变焦和闪光灯控制
- **多模态AI图像理解**: 集成20+多模态大模型(GLM4V、Qwen-VL、GPT-4V等)，支持图像内容分析、OCR文字提取、场景理解和多轮视觉对话
- **智能图片处理**: 支持相机拍摄、相册选择、图片保存，PHPickerViewController多选支持，实时图像预处理和优化
- **流式视觉交互**: 实时流式响应的视觉问答体验，支持上下文记忆的连续对话，提供类似苹果视觉的交互体验
- **跨设备图片同步**: 基于SwiftData的图片元数据管理，支持多设备间的视觉分析历史同步


## 🛠️ 技术栈

- **开发语言**: Swift 5.9+
- **UI框架**: SwiftUI
- **数据存储**: SwiftData + CloudKit
- **网络请求**: URLSession + Async/Await
- **依赖管理**: Swift Package Manager


### 主要依赖

```swift
// 本地AI库
.package(url: "https://github.com/otabuzzman/LLM.swift", from: "1.8.0")

// 文档与对话显示
.package(url: "https://github.com/CoreOffice/CoreXLSX", from: "0.14.2")
.package(url: "https://github.com/blackhole89/LaTeXSwiftUI", from: "1.5.0")
.package(url: "https://github.com/gonzalezreal/MarkdownUI", from: "2.0.0")

// 文本和UI
.package(url: "https://github.com/RichTextFormat/RichTextKit", from: "0.9.0")
.package(url: "https://github.com/scinfu/SwiftSoup", from: "2.6.0")

// 工具库
.package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.0")
```


## 🚀 快速开始

### 环境要求
- iOS 18.0+
- Xcode 15.0+
- Swift 5.9+
- macOS 14.0+ (for development)

### 安装步骤

1. **克隆项目 Clone the repository**
   ```bash
   git clone https://github.com/CherryHQ/hanlin-ai.git
   cd AI_HLY
   ```

2. **打开项目 Open the project**
   ```bash
   open AI_HLY.xcodeproj
   ```

3. **配置签名 Configure signing**
   - 在Xcode中选择你的开发团队
   - 修改Bundle Identifier为唯一值

4. **运行项目 Run the project**
   - 选择目标设备或模拟器
   - 按 `Cmd + R` 运行项目

### API配置

1. 运行应用并进入"设置"页面
2. 在"API密钥管理"中配置你需要的AI服务商API密钥：
   - OpenAI API Key
   - Claude API Key
   - Google Gemini API Key
   - 其他服务商密钥...

3. 在"工具配置"中设置外部服务API：
   - 搜索引擎API密钥
   - 地图服务密钥
   - 天气服务密钥

## 📖 使用指南

### 基础对话
1. 点击"列表"标签页
2. 点击"+"按钮创建新对话
3. 选择AI模型和配置参数
4. 开始对话

### 视觉分析
1. 点击"视觉"标签页
2. 使用相机拍摄包含文字的图像
3. 应用会自动识别并提取文字
4. 可以进一步对图像进行AI分析

### 知识库管理
1. 点击"知识库"标签页
2. 创建新的知识库
3. 上传文档或手动输入知识
4. 在对话中引用知识库进行问答

## 🏗️ 项目架构

### 目录结构
```
AI_HLY/
├── AI_HLY/                    # 主应用目录
│   ├── Views/                 # 视图组件
│   │   ├── MainTabView.swift
│   │   ├── ChatView.swift
│   │   ├── VisionView.swift
│   │   └── ...
│   ├── Models/                # 数据模型
│   │   ├── ChatRecords.swift
│   │   ├── AllModels.swift
│   │   └── ...
│   ├── Services/              # 服务层
│   │   ├── APIServices/
│   │   ├── ChatServices/
│   │   └── ...
│   └── Resources/             # 资源文件
├── AI_HLY.xcodeproj/         # Xcode项目文件
└── README.md
```

### 核心组件

1. **应用入口** (`AI_HLY.swift`)
   - SwiftData模型容器初始化
   - CloudKit配置
   - 深度链接处理

2. **主界面** (`MainTabView.swift`)
   - 五个标签页导航
   - 深度链接路由

3. **数据层** (`Models/`)
   - SwiftData模型定义
   - CloudKit集成
   - 数据持久化

4. **服务层** (`Services/`)
   - API通信管理
   - 工具系统集成
   - 外部服务集成

## 📄 许可证

本项目采用 MIT 许可证。查看 [LICENSE](LICENSE) 文件了解详细信息。

## 🙏 致谢

- 感谢所有AI服务提供商的模型支持
- 感谢开源社区提供的优秀库和工具
- 感谢所有贡献者的努力

---

<div align="center">

**如果这个项目对你有帮助，请给它一个 ⭐️！**  
*If this project helps you, please give it a ⭐️!*

Made with ❤️ by the Hylic.AI team

</div>