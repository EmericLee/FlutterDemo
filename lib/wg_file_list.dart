import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_demo/notification_service.dart';
import 'dart:io';
import 'time_analyzer.dart';

/// 文件列表Widget
/// 显示过滤后的文件列表，包含时间分析结果
class FileListWidget extends StatefulWidget {
  final List<File> filteredFileList;
  final List<File> originalFileList;
  final List<TimeAnalysisResult?> fileListTimeAnalysised;

  const FileListWidget({
    super.key,
    required this.filteredFileList,
    required this.originalFileList,
    required this.fileListTimeAnalysised,
  });

  @override
  State<FileListWidget> createState() => _FileListWidgetState();
}

class _FileListWidgetState extends State<FileListWidget> {
  final ScrollController _scrollController = ScrollController();
  int _firstVisibleIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // 监听滚动位置 - 优化性能，减少setState调用
    _scrollController.addListener(() {
      final firstVisibleIndex =
          _scrollController.position.minScrollExtent == _scrollController.offset
              ? 0
              : (_scrollController.offset /
                      _scrollController.position.maxScrollExtent *
                      widget.filteredFileList.length)
                  .floor();

      if (firstVisibleIndex != _firstVisibleIndex && mounted) {
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

  Widget _buildFileListRow(File file, TimeAnalysisResult? analysisResult) {
    return RepaintBoundary(
      child: ListTile(
        onLongPress: () {
          // 处理长按事件，例如复制文件路径
          Clipboard.setData(ClipboardData(text: file.path));
          // 显示复制成功提示
          notification.show(msg: '文件路径已复制到剪贴板：${file.path}');
        },
        leading: const Icon(Icons.insert_drive_file, size: 20),
        title: Row(
          children: [
            Flexible(
              child: SelectionArea(
                child: Text(
                  file.path.split(Platform.pathSeparator).last,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        subtitle: SelectionArea(
          child: Text(
            file.path,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
        case TimeAnalysisStatus.fixed:
          msgText = SelectableText('已修正: ${_formatDateTime(result.suggestedTime)}');
          msgIcon = const Icon(Icons.check_circle, size: 12, color: Colors.green);
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

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.filteredFileList;

    if (filteredList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('空',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Scrollbar(
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
                final originalIndex = widget.originalFileList.indexOf(file);
                TimeAnalysisResult? analysisResult;

                // 查找当前文件的时间分析结果
                if (originalIndex >= 0 &&
                    originalIndex < widget.fileListTimeAnalysised.length) {
                  analysisResult = widget.fileListTimeAnalysised[originalIndex];
                }

                return Column(
                  children: [
                    _buildFileListRow(file, analysisResult),
                    if (index < filteredList.length - 1)
                      const Divider(height: 1),
                  ],
                );
              },
            ),
          ),
        ),
        if (filteredList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('总计: ${widget.fileListTimeAnalysised.length} 个文件'),
                Text('当前位置: $_firstVisibleIndex/${filteredList.length}'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}