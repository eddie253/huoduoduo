import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../webview_shell/application/map_navigation_preflight_service.dart';

typedef LaunchExternalPort = Future<bool> Function(Uri uri, LaunchMode mode);

class MapsPage extends StatefulWidget {
  const MapsPage({
    super.key,
    MapNavigationPreflightPort? mapPreflight,
    LaunchExternalPort? launchExternal,
  })  : _mapPreflight =
            mapPreflight ?? const DefaultMapNavigationPreflightService(),
        _launchExternal = launchExternal ?? _defaultLaunchExternal;

  static Future<bool> _defaultLaunchExternal(Uri uri, LaunchMode mode) {
    return launchUrl(uri, mode: mode);
  }

  final MapNavigationPreflightPort _mapPreflight;
  final LaunchExternalPort _launchExternal;

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
    final latitudeRaw = _latitudeController.text.trim();
    final longitudeRaw = _longitudeController.text.trim();
    final latitude = double.tryParse(latitudeRaw);
    final longitude = double.tryParse(longitudeRaw);
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      _showMessage('Latitude/longitude format is invalid.');
      return;
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', <String, String>{
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });

    final preflight = await widget._mapPreflight.ensureReady();
    if (!preflight.allowed) {
      _showMessage(preflight.message ?? 'Navigation preflight failed.');
      return;
    }

    if (!await widget._launchExternal(uri, LaunchMode.externalApplication)) {
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
    if (!await widget._launchExternal(uri, LaunchMode.externalApplication)) {
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _longitudeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
