# iOS Tweak AI Generator

一款面向 iOS 逆向工程与越狱开发者的 AI 辅助工具，结合强大的 LLM (如 Gemini/OpenAI)，能够依据自然语言描述为你自动生成 `Logos (.xm)` 源代码以及相关的 `Makefile`、`control` 配置文件。本项目特别添加了与 GitHub Actions 无缝集成的能力，支持将 AI 生成的源码自动推送至远程代码仓库并立刻触发 Theos 自动化交叉编译。

## 🎯 核心功能 (Features)

- **AI 源码生成 (Dylib Builder)**
  - 根据输入的目标应用名称或具体需求说明（如：“去除腾讯视频前置广告”），自动分析并生成对应的 Theos/Logos (.xm) 逆向汇编代码。
  - 自动生成结构完整的 `Makefile`（包含各类编译 Flag 和 Framework 依赖）及兼容打包平台的 `control` 文件。

- **多轮逻辑修改与细化 (Iterative Modifying)**
  - “源码生成器”支持根据生成的旧代码通过对话继续追加、删改 Hook 逻辑，完美处理长尾的定制化代码修复。

- **符号研究员 (Symbols Researcher)**
  - **如何使用：**
    在“符号研究员”页面输入你想研究的方向或具体的组件。例如输入 `UIAlertController 弹窗拦截` 或者 `微信撤回消息底层类名`。
    AI 会以资深 iOS 逆向专家的身份，为你深度解析苹果私有/公开库底层类名、方法名，并提供 Frida-trace 追踪命令或 Cycript / LLDB 的挂载分析调试策略，为动手编写代码前提供全方位的知识图谱和数据支撑。

- **GitHub Release 自动化打包 (Cloud Build & Release)**
  - 绑定 GitHub Personal Access Token (PAT)。
  - 一键将生成的源码推送至指定仓库，利用提前配置好的 `build.yml` 工作流实现云端云打包。
  - 支持全架构编译（同时产出传统 Rootful、Rootless 以及最新的 RootHide 越狱环境的 .deb 安装包）。
  - 打包产物将自动上传至被触发仓库的 Releases 中供直接下载安装。

- **多语言与自定义模型设置 (I18n & Model Settings)**
  - 支持中英双语 (ZH / EN)。
  - 在设置中自定义你偏好的提供商（通常支持环境变量透传或者用户输入自己的 Gemini 密钥）。

## 🚀 部署与使用指南 (How to setup)

1. 克隆本项目：
   ```bash
   git clone <你的仓库地址>
   cd <你的仓库目录>
   ```

2. 安装依赖并启动本地服务器：
   ```bash
   npm install
   npm run dev
   ```

3. 访问应用：
   打开浏览器并访问 `http://localhost:3000`。

## 🛠 技术栈与工程实践
- 前端：React 18 + Vite + Tailwind CSS + Framer Motion
- 后端：Express.js (供预览环境或作为生产基础镜像)
- API：整合了模型调用和 GitHub API 文件同步

## 💡 最佳使用建议
- 建议将 AI 输出的 Dylib 代码作为参考模板，由它打通绝大多数模板代码或常见组件逻辑，对于高度加密或动态变换偏移类的混淆代码，可以先利用 **符号研究员 (Researcher)** 探讨解题思路后再投入正式构建。 
- 对于 Theos 编译报错的修复，可以把报错日志直接复制到 **AI 修改区** 要求它排查并修正缺失的依赖或语法错误！

## 📄 协议 (License)
本项目遵守相应开源以及模型提供方的限制性协议。
