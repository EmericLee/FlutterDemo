# Flutter Demo

一个跨平台Flutter应用示例项目，支持Android、Windows、Linux等多平台构建。

## 🚀 技术栈

### 核心框架
- **Flutter**: [v3.24.5](https://flutter.dev/) - Google的跨平台UI工具包
- **Dart**: [v3.5.3](https://dart.dev/) - Flutter的编程语言

### 开发工具
- **Android Studio** - 主要开发环境
- **Android SDK**: [API Level 34](https://developer.android.com/studio) - Android开发工具包
- **GitHub Actions** - 持续集成/持续部署

### 构建工具和依赖管理
- **Gradle**: [v8.5](https://gradle.org/) - Android项目构建工具
- **pub**: Dart包管理器
- **CMake**: 桌面平台构建工具

### 平台支持
- **Android** (APK构建)
- **Windows** (Windows桌面应用)
- **Linux** (Linux桌面应用，支持ARM64架构)
- **macOS** (macOS桌面应用)
- **Web** (Web应用)
- **iOS** (iOS应用)

### CI/CD工具链
- **GitHub Actions** - 自动化构建和部署
- **Flutter Action**: [v2.13.0](https://github.com/subosito/flutter-action) - Flutter CI/CD集成
- **AppImage Tool** - Linux应用打包工具

## 📦 项目结构

```
flutter_demo/
├── .github/workflows/     # GitHub Actions工作流
├── android/               # Android平台特定代码
├── ios/                   # iOS平台特定代码  
├── lib/                   # Dart应用代码
├── linux/                 # Linux平台特定代码
├── macos/                 # macOS平台特定代码
├── windows/               # Windows平台特定代码
├── web/                   # Web平台特定代码
└── pubspec.yaml          # 项目依赖配置
```

## 🛠️ 开发环境要求

### 必需工具
- Flutter SDK: >= 3.24.0
- Dart SDK: >= 3.5.0 < 3.11.0
- Android SDK: API Level 34
- Git: 版本控制

### 推荐工具
- Android Studio 或 VS Code
- GitHub账户（用于CI/CD）

## 🚀 快速开始

### 本地开发
```bash
# 克隆项目
git clone <repository-url>
cd flutter_demo

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 构建发布版本
```bash
# Android APK
flutter build apk --release

# Windows桌面应用
flutter build windows --release

# Linux桌面应用
flutter build linux --release
```

## 📱 平台特性

### Android
- 支持ARM64架构
- 自动签名和打包
- Google Play商店兼容

### Windows
- Windows桌面应用支持
- 原生Windows UI集成
- 系统托盘支持

### Linux
- 支持ARM64架构
- AppImage打包格式
- 桌面环境集成

## 🔧 CI/CD配置

项目配置了多平台自动化构建：
- **Android构建**: Ubuntu环境，APK输出
- **Windows构建**: Windows环境，ZIP打包
- **Linux ARM64构建**: Ubuntu ARM64环境，AppImage输出

## 📄 许可证

本项目采用MIT许可证。

## 🤝 贡献

欢迎提交Issue和Pull Request来改进项目。

---

*项目持续更新中，更多功能正在开发...*  
