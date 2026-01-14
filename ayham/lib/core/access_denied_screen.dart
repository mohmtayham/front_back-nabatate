import 'package:flutter/material.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 70, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'ليس لديك صلاحية للوصول إلى هذه الصفحة',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
