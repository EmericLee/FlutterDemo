import 'package:flutter/material.dart';
import 'time_analyzer.dart';
import 'wp_file_time_fixer.dart';

/// 扫描状态面板组件
class ScanStatusPanel extends StatelessWidget {
  final bool isScanning;
  final int fileCount;
  final bool isTimeAnalysising;
  final List<TimeAnalysisResult> fileListTimeAnalysised;
  final FileFilterType currentFilter;
  final VoidCallback onStopScan;
  final Function(FileFilterType) onFilterChange;

  const ScanStatusPanel({
    super.key,
    required this.isScanning,
    required this.fileCount,
    required this.isTimeAnalysising,
    required this.fileListTimeAnalysised,
    required this.currentFilter,
    required this.onStopScan,
    required this.onFilterChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // 扫描状态显示
          if (isScanning) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            Text('发现文件： $fileCount '),
          ],
          
          // 时间分析状态显示
          if (isTimeAnalysising) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '已分析 ${fileListTimeAnalysised.length} / $fileCount ',
            ),
          ],
          
          // 扫描完成后显示过滤按钮组
          if (!isTimeAnalysising && fileListTimeAnalysised.isNotEmpty) ...[
            // 过滤按钮组
            Container(
              // padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              // decoration: BoxDecoration(
              //   border: Border.all(color: Colors.grey.shade300),
              //   borderRadius: BorderRadius.circular(20),
              // ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,  
                children: [
                  // 全部按钮
                  _buildFilterButton(
                    '全部',
                    FileFilterType.all,
                    Icons.filter_list,
                    fileListTimeAnalysised.length,
                  ),
                  // 一致按钮
                  _buildFilterButton(
                    '一致',
                    FileFilterType.consistent,
                    Icons.check_circle,
                    fileListTimeAnalysised.where((r) => r.status == TimeAnalysisStatus.consistent).length,
                    Colors.green,
                  ),
                  // 修正按钮
                  _buildFilterButton(
                    '需修正',
                    FileFilterType.needsFix,
                    Icons.timer_rounded,
                    fileListTimeAnalysised.where((r) => r.status == TimeAnalysisStatus.needsFix).length,
                    Colors.orange,
                  ),
                  // 已经修正按钮
                  _buildFilterButton(
                    '已修正',
                    FileFilterType.fixed,
                    Icons.timer,
                    fileListTimeAnalysised.where((r) => r.status == TimeAnalysisStatus.fixed).length,
                    Colors.green,
                  ),
                  // 无法解析按钮
                  _buildFilterButton(
                    '无法解析',
                    FileFilterType.cannotJudge,
                    Icons.help_outline,
                    fileListTimeAnalysised.where((r) => r.status == TimeAnalysisStatus.cannotJudge).length,
                    Colors.grey,
                  ),
                ],
              ),
            ),
          ],
          
          // 停止按钮
          if (isScanning || isTimeAnalysising) ...[
            SizedBox(width: 8),
            Tooltip(
              message: '点击停止扫描',
              child: InkWell(
                onTap: onStopScan,
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
                ),
              ),
            )
          ],
        ],
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
    final isActive = currentFilter == filterType;
    final color = activeColor ?? Colors.blue; // 使用默认颜色而不是Theme.of(context).primaryColor

    if(count == 0){
      return Container();
    }

    return Tooltip(
      message: '$label: $count 个文件',
      child: InkWell(
        onTap: () => onFilterChange(filterType),
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
              // SizedBox(width: 4),
              // Text(
              //   '$label',
              //   style: TextStyle(
              //     fontSize: 12,
              //     color: isActive ? color : Colors.grey.shade700,
              //     fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              //   ),
              // ),
              if (count >= 0) ...[
                SizedBox(width: 8),
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
}