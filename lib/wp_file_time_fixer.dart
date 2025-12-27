import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'logger_service.dart';
import 'time_analyzer.dart';
import 'notification_service.dart';
import 'wg_scan_status_panel.dart';
import 'wg_file_list.dart';

/// 文件过滤类型枚举
enum FileFilterType {
  all, // 显示所有文件
  consistent, // 只显示一致的文件
  needsFix, // 只显示需要修正的文件
  cannotJudge, // 只显示无法解析的文件
  fixed, // 只显示已修正的文件
}

/// 智能目录列表 Widget - 支持独立页面和嵌入组件双模式
class WPFileTimeFixer extends StatefulWidget {
  /// 可选参数：初始选中的目录路径
  final String? initialDirectory;

  /// 可选参数：是否自动扫描初始目录
  final bool autoScanInitialDirectory;

  /// 可选参数：回调函数，当文件列表更新时触发
  final ValueChanged<List<File>>? onFileListUpdated;

  /// 可选参数：是否作为独立页面使用（默认为false）
  final bool isPage;

  /// 可选参数：页面标题（仅在isPage=true时生效）
  final String? pageTitle;

  /// 可选参数：自动修正功能开关状态
  final bool? autoFixEnabled;

  /// 可选参数：自动修正开关状态变化回调
  final ValueChanged<bool>? onAutoFixChanged;

  const WPFileTimeFixer({
    super.key,
    this.initialDirectory,
    this.autoScanInitialDirectory = false,
    this.onFileListUpdated,
    this.isPage = false,
    this.pageTitle,
    this.autoFixEnabled,
    this.onAutoFixChanged,
  });

  @override
  State<WPFileTimeFixer> createState() => _WPFileTimeFixerState();
}

class _WPFileTimeFixerState extends State<WPFileTimeFixer> {
  String? _selectedDirectory;
  bool _isScanning = false;
  bool _isTimeAnalysising = false;
  final List<File> _fileList = [];
  final List<TimeAnalysisResult> _fileListTimeAnalysised = [];
  int _fileCount = 0;

  // 过滤功能状态变量
  FileFilterType _currentFilter = FileFilterType.all;
  final String _searchQuery = '';

  // 自动修正开关状态
  late bool _autoFixEnabled;

  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // 自动修正开关状态变化处理
  void _onAutoFixChanged(bool value) {
    safeSetState(() {
      _autoFixEnabled = value;
    });

    // 调用外部回调
    if (widget.onAutoFixChanged != null) {
      widget.onAutoFixChanged!(value);
    }

    // 显示通知
    final message = value ? '自动修正功能已启用' : '自动修正功能已禁用';
    notification.show(msg: message);
  }

  // 设置过滤类型
  void _setFilter(FileFilterType filter) {
    safeSetState(() {
      _currentFilter = filter;
    });
  }

