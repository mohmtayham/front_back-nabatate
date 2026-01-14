import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final int totalItems;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRefresh;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.totalItems,
    required this.onPrevious,
    required this.onNext,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Employees: $totalItems',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: currentPage > 1 ? onPrevious : null,
                color: currentPage > 1 ? Colors.blue : Colors.grey,
                tooltip: 'Previous Page',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page $currentPage of $lastPage',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: currentPage < lastPage ? onNext : null,
                color: currentPage < lastPage ? Colors.blue : Colors.grey,
                tooltip: 'Next Page',
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}