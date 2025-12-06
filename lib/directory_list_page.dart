import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class DirectoryListPage extends StatefulWidget {
  const DirectoryListPage({super.key});

  @override
  State<DirectoryListPage> createState() => _DirectoryListPageState();
}

class _DirectoryListPageState extends State<DirectoryListPage> {
  String? _selectedDirectory;
  List<File> _fileList = [];
  bool _isScanning = false;
  int _fileCount = 0;

  // 选择目录
  Future<void> _selectDirectory() async {
    try {
      String? result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        setState(() {
          _selectedDirectory = result;
          _isScanning = true;
          _fileList.clear();
          _fileCount = 0;
        });

        // 扫描目录
        await _scanDirectory(result);

        setState(() {
          _isScanning = false;
          // 按文件名字母排序
          _fileList.sort((a, b) => a.path.compareTo(b.path));
          _fileCount = _fileList.length;
        });
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

  // 递归扫描目录
  Future<void> _scanDirectory(String directoryPath) async {
    Directory directory = Directory(directoryPath);
    if (!directory.existsSync()) return;

    try {
      // 获取目录中的所有实体
      List<FileSystemEntity> entities = directory.listSync(recursive: true, followLinks: false);
      
      for (var entity in entities) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('目录列表'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 目录选择按钮
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _selectDirectory,
              child: const Text('选择目录'),
            ),
          ),

          // 选中目录显示
          if (_selectedDirectory != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '选中目录: $_selectedDirectory',
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // 文件数量统计
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _isScanning 
                  ? '正在扫描文件...' 
                  : _fileCount > 0 
                      ? '共找到 $_fileCount 个文件' 
                      : '未找到文件',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // 文件列表
          Expanded(
            child: _isScanning
                ? const Center(child: CircularProgressIndicator())
                : _fileList.isEmpty
                    ? const Center(child: Text('请选择一个目录'))
                    : ListView.builder(
                        itemCount: _fileList.length,
                        itemBuilder: (context, index) {
                          File file = _fileList[index];
                          return ListTile(
                            title: Text(file.path),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
