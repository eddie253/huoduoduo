import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final _latitudeController = TextEditingController(text: '25.0330');
  final _longitudeController = TextEditingController(text: '121.5654');
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openMap() async {
    final latitude = _latitudeController.text.trim();
    final longitude = _longitudeController.text.trim();
    final coordinatePattern = RegExp(r'^-?\d+(?:\.\d+)?$');
    if (!coordinatePattern.hasMatch(latitude) ||
        !coordinatePattern.hasMatch(longitude)) {
      _showMessage('Latitude/longitude format is invalid.');
      return;
    }

    final uri = Uri.https('www.google.com', '/maps/search/', <String, String>{
      'api': '1',
      'query': '$latitude,$longitude',
    });

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('Failed to open map application.');
    }
  }

  Future<void> _dialPhone() async {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9+#*]'), '');
    if (phone.length < 5) {
      _showMessage('Phone number is invalid.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('Failed to open dialer.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map & Dial')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _latitudeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _longitudeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Longitude'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map),
                label: const Text('Open Map'),
              ),
            ),
            const Divider(height: 32),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _dialPhone,
                icon: const Icon(Icons.phone),
                label: const Text('Dial Phone'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
