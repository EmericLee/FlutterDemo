import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// 目录列表 Widget，可复用的文件浏览器组件
class DirectoryListWidget extends StatefulWidget {
  /// 可选参数：初始选中的目录路径
  final String? initialDirectory;

  /// 可选参数：是否自动扫描初始目录
  final bool autoScanInitialDirectory;

  /// 可选参数：回调函数，当选择目录时触发
  final ValueChanged<String>? onDirectorySelected;

  /// 可选参数：回调函数，当文件列表更新时触发
  final ValueChanged<List<File>>? onFileListUpdated;

  const DirectoryListWidget({
    Key? key,
    this.initialDirectory,
    this.autoScanInitialDirectory = false,
    this.onDirectorySelected,
    this.onFileListUpdated,
  }) : super(key: key);

  @override
  State<DirectoryListWidget> createState() => _DirectoryListWidgetState();
}

class _DirectoryListWidgetState extends State<DirectoryListWidget> {
  String? _selectedDirectory;
  List<File> _fileList = [];
  bool _isScanning = false;
  int _fileCount = 0;
  int _firstVisibleIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // 选择目录
  Future<void> _selectDirectory() async {
    try {
      String? result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        _startScan(result);
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择目录时出错: $e')),
      );
    }
  }

  // 开始扫描目录
  Future<void> _startScan(String directoryPath) async {
    setState(() {
      _selectedDirectory = directoryPath;
      _isScanning = true;
      _fileList.clear();
      _fileCount = 0;
    });

    // 调用目录选择回调
    widget.onDirectorySelected?.call(directoryPath);

    // 扫描目录
    await _scanDirectory(directoryPath);

    setState(() {
      _isScanning = false;
      // 按文件名字母排序
      _fileList.sort((a, b) => a.path.compareTo(b.path));
      _fileCount = _fileList.length;
    });

    // 调用文件列表更新回调
    widget.onFileListUpdated?.call(_fileList);
  }

  @override
  void initState() {
    super.initState();

    // 处理初始目录
    if (widget.initialDirectory != null) {
      _selectedDirectory = widget.initialDirectory;
      if (widget.autoScanInitialDirectory) {
        _startScan(widget.initialDirectory!);
      }
    }

    // 监听滚动位置
    _scrollController.addListener(() {
      final firstVisibleIndex =
          _scrollController.position.minScrollExtent == _scrollController.offset
              ? 0
              : (_scrollController.offset /
                      _scrollController.position.maxScrollExtent *
                      _fileList.length)
                  .floor();

      if (firstVisibleIndex != _firstVisibleIndex) {
        setState(() {
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

  // 递归扫描目录
  Future<void> _scanDirectory(String directoryPath) async {
    Directory directory = Directory(directoryPath);
    if (!directory.existsSync()) return;

    try {
      // 获取目录中的所有实体
      List<FileSystemEntity> entities =
          directory.listSync(recursive: true, followLinks: false);

      for (var entity in entities) {
        // 暂停200毫秒
        await Future.delayed(const Duration(milliseconds: 10));
        if (entity is File) {
          setState(() {
            _fileList.add(entity);
          });
        }
      }
    } catch (e) {
      // 忽略权限问题等异常，继续扫描其他文件
      print('扫描目录时出错: $e');
    }
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
                onPressed: _selectDirectory,
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

              Text(
                _isScanning
                    ? '正在扫描文件...'
                    : _fileCount > 0
                        ? '共找到 $_fileCount 个文件'
                        : '未找到文件',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),

        //separator
        const Divider(height: 1),

        // 文件列表
        Expanded(
          child: Stack(
            children: [
              _fileList.isEmpty
                  ? const Center(child: Text('请选择一个目录'))
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _scrollController,
                        itemCount: _fileList.length,
                        // 使用separated更高效地添加分隔线
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          File file = _fileList[index];
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file,
                                size: 20), // 添加文件图标
                            title: Text(
                              file.path,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        },
                      ),
                    ),
              // 底部信息栏
              if (_fileList.isNotEmpty) ...[
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
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
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 目录列表页面（为了向后兼容而保留）
class DirectoryListPage extends StatelessWidget {
  const DirectoryListPage({Key? key}) : super(key: key);

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
