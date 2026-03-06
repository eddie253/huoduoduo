import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_service.dart';

final locationServiceProvider = Provider<LocationServicePort>((ref) {
  return const LocationService();
});
