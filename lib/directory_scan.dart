import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'logger_service.dart';
import 'time_analyzer.dart';
import 'notification_service.dart';

/// 文件过滤类型枚举
enum FileFilterType {
  all,        // 显示所有文件
  consistent, // 只显示一致的文件
  needsFix,   // 只显示需要修正的文件
  cannotJudge,// 只显示无法解析的文件
}

/// 目录列表页面（为了向后兼容而保留）
class DirectoryListPage extends StatelessWidget {
  const DirectoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目录列表'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const DirectoryListWidget(),
    );
  }
}

/// 目录列表 Widget，可复用的文件浏览器组件
class DirectoryListWidget extends StatefulWidget {
  /// 可选参数：初始选中的目录路径
  final String? initialDirectory;

  /// 可选参数：是否自动扫描初始目录
  final bool autoScanInitialDirectory;

  /// 可选参数：回调函数，当文件列表更新时触发
  final ValueChanged<List<File>>? onFileListUpdated;

  const DirectoryListWidget({
    super.key,
    this.initialDirectory,
    this.autoScanInitialDirectory = false,
    this.onFileListUpdated,
  });

  @override
  State<DirectoryListWidget> createState() => _DirectoryListWidgetState();
}

class _DirectoryListWidgetState extends State<DirectoryListWidget> {
  String? _selectedDirectory;
  List<File> _fileList = [];
  bool _isScanning = false;
  List<TimeAnalysisResult> _fileListTimeAnalysised = [];
  bool _isTimeAnalysising = false;
  int _fileCount = 0;
  int _firstVisibleIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // 过滤功能状态变量
  FileFilterType _currentFilter = FileFilterType.all;
  String _searchQuery = '';

  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void onPressed() {}

  // 设置过滤类型
  void _setFilter(FileFilterType filter) {
    safeSetState(() {
      _currentFilter = filter;
    });
  }

