class MapsViewModel {
  const MapsViewModel();

  ({Uri? uri, String? error}) buildMapUri(
    String latitudeRaw,
    String longitudeRaw,
  ) {
    final lat = double.tryParse(latitudeRaw.trim());
    final lng = double.tryParse(longitudeRaw.trim());
    if (lat == null ||
        lng == null ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return (uri: null, error: 'Latitude/longitude format is invalid.');
    }
    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      <String, String>{
        'api': '1',
        'destination': '$lat,$lng',
        'travelmode': 'driving',
        'dir_action': 'navigate',
      },
    );
    return (uri: uri, error: null);
  }

  ({String? phone, String? error}) sanitizePhone(String raw) {
    final sanitized = raw.replaceAll(RegExp(r'[^0-9+#*]'), '');
    if (sanitized.length < 5) {
      return (phone: null, error: 'Phone number is invalid.');
    }
    return (phone: sanitized, error: null);
  }
}
