import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/services/travel_cache_service.dart';

void main() {
  group('TravelCacheService', () {
    late TravelCacheService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = TravelCacheService();
      await service.init();
    });

    test('should return null for unknown route', () {
      final duration = service.getRouteDuration('Stockholm', 'Uppsala');
      expect(duration, null);
    });

    test('should save and retrieve route duration', () async {
      await service.saveRoute(from: 'Stockholm', to: 'Uppsala', minutes: 55);

      final duration = service.getRouteDuration('Stockholm', 'Uppsala');
      expect(duration, 55);
    });

    test('should retrieve reverse route when querying', () async {
      await service.saveRoute(from: 'Stockholm', to: 'Uppsala', minutes: 55);

      // Reverse caching: saving A->B also saves B->A
      // Use getMinutes for canonical API
      final reverseDuration = service.getMinutes('Uppsala', 'Stockholm');
      expect(reverseDuration, 55);
      
      // getRouteDuration also works (delegates to getMinutes)
      final reverseDurationLegacy = service.getRouteDuration('Uppsala', 'Stockholm');
      expect(reverseDurationLegacy, 55);
    });

    test('should match routes case-insensitively and ignoring whitespace', () async {
      await service.saveRoute(from: '  Stockholm  ', to: 'Uppsala', minutes: 55);

      final duration = service.getRouteDuration('stockholm', 'uppsala');
      expect(duration, 55);
    });

    test('should update existing route', () async {
      await service.saveRoute(from: 'Stockholm', to: 'Uppsala', minutes: 55);
      await service.saveRoute(from: 'Stockholm', to: 'Uppsala', minutes: 60);

      final duration = service.getRouteDuration('Stockholm', 'Uppsala');
      expect(duration, 60);
    });
  });
}