  // 更新搜索查询
  void _updateSearchQuery(String query) {
    safeSetState(() {
      _searchQuery = query.toLowerCase();
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
        final fileName = file.path.split(Platform.pathSeparator).last.toLowerCase();
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

    // 处理初始目录
    if (widget.initialDirectory != null) {
      _selectedDirectory = widget.initialDirectory;
      if (widget.autoScanInitialDirectory) {
        _directoryScan(widget.initialDirectory!);
      }
    }

    // 监听滚动位置 - 优化性能，减少setState调用
    _scrollController.addListener(() {
      final firstVisibleIndex =
          _scrollController.position.minScrollExtent == _scrollController.offset
              ? 0
              : (_scrollController.offset /
                      _scrollController.position.maxScrollExtent *
                      _fileList.length)
                  .floor();

      if (firstVisibleIndex != _firstVisibleIndex && mounted) {
        safeSetState(() {
          _firstVisibleIndex = firstVisibleIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //header directory info
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _directorySelect,
                child: const Text('选择目录'),
              ),
              const SizedBox(width: 20), // 横向间距

              Expanded(
                child: Text(
                  _selectedDirectory != null
                      ? '选中目录: $_selectedDirectory'
                      : '请选择目录',
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 扫描状态显示
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    //scanning ....
                    if (_isScanning) ...[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('发现文件： $_fileCount '),
                      const SizedBox(width: 8),
                    ],
                    //Time analysising...
                    if (_isTimeAnalysising) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '已分析 ${_fileListTimeAnalysised.length} / $_fileCount ',
                      ),
                    ],
                    //Time analysising completed
                    if (!_isTimeAnalysising &&
                        _fileListTimeAnalysised.isNotEmpty) ...[
                      // const SizedBox(width: 8),
                      // Icon(
                      //   Icons.check_circle,
                      //   color: Colors.green,
                      // ),
                      // Text(
                      //   '分析完成 ${_fileListTimeAnalysised.length} 文件',
                      //   style: const TextStyle(fontWeight: FontWeight.bold),
                      // ),
                      const SizedBox(width: 8),
                      // 搜索框
                      // SizedBox(
                      //   width: 200,
                      //   child: TextField(
                      //     decoration: InputDecoration(
                      //       hintText: '搜索文件名...',
                      //       prefixIcon: Icon(Icons.search, size: 16),
                      //       contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      //       border: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(20),
                      //         borderSide: BorderSide(color: Colors.grey.shade300),
                      //       ),
                      //       enabledBorder: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(20),
                      //         borderSide: BorderSide(color: Colors.grey.shade300),
                      //       ),
                      //       focusedBorder: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(20),
                      //         borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      //       ),
                      //     ),
                      //     style: TextStyle(fontSize: 12),
                      //     onChanged: _updateSearchQuery,
                      //   ),
                      // ),
                      // const SizedBox(width: 8),
                      // 过滤按钮组
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 全部按钮
                            _buildFilterButton(
                              '全部',
                              FileFilterType.all,
                              Icons.filter_list,
                              _fileListTimeAnalysised.length,
                            ),
                            const SizedBox(width: 8),
                            // 一致按钮
                            _buildFilterButton(
                              '一致',
                              FileFilterType.consistent,
                              Icons.check_circle,
                              _fileListTimeAnalysised.where((r) => r.status == TimeAnalysisStatus.consistent).length,
                              Colors.green,
                            ),
                            const SizedBox(width: 8),
                            // 修正按钮
                            _buildFilterButton(
                              '修正',
                              FileFilterType.needsFix,
                              Icons.timer,
                              _fileListTimeAnalysised.where((r) => r.status == TimeAnalysisStatus.needsFix).length,
                              Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            // 无法解析按钮
                            _buildFilterButton(
                              '无法解析',
                              FileFilterType.cannotJudge,
                              Icons.help_outline,
                              _fileListTimeAnalysised.where((r) => r.status == TimeAnalysisStatus.cannotJudge).length,
                              Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
                    //Stop button
                    if (_isScanning || _isTimeAnalysising) ...[
                      SizedBox(width: 8),
                      Tooltip(
                        message: '点击停止扫描',
                        child: InkWell(
                            onTap: () {
                              // 停止扫描
                              _stopScan();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.stop,
                                size: 16,
                                color: Colors.red,
                              ),
                            )),
                      )
                    ],
                  ],
                ),
              )
            ],
          ),
        ),

        //separator
        const Divider(height: 1),

        // 文件列表
        Expanded(
          child: Column(
            children: [
              Expanded(
                  child: _fileList.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('请选择一个目录',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey)),
                              SizedBox(height: 8),
                              Text('点击上方按钮选择要扫描的目录',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        )
                      : _buildFileList()),
              // 底部信息栏
              if (_fileList.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('总计: $_fileCount 个文件'),
                      Text(
                          '当前位置: ${_firstVisibleIndex + 1}/${_fileList.length}'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // 构建文件列表视图
  Widget _buildFileList() {
    final filteredList = _filteredFileList;
    
    if (filteredList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('没有符合条件的文件',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('尝试调整过滤条件或搜索关键词',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: filteredList.length,
        itemExtent: 72.0, // 固定高度提升滚动性能
        cacheExtent: 200.0, // 增加缓存区域
        addAutomaticKeepAlives: false, // 禁用自动保持活动状态
        addRepaintBoundaries: true, // 启用重绘边界
        itemBuilder: (context, index) {
          File file = filteredList[index];
          
          // 在原始列表中查找对应的分析结果
          final originalIndex = _fileList.indexOf(file);
          TimeAnalysisResult? analysisResult;

          // 查找当前文件的时间分析结果
          if (originalIndex >= 0 && originalIndex < _fileListTimeAnalysised.length) {
            analysisResult = _fileListTimeAnalysised[originalIndex];
          }

          return Column(
            children: [
              _buildFileListRow(file, analysisResult),
              if (index < filteredList.length - 1) const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }

  // 构建过滤按钮
  Widget _buildFilterButton(
    String label,
    FileFilterType filterType,
    IconData icon,
    int count, [
    Color? activeColor,
  ]) {
    final isActive = _currentFilter == filterType;
    final color = activeColor ?? Theme.of(context).primaryColor;

    return Tooltip(
      message: '$label: $count 个文件',
      child: InkWell(
        onTap: () => _setFilter(filterType),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? color : Colors.grey.shade300,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? color : Colors.grey.shade600,
              ),
              SizedBox(width: 4),
              Text(
                '$label',
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? color : Colors.grey.shade700,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (count > 0) ...[
                SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? color : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 构建文件列表项 row
  Widget _buildFileListRow(File file, TimeAnalysisResult? analysisResult) {
    return RepaintBoundary(
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file, size: 20),
        title: Row(
          children: [
            Flexible(
              child: Text(
                file.path.split(Platform.pathSeparator).last,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          file.path,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 200, // 设置固定宽度以控制右侧显示区域
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 原始修改时间（trailing显示）
              _buildFileOrignalTime(file, analysisResult),
              // 分析结果（trailing显示）
              _buildFileAnalyTime(analysisResult)
            ],
          ),
        ),
      ),
    );
  }

  // 获取状态图标和文本
  Widget _buildFileAnalyTime(TimeAnalysisResult? result) {
    SelectableText msgText;
    Icon msgIcon;

    if (result == null) {
      msgText = const SelectableText('正在分析...');
      msgIcon = const Icon(Icons.help, size: 12, color: Colors.grey);
    } else {
      switch (result.status) {
        case TimeAnalysisStatus.consistent:
          msgText =
              SelectableText('一致 ${_formatDateTime(result.suggestedTime)}');
          msgIcon =
              const Icon(Icons.check_circle, size: 12, color: Colors.green);
          break;
        case TimeAnalysisStatus.needsFix:
          msgText =
              SelectableText('需要修正: ${_formatDateTime(result.suggestedTime)}');
          msgIcon = const Icon(Icons.warning, size: 12, color: Colors.orange);
          break;
        case TimeAnalysisStatus.cannotJudge:
          msgText = SelectableText(
              '无有效时间信息： ${_formatDateTime(result.suggestedTime)}');
          msgIcon = const Icon(Icons.help, size: 12, color: Colors.grey);
          break;
      }
      switch (result.suggestedFrom) {
        case TimeAnalysisFrom.exif:
          msgText = SelectableText('${msgText.data ?? ''} (E)');
          break;
        case TimeAnalysisFrom.filename:
          msgText = SelectableText('${msgText.data ?? ''} (F)');
          break;
        case TimeAnalysisFrom.unknown:
          msgText = SelectableText('${msgText.data ?? ''} (U)');
          break;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        msgIcon,
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            msgText.data ?? '',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 构建文件原始信息行
  Widget _buildFileOrignalTime(File file, TimeAnalysisResult? analysisResult) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.history, size: 12, color: Colors.blue),
        const SizedBox(width: 2),
        SelectableText(
          analysisResult != null
              ? _formatDateTime(analysisResult.originalTime)
              : _formatDateTime(file.statSync().modified),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
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
    // 记录开始时间
    final startTime = DateTime.now();
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

    // 计算总耗时并显示完成通知
    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime);
    final scanDuration = scanEndTime.difference(scanStartTime);
    final analysisDuration = analysisEndTime.difference(analysisStartTime);
    
    // 显示详细的完成时间统计
    final message = '扫描完成！\n'
        '总耗时: ${_formatDuration(totalDuration)}\n'
        '文件扫描: ${fileScanCount}个文件, 耗时: ${_formatDuration(scanDuration)}\n'
        '时间分析: ${timeAnalysisCount}个文件, 耗时: ${_formatDuration(analysisDuration)}';
    
    notification.show(
      title: '扫描完成', 
      msg: message,
      persistent: true,
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
        _fileList = files;
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

      // await Future.delayed(const Duration(milliseconds: 10));

      // 使用TimeAnalyzer.analyzeSingleFile方法获取分析结果
      final result = await TimeAnalyzer.analyzeFile(_fileList[i]);
      results.add(result);

      // 显示进度信息
      if (i % 100 == 0 || i == _fileList.length - 1) {
        await Future.delayed(const Duration(milliseconds: 10));  // 暂停1毫秒，避免UI卡顿
        // 更新时间分析结果列表
        safeSetState(() {
          _fileListTimeAnalysised.addAll(results);
          results.clear();
        });
      }
    }
  }

  // 格式化日期时间
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}:${_twoDigits(dateTime.second)}';
  }

  // 格式化两位数
  String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
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