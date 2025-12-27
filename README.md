# FTime Fixer
#### 文件时间修正工具 (File Time Fixer)

一个智能的Flutter文件时间修正工具，专门用于解决文件传输、手机备份恢复过程中可能造成的时间信息混乱问题。

- **下载地址**: [GitHub Releases](https://github.com/EmericLee/FlutterDemo/releases)

## 🎯 项目介绍

本项目主要功能是扫描指定目录的所有文件，根据文件的名称或者EXIF信息智能修正文件时间。支持多平台运行，是一个Flutter跨平台解决方案的完整示例。

### 核心功能

- **📁 智能目录扫描**: 递归扫描指定目录，列出所有文件
- **🕒 时间分析**: 根据文件名格式和EXIF信息分析文件时间
- **🔧 自动修正**: 智能修正文件创建时间和修改时间
- **🏷️ 文件过滤**: 支持按文件状态（正常、需要修正、已修正等）过滤显示
- **📊 实时进度**: 显示扫描和分析进度
- **📱 跨平台支持**: 一套代码，多平台运行(x86 arm)

## 🌐 平台支持

- ✔️ **Android** (APK构建) - 多架构 
- ✔️ **Windows** (Windows桌面应用) - x64架构
- ✔️ **Linux** (Linux桌面应用) - ARM64和x64架构
- **macOS** (macOS桌面应用) - 未测试
- **iOS** (iOS应用) - 未测试



## 🚀 技术栈

### 核心框架
- **Flutter**: [v3.24.5](https://flutter.dev/) - Google的跨平台UI工具包
- **Dart**: [v3.5.3](https://dart.dev/) - Flutter的编程语言

### 主要依赖
- **permission_handler** - 权限管理
- **file_picker** - 文件选择和目录浏览
- **exif** - 图片EXIF信息提取
- **logger** - 日志记录框架
- **bot_toast** - 通知提示组件
- **package_info_plus** - 应用版本信息获取
- **collection** - 数据结构工具库

### 开发工具
- **Android Studio** - 主要开发环境
- **VS Code** - 轻量级开发编辑器
- **GitHub Actions** - 持续集成

### 构建工具和依赖管理
- **Gradle**: [v8.5](https://gradle.org/) - Android项目构建工具
- **pub**: Dart包管理器
- **CMake**: 桌面平台构建工具


## 📦 项目结构

```
flutter_demo/
├── .github/workflows/     # GitHub Actions自动化构建
├── android/               # Android平台配置和代码
├── ios/                   # iOS平台配置和代码  
├── lib/                   # Dart应用核心代码
│   ├── main.dart          # 应用入口
│   ├── time_analyzer.dart # 时间分析核心逻辑
│   ├── wp_file_time_fixer.dart # 主要UI组件
│   ├── notification_service.dart # 通知服务
│   ├── logger_service.dart # 日志服务
│   ├── wg_file_list.dart  # 文件列表组件
│   └── wg_scan_status_panel.dart # 扫描状态面板
├── linux/                 # Linux平台特定代码
├── macos/                 # macOS平台特定代码
├── windows/               # Windows平台特定代码
├── web/                   # Web平台特定代码
├── assets/                # 应用资源文件
└── pubspec.yaml          # 项目依赖配置
```

## 🛠️ 开发环境要求

### 必需工具
- **Flutter SDK**: >= 3.24.0
- **Dart SDK**: >= 3.5.0
- **Android SDK**: API Level 34
- **Git**: 版本控制
- **CMake**: >= 3.16 (Linux/Windows构建)

### 推荐开发环境
- **Android Studio** (推荐Android开发)
- **VS Code** (轻量级开发)
- **Xcode** (macOS/iOS开发，仅限macOS)

### 平台特定要求
- **Android**: Android SDK + NDK
- **iOS**: Xcode 14.0+ (仅限macOS)
- **Windows**: Visual Studio Build Tools
- **Linux**: GCC/Clang编译器

## 🚀 二次开发如何开始

### 1. 环境准备
```bash
# 安装Flutter SDK (如果未安装)
# 参考: https://flutter.dev/docs/get-started/install

# 验证Flutter环境
flutter doctor
```

### 2. 获取项目
```bash
# 克隆项目
git clone <repository-url>
cd flutter_demo

# 安装依赖
flutter pub get
```

### 3. 运行项目
```bash
# 运行到Android设备/模拟器
flutter run

# 运行到Windows桌面
flutter run -d windows

# 运行到Web浏览器
flutter run -d chrome

# 运行到iOS设备 (仅限macOS)
flutter run -d ios
```

## 📱 构建发布版本

### Android
```bash
# 构建APK
flutter build apk --release

# 构建App Bundle (Google Play推荐)
flutter build appbundle --release
```

### Windows
```bash
# 构建Windows桌面应用
flutter build windows --release
```

### Linux
```bash
# 构建Linux桌面应用
flutter build linux --release

# 构建ARM64版本 (适用于树莓派等)
flutter build linux --release --target-arch arm64
```

### macOS
```bash
# 构建macOS桌面应用
flutter build macos --release
```

### Web
```bash
# 构建Web应用
flutter build web --release
```

## 🔧 功能特色

### 智能时间分析
- **文件名模式识别**: 自动识别文件名中的日期时间信息
- **EXIF数据读取**: 支持图片文件的EXIF时间信息
- **多格式支持**: 支持多种常见的文件名日期格式

### 文件过滤与管理
- **状态过滤**: 按文件时间状态过滤显示
  - 正常文件 (时间一致)
  - 需要修正的文件
  - 已修正的文件
  - 无法判断的文件
- **搜索功能**: 按文件名快速搜索
- **排序选项**: 按文件名、修改时间等排序

### 用户界面
- **现代化UI**: Material Design 3.0设计语言
- **响应式布局**: 适配不同屏幕尺寸
- **实时反馈**: 扫描进度实时显示
- **通知系统**: 操作完成及时通知

## 📊 性能特点

- **高效扫描**: 异步文件扫描，避免UI阻塞
- **内存优化**: 流式处理大量文件，内存占用低
- **错误恢复**: 完善的错误处理和恢复机制
- **权限兼容**: 智能权限管理，适配不同平台权限模型

## 🔐 权限说明

### Android
- **存储权限**: 读取外部存储和内部存储
- **媒体权限**: 读取媒体文件权限

### Windows/Linux
- **文件系统权限**: 访问指定目录的读写权限

### iOS
- **相册访问权限**: 访问照片库的权限

## 🔧 CI/CD配置

项目配置了多平台自动化构建流水线：

### 构建矩阵
- **Android**: Ubuntu环境，输出APK
- **Windows**: Windows环境，输出ZIP安装包
- **Linux**: Ubuntu ARM64环境，输出AppImage
- **macOS**: macOS环境，输出DMG安装包

### 构建触发
- **推送代码**: 自动触发全平台构建
- **创建Release**: 自动构建发布版本
- **手动触发**: 支持手动触发特定平台构建

## 🐛 故障排除

### 常见问题

1. **Android权限被拒绝**
   - 检查应用权限设置
   - 手动授予存储权限

2. **构建失败**
   ```bash
   # 清理构建缓存
   flutter clean
   flutter pub get
   ```

3. **iOS构建问题**
   ```bash
   # iOS平台重置
   cd ios
   pod deintegrate
   pod install
   ```

## 📄 许可证

本项目采用 [MIT License](LICENSE) 许可证。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进项目！

### 贡献指南
1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📞 支持

如果您在使用过程中遇到问题，可以：

1. 查看 [Issues](issues) 页面寻找解决方案
2. 创建新的 Issue 描述问题
3. 参与讨论帮助其他用户

---

*这个项目展示了Flutter在跨平台开发中的强大能力，一套代码即可覆盖多个平台和架构，是学习Flutter开发的优秀示例。*