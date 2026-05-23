import 'package:flutter/material.dart';
import 'package:dayz/demo/demo_entry.dart';

class DebugHome extends StatelessWidget {
  final List<DemoEntry> entries;

  const DebugHome({
    super.key,
    this.entries = const [],
  });

  @override
  Widget build(BuildContext context) {
    // If entries is empty, use the global demos list
    final list = entries.isNotEmpty ? entries : demos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Home'),
      ),
      body: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final entry = list[index];
          return ListTile(
            title: Text(entry.title),
            subtitle: entry.subtitle != null ? Text(entry.subtitle!) : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: entry.builder),
              );
            },
          );
        },
      ),
    );
  }
}
