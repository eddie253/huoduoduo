import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile_flutter/core/navigation/map_navigation_preflight_port.dart';

import '../application/maps_view_model.dart';

typedef LaunchExternalPort = Future<bool> Function(Uri uri, LaunchMode mode);

class MapsPage extends StatefulWidget {
  const MapsPage({
    super.key,
    required MapNavigationPreflightPort mapPreflight,
    LaunchExternalPort? launchExternal,
  })  : _mapPreflight = mapPreflight,
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
  final _viewModel = const MapsViewModel();
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
    final (:uri, :error) = _viewModel.buildMapUri(
      _latitudeController.text,
      _longitudeController.text,
    );
    if (error != null) {
      _showMessage(error);
      return;
    }

    final preflight = await widget._mapPreflight.ensureReady();
    if (!preflight.allowed) {
      _showMessage(preflight.message ?? 'Navigation preflight failed.');
      return;
    }

    if (!await widget._launchExternal(uri!, LaunchMode.externalApplication)) {
      _showMessage('Failed to open map application.');
    }
  }

  Future<void> _dialPhone() async {
    final (:phone, :error) = _viewModel.sanitizePhone(_phoneController.text);
    if (error != null) {
      _showMessage(error);
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
