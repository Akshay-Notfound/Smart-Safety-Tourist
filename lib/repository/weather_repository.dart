import 'package:smart_tourist_app/models/weather_data_model.dart';
import 'package:smart_tourist_app/data/network/api_service.dart';
import 'package:smart_tourist_app/res/app_url/app_url.dart';

class WeatherRepository {
  final ApiService _apiService = ApiService();

  // Cache variables
  static WeatherDataModel? _cachedWeather;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  Future<WeatherDataModel> fetchWeatherData(
      double latitude, double longitude) async {
    // Check cache first
    if (_cachedWeather != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        print('Using cached weather data');
        return _cachedWeather!;
      }
    }

    try {
      final url = AppUrl.getWeatherUrl(latitude, longitude);
      final response = await _apiService.getApi(url);
      final weatherData = WeatherDataModel.fromJson(response);

      // Update cache
      _cachedWeather = weatherData;
      _lastFetchTime = DateTime.now();

      return weatherData;
    } catch (e) {
      // If API fails (e.g., 429 Too Many Requests), return Mock Data
      print('API Error: $e. Returning MOCK data.');
      return _getMockWeatherData();
    }
  }

  Future<WeatherDataModel> fetchWeatherDataByCity(String cityName) async {
    try {
      final url = AppUrl.getWeatherUrlByCity(cityName);
      final response = await _apiService.getApi(url);
      return WeatherDataModel.fromJson(response);
    } catch (e) {
      // Fallback to mock data on error
      print('API Error: $e. Returning MOCK data.');
      return _getMockWeatherData();
    }
  }

  // Mock Data Generator to prevent app crash
  WeatherDataModel _getMockWeatherData() {
    // Create a safe, pleasant weather state
    return WeatherDataModel(
      queryCost: 0,
      latitude: 0,
      longitude: 0,
      resolvedAddress: "Mock Location (Safe Mode)",
      address: "Safe Haven",
      timezone: "IST",
      tzoffset: 5.5,
      days: [
        Days(
          datetime: DateTime.now().toString(),
          temp: 24.0,
          feelslike: 25.0,
          humidity: 45.0,
          dew: 10.0,
          precip: 0.0,
          precipprob: 0.0,
          snow: 0.0,
          snowdepth: 0.0,
          windgust: 5.0,
          windspeed: 10.0,
          winddir: 180.0,
          pressure: 1012.0,
          cloudcover: 10.0,
          visibility: 10.0,
          solarradiation: 200.0,
          solarenergy: 5.0,
          uvindex: 3.0,
          severerisk: 0.0,
          conditions: "Clear",
          icon: "clear-day",
          stations: [],
          source: "mock",
          hours: [
            Hours(
              datetime: "12:00:00",
              datetimeEpoch: 0,
              temp: 24.0,
              feelslike: 25.0,
              humidity: 45.0,
              dew: 10.0,
              precip: 0.0,
              precipprob: 0.0,
              snow: 0.0,
              snowdepth: 0.0,
              windgust: 5.0,
              windspeed: 10.0,
              winddir: 180.0,
              pressure: 1012.0,
              cloudcover: 10.0,
              visibility: 10.0,
              solarradiation: 200.0,
              solarenergy: 5.0,
              uvindex: 3.0,
              severerisk: 0.0,
              conditions: "Clear",
              icon: "clear-day",
              stations: [],
              source: "mock",
            )
          ],
        )
      ],
    );
  }
}
