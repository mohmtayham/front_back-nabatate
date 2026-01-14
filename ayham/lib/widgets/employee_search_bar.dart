import 'package:flutter/material.dart';
import 'package:nabtatcompany/generated/l10n.dart';

class EmployeeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;

  const EmployeeSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: S.of(context).searchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          onSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => onSearch(value),
              onSubmitted: onSearch,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => onSearch(controller.text),
            icon: const Icon(Icons.search, size: 18),
            label: Text(S.of(context).search),
          ),
        ],
      ),
    );
  }
}