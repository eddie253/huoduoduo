import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProxyMenuPage extends StatelessWidget {
  const ProxyMenuPage({super.key});

  static const Key mateButtonKey = Key('proxy.menu.mate');
  static const Key kpiButtonKey = Key('proxy.menu.kpi');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('代理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _ProxyEntryCard(
            key: mateButtonKey,
            icon: Icons.group_rounded,
            title: '媒合',
            subtitle: 'pxy/mate.aspx',
            onTap: () => context.pop('pxy/mate.aspx'),
          ),
          const SizedBox(height: 12),
          _ProxyEntryCard(
            key: kpiButtonKey,
            icon: Icons.assessment_rounded,
            title: 'KPI',
            subtitle: 'pxy/kpi.aspx',
            onTap: () => context.pop('pxy/kpi.aspx'),
          ),
        ],
      ),
    );
  }
}

class _ProxyEntryCard extends StatelessWidget {
  const _ProxyEntryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
