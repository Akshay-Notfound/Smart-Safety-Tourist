import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tourist_app/repository/weather_repository.dart';
import 'package:smart_tourist_app/res/app_url/app_url.dart';

void main() {
  group('Weather API Tests', () {
    test('AppUrl generates correct URL', () {
      final url = AppUrl.getWeatherUrl(40.7128, -74.0060);
      expect(url, contains('weather.visualcrossing.com'));
      expect(url, contains('40.7128,-74.0060'));
      expect(url, contains('key=RXV3DU74MYRUWSL2JYQZNUDN7'));
      expect(url, contains('unitGroup=metric'));
      expect(url, contains('include=alerts,current,days,minutes'));
    });

    test('WeatherRepository can be instantiated', () {
      final repository = WeatherRepository();
      expect(repository, isNotNull);
    });
  });
}