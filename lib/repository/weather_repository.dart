import 'package:smart_tourist_app/models/weather_data_model.dart';
import 'package:smart_tourist_app/data/network/api_service.dart';
import 'package:smart_tourist_app/res/app_url/app_url.dart';

class WeatherRepository {
  final ApiService _apiService = ApiService();

  Future<WeatherDataModel> fetchWeatherData(double latitude, double longitude) async {
    try {
      final url = AppUrl.getWeatherUrl(latitude, longitude);
      final response = await _apiService.getApi(url);
      return WeatherDataModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<WeatherDataModel> fetchWeatherDataByCity(String cityName) async {
    try {
      final url = AppUrl.getWeatherUrlByCity(cityName);
      final response = await _apiService.getApi(url);
      return WeatherDataModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}