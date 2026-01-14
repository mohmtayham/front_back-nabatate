import 'package:flutter/material.dart';
import 'package:nabtatcompany/generated/l10n.dart';

class EmployeeTable extends StatelessWidget {
  final List employees;
  final Function(Map) onEdit;
  final Function(int, String) onDelete;
  final Function(int, String) onViewAttachments;
  final Function(Map) onViewDetails;

  const EmployeeTable({
    super.key,
    required this.employees,
    required this.onEdit,
    required this.onDelete,
    required this.onViewAttachments,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return _buildEmptyState(context);
    }

    final s = S.of(context);

    return DataTable(
      columns: [
        DataColumn(label: Text(s.col_id, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(s.col_sn, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(s.col_name, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(s.col_iqamah, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(s.col_id_number, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(s.col_nationality, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(s.col_phone, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(s.col_actions, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: employees.map<DataRow>((e) => DataRow(
        cells: [
          DataCell(Text(e['id'].toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
          DataCell(Text(e['sn']?.toString() ?? '-')),
          DataCell(
            Tooltip(
              message: e['id_name'] ?? '',
              child: Text(
                e['id_name'] ?? 'Unknown',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          DataCell(Text(e['iqamah_number']?.toString() ?? '-')),
          DataCell(Text(e['id_number']?.toString() ?? '-')),
          DataCell(Text(e['nationality']?.toString() ?? '-')),
          DataCell(Text(e['phone_number']?.toString() ?? '-')),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  tooltip: s.action_edit,
                  onPressed: () => onEdit(e),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  tooltip: s.action_delete,
                  onPressed: () => onDelete(e['id'], e['id_name'] ?? 'Unknown'),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.attach_file,
                  color: Colors.green,
                  tooltip: s.action_attachments,
                  onPressed: () => onViewAttachments(e['id'], e['id_name'] ?? 'Unknown'),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.visibility,
                  color: Colors.orange,
                  tooltip: s.action_view_details,
                  onPressed: () => onViewDetails(e),
                ),
              ],
            ),
          ),
        ],
      )).toList(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      color: color,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            s.noEmployeesFound,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}