  // 获取过滤后的文件列表
  List<File> get _filteredFileList {
    if (_currentFilter == FileFilterType.all && _searchQuery.isEmpty) {
      return _fileList;
    }

    return _fileList.where((file) {
      // 搜索过滤
      if (_searchQuery.isNotEmpty) {
        final fileName =
            file.path.split(Platform.pathSeparator).last.toLowerCase();
        if (!fileName.contains(_searchQuery)) {
          return false;
        }
      }

      // 状态过滤
      if (_currentFilter != FileFilterType.all) {
        final index = _fileList.indexOf(file);
        if (index >= _fileListTimeAnalysised.length) {
          return false;
        }

        final analysisResult = _fileListTimeAnalysised[index];
        switch (_currentFilter) {
          case FileFilterType.consistent:
            return analysisResult.status == TimeAnalysisStatus.consistent;
          case FileFilterType.needsFix:
            return analysisResult.status == TimeAnalysisStatus.needsFix;
          case FileFilterType.fixed:
            return analysisResult.status == TimeAnalysisStatus.fixed;
          case FileFilterType.cannotJudge:
            return analysisResult.status == TimeAnalysisStatus.cannotJudge;
          default:
            return true;
        }
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    // 初始化自动修正状态
    _autoFixEnabled = widget.autoFixEnabled ?? false;

    // 处理初始目录
    if (widget.initialDirectory != null) {
      _selectedDirectory = widget.initialDirectory;
      if (widget.autoScanInitialDirectory) {
        _directoryScan(widget.initialDirectory!);
      }
    }

  }


  @override
  Widget build(BuildContext context) {
    // 页面模式：返回完整的Scaffold结构
    if (widget.isPage) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              // 自动修正开关图标
              Icon(
                _autoFixEnabled ? Icons.auto_fix_high : Icons.auto_fix_off,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(widget.pageTitle ?? '目录列表'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                        onPressed: _directorySelect,
                        child: Row(
                          children: [
                            const Icon(Icons.folder_open),
                            const SizedBox(width: 5),
                            if (_selectedDirectory == null) ...[
                              const Text('选择目录'),
                            ] else ...[
                              const Text('重新扫描目录'),
                            ]
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '自动修正',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 36,
                      height: 22,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Switch(
                          value: _autoFixEnabled,
                          onChanged: _onAutoFixChanged,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        ),
        body: _buildContent(),
      );
    }

    // 嵌入模式：仅返回内容区域
    return _buildContent();
  }

  Widget _buildContent() {
    return Column(
      children: [
        //header directory info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: IconButton(
                onPressed: _directorySelect,
                icon: const Icon(Icons.folder_open),
              ),
            ),
            Expanded(
              child: Text(
                _selectedDirectory != null
                    ? '扫描: $_selectedDirectory'
                    : '请选择目录',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 扫描状态显示
            ScanStatusPanel(
              isScanning: _isScanning,
              fileCount: _fileCount,
              isTimeAnalysising: _isTimeAnalysising,
              fileListTimeAnalysised: _fileListTimeAnalysised,
              currentFilter: _currentFilter,
              onStopScan: _stopScan,
              onFilterChange: _setFilter,
            ),
          ],
        ),

        //separator
        const Divider(height: 1),

        // 文件列表
        Expanded(
          child: FileListWidget(
            filteredFileList: _filteredFileList,
            originalFileList: _fileList,
            fileListTimeAnalysised: _fileListTimeAnalysised,
          ),
        ),
      ],
    );
  }

  // 停止扫描
  void _stopScan() {
    if (_isScanning || _isTimeAnalysising) {
      setState(() {
        _isScanning = false;
        _isTimeAnalysising = false;
      });
      notification.show(msg: '扫描已停止');
    }
  }

  // 检查并请求存储权限
  Future<bool> _checkAndroidStoragePermission() async {
    // 根据Android版本检查不同的权限
    if (Platform.isAndroid) {
      // Android 13+ (API 33+)
      if (await Permission.storage.status.isDenied ||
          await Permission.photos.status.isDenied ||
          await Permission.videos.status.isDenied ||
          await Permission.audio.status.isDenied) {
        // 请求Android 13+的媒体权限
        Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();

        // 检查是否有必要的权限被授予
        return statuses[Permission.storage]?.isGranted == true ||
            statuses[Permission.photos]?.isGranted == true ||
            statuses[Permission.videos]?.isGranted == true ||
            statuses[Permission.audio]?.isGranted == true;
      }

      // Android 11-12 (API 30-32)
      if (await Permission.storage.status.isDenied) {
        if (await Permission.storage.request().isGranted) {
          return true;
        }
      }

      // Android 10 及以下
      if (await Permission.manageExternalStorage.status.isDenied) {
        if (await Permission.manageExternalStorage.request().isGranted) {
          return true;
        }
      }
    }

    // 非Android平台或已拥有权限
    return true;
  }

  // 选择目录并开始扫描
  Future<void> _directorySelect() async {
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath != null) {
        // notification.show(msg: '已经选择目录 $directoryPath \n 开始扫描...');
        _directoryScan(directoryPath);
      } else {
        notification.show(msg: '未选择目录，请重新选择...');
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      notification.show(msg: '选择目录时出错: $e');
    }
  }

  // 开始扫描目录
  Future<void> _directoryScan(String directoryPath) async {
    int fileScanCount = 0;
    int timeAnalysisCount = 0;

    // 检查权限
    bool hasPermission = await _checkAndroidStoragePermission();
    if (!hasPermission) {
      setState(() {
        _isScanning = false;
      });
      // 检查组件是否仍然挂载，避免在异步操作后使用已销毁的context
      notification.show(msg: '需要存储权限才能访问文件');
      return;
    }

    // 初始化扫描状态
    setState(() {
      _selectedDirectory = directoryPath;
      _isScanning = true;
      _fileList.clear();
      _fileListTimeAnalysised.clear();
      _fileCount = 0;
    });

    // 扫描目录列表
    final scanStartTime = DateTime.now();
    await _directoryScanRun(directoryPath);
    final scanEndTime = DateTime.now();
    fileScanCount = _fileList.length;

    // notification.show(title: '扫描完成', msg: '已扫描 ${_fileList.length} 个文件');

    setState(() {
      _isScanning = false;
      // 按文件名字母排序
      _fileCount = _fileList.length;
    });

    // 扫描完成后，检查并修正文件修改时间
    safeSetState(() {
      _isTimeAnalysising = true;
    });

    final analysisStartTime = DateTime.now();
    await _directoryScanTime();
    final analysisEndTime = DateTime.now();
    timeAnalysisCount = _fileListTimeAnalysised.length;

    safeSetState(() {
      _isTimeAnalysising = false;
    });

    // 显示详细的完成时间统计
    final scanDuration = scanEndTime.difference(scanStartTime);
    final analysisDuration = analysisEndTime.difference(analysisStartTime);

    // 显示详细的完成时间统计
    String message = '\n';
    message = _autoFixEnabled
        ? '完成时间修正！ 总共修正了【${_fileListTimeAnalysised.where((r) => r.status == TimeAnalysisStatus.fixed).length}】个文件'
        : 'Dryrun 模式，自动修正未启用，共发现需修正文件【${_fileListTimeAnalysised.where((r) => r.status == TimeAnalysisStatus.needsFix).length}】个';
    message += '\n\n'
        '文件扫描: $fileScanCount个文件, 耗时: ${_formatDuration(scanDuration)}\n'
        '时间分析: $timeAnalysisCount个文件, 耗时: ${_formatDuration(analysisDuration)}\n'
        '';

    notification.show(
      title: '扫描完成',
      msg: message,
      duration: const Duration(seconds: 15),
    );

    // 调用文件列表更新回调
    widget.onFileListUpdated?.call(_fileList);
  }

  // 递归扫描目录
  // 遍历目录下的所有文件和子目录
  // 将会改变数据状态: _fileCount, _fileList
  Future<void> _directoryScanRun(String directoryPath) async {
    Directory directory = Directory(directoryPath);
    final List<File> files = [];

    if (!directory.existsSync()) {
      logger.w('目录不存在: $directoryPath');
      return;
    }

    try {
      // 使用异步方式获取目录实体，避免阻塞UI线程
      Stream<FileSystemEntity> entityStream =
          directory.list(recursive: true, followLinks: false);

      await for (var entity in entityStream) {
        // 检查是否已停止扫描
        if (!_isScanning) {
          logger.i('扫描已被用户停止');
          return;
        }

        // 暂停10毫秒，避免UI卡顿
        // await Future.delayed(const Duration(milliseconds: 2));

        try {
          if (entity is File) {
            // 检查文件是否可读
            if (entity.existsSync() && await entity.length() >= 0) {
              // 确保组件仍然处于挂载状态，避免setState() called after dispose()错误
              files.add(entity);
            }
          }
        } catch (fileError) {
          // 忽略单个文件的错误，继续扫描其他文件
          logger.e('访问文件时出错: ${entity.path}, 错误: $fileError');
        }

        //update file count every 10 files
        int count = files.length;
        if ((count + 1) % 100 == 0) {
          safeSetState(() {
            _fileCount = files.length;
          });
        }
      }

      //update file list
      files.sort((a, b) => a.path.compareTo(b.path));
      safeSetState(() {
        _fileCount = files.length;
        _fileList.addAll(files);
      });
    } catch (e) {
      // 记录详细的目录扫描错误
      logger.e('扫描目录时出错: $directoryPath, 错误: $e');

      // 在Android平台上，可能需要特殊处理分区存储限制
      if (Platform.isAndroid) {
        logger.w('Android平台上的目录访问错误，可能是因为分区存储限制');
        // 尝试访问应用私有目录作为替代方案
        try {
          String? appDir = Directory.systemTemp.parent.path;
          logger.i('尝试访问应用目录: $appDir');
          Directory appDirectory = Directory(appDir);
          if (appDirectory.existsSync()) {
            Stream<FileSystemEntity> appEntityStream =
                appDirectory.list(recursive: true, followLinks: false);

            await for (var entity in appEntityStream) {
              if (entity is File) {
                // 确保组件仍然处于挂载状态，避免setState() called after dispose()错误
                if (mounted) {
                  setState(() {
                    _fileList.add(entity);
                  });
                }
              }
            }
          }
        } catch (appDirError) {
          logger.e('访问应用目录时出错: $appDirError');
        }
      }
    }
  }

  // 检查并分析文件的修改时间
  Future<void> _directoryScanTime() async {
    if (_fileList.isEmpty) {
      return;
    }

    List<TimeAnalysisResult> results = [];

    // 遍历所有文件
    for (int i = 0; i < _fileList.length; i++) {
      // 检查是否已停止扫描
      if (!_isTimeAnalysising) {
        logger.i('时间分析已被用户停止');
        return;
      }

      // 使用TimeAnalyzer.analyzeSingleFile方法获取分析结果
      final result = await TimeAnalyzer.analyzeFile(_fileList[i]);
      if (_autoFixEnabled &&
          result.status == TimeAnalysisStatus.needsFix &&
          result.suggestedTime != null) {
        //修改文件创建时间和最后修改到建议时间
        _fileList[i].setLastModifiedSync(result.suggestedTime!);
        result.status = TimeAnalysisStatus.fixed;
      }
      results.add(result);

      // 显示进度信息
      if (i % 100 == 0 || i == _fileList.length - 1) {
        // 更新时间分析结果列表
        safeSetState(() {
          _fileListTimeAnalysised.addAll(results);
          results.clear();
        });
      }
      await Future.delayed(const Duration(milliseconds: 2)); // 暂停1毫秒，避免UI卡顿
    }
  }

  // 格式化持续时间
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天 ${duration.inHours % 24}小时 ${duration.inMinutes % 60}分 ${duration.inSeconds % 60}秒';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}小时 ${duration.inMinutes % 60}分 ${duration.inSeconds % 60}秒';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分 ${duration.inSeconds % 60}秒';
    } else if (duration.inSeconds > 0) {
      return '${duration.inSeconds}秒 ${duration.inMilliseconds % 1000}毫秒';
    } else {
      return '${duration.inMilliseconds}毫秒';
    }
  }
}
