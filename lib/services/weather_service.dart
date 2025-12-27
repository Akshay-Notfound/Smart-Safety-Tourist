import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_tourist_app/models/weather_data_model.dart';
import 'package:smart_tourist_app/repository/weather_repository.dart';

class WeatherService extends ChangeNotifier {
  final WeatherRepository _weatherRepository = WeatherRepository();

  WeatherDataModel? _weatherModel;
  Hours? _currentHour;
  int _currentIndex = 0;
  bool _isLoading = false;
  String _errorMessage = '';

  WeatherDataModel? get weatherModel => _weatherModel;
  Hours? get currentHour => _currentHour;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasData => _weatherModel != null;

  Future<void> fetchWeatherData(double latitude, double longitude) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final response =
          await _weatherRepository.fetchWeatherData(latitude, longitude);
      _weatherModel = response;

      // Set current hour data
      if (_weatherModel != null &&
          _weatherModel!.days != null &&
          _weatherModel!.days!.isNotEmpty &&
          _weatherModel!.days![0].hours != null) {
        // Find current hour or use first hour
        // Find current hour
        final currentHour = DateTime.now().hour;
        for (int i = 0; i < _weatherModel!.days![0].hours!.length; i++) {
          // The API likely returns hour as "HH:00:00" or similar, or we can assume index matches hour if 24h format?
          // Looking at standard weather APIs, 'datetime' is often "HH:mm:ss".
          // Let's parse the datetime to be safe, or check if specific hour field exists.
          // Assuming 'datetime' contains the hour or index correlates.
          // Actually, let's parse the string from the model.
          final hourData = _weatherModel!.days![0].hours![i];
          if (hourData.datetime != null) {
            final hourString = hourData.datetime!
                .split(':')[0]; // Extract "14" from "14:00:00"
            final hourInt = int.tryParse(hourString);

            if (hourInt == currentHour) {
              _currentHour = hourData;
              _currentIndex = i;
              break;
            }
          }
        }

        // Fallback: If no match (shouldn't happen for 24h data), keep default (first one or null) but ensure we set something if possible.
        if (_currentHour == null && _weatherModel!.days![0].hours!.isNotEmpty) {
          _currentHour = _weatherModel!.days![0].hours![0];
          _currentIndex = 0;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Weather fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeatherDataByCity(String cityName) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final response =
          await _weatherRepository.fetchWeatherDataByCity(cityName);
      _weatherModel = response;

      // Set current hour data
      if (_weatherModel != null &&
          _weatherModel!.days != null &&
          _weatherModel!.days!.isNotEmpty &&
          _weatherModel!.days![0].hours != null) {
        // Find current hour or use first hour
        // Find current hour
        final currentHour = DateTime.now().hour;
        for (int i = 0; i < _weatherModel!.days![0].hours!.length; i++) {
          final hourData = _weatherModel!.days![0].hours![i];
          if (hourData.datetime != null) {
            final hourString = hourData.datetime!.split(':')[0];
            final hourInt = int.tryParse(hourString);

            if (hourInt == currentHour) {
              _currentHour = hourData;
              _currentIndex = i;
              break;
            }
          }
        }
        // Fallback
        if (_currentHour == null && _weatherModel!.days![0].hours!.isNotEmpty) {
          _currentHour = _weatherModel!.days![0].hours![0];
          _currentIndex = 0;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Weather fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getHour(int index) {
    if (_weatherModel != null &&
        _weatherModel!.days != null &&
        _weatherModel!.days!.isNotEmpty &&
        _weatherModel!.days![0].hours != null &&
        index < _weatherModel!.days![0].hours!.length) {
      final datetime =
          _weatherModel!.days![0].hours![index].datetime.toString();
      return _formatTime(datetime);
    }
    return '--:--';
  }

  String _formatTime(String datetime) {
    // Extract time from datetime string (assuming format like "2023-06-15T14:00:00")
    try {
      final parts = datetime.split('T');
      if (parts.length > 1) {
        final timeParts = parts[1].split(':');
        if (timeParts.length > 1) {
          return '${timeParts[0]}:${timeParts[1]}';
        }
      }
    } catch (e) {
      // Return original if parsing fails
      return datetime;
    }
    return datetime;
  }

  String getAddress() {
    if (_weatherModel != null) {
      return '${_weatherModel!.address ?? ''}\n${_weatherModel!.timezone ?? ''}';
    }
    return 'Location Unknown';
  }

  String getCondition() {
    if (_currentHour != null) {
      return _currentHour!.conditions?.toString() ?? 'Unknown';
    }
    return 'Unknown';
  }

  String getCurrentTemp() {
    if (_currentHour != null && _currentHour!.temp != null) {
      return _currentHour!.temp.toInt().toString();
    }
    return '--';
  }

  String getFeelsLike() {
    if (_currentHour != null && _currentHour!.feelslike != null) {
      return _currentHour!.feelslike.toStringAsFixed(0);
    }
    return '--';
  }

  String getCloudCover() {
    if (_currentHour != null && _currentHour!.cloudcover != null) {
      return _currentHour!.cloudcover.toInt().toString();
    }
    return '--';
  }

  String getWindSpeed() {
    if (_currentHour != null && _currentHour!.windspeed != null) {
      return _currentHour!.windspeed.toInt().toString();
    }
    return '--';
  }

  String getHumidity() {
    if (_currentHour != null && _currentHour!.humidity != null) {
      return _currentHour!.humidity.toInt().toString();
    }
    return '--';
  }

  String getVisibility() {
    if (_currentHour != null && _currentHour!.visibility != null) {
      return _currentHour!.visibility.toInt().toString();
    }
    return '--';
  }

  String getPressure() {
    if (_currentHour != null && _currentHour!.pressure != null) {
      return _currentHour!.pressure.toInt().toString();
    }
    return '--';
  }

  void setHour(int index) {
    if (_weatherModel != null &&
        _weatherModel!.days != null &&
        _weatherModel!.days!.isNotEmpty &&
        _weatherModel!.days![0].hours != null &&
        index < _weatherModel!.days![0].hours!.length) {
      _currentIndex = index;
      _currentHour = _weatherModel!.days![0].hours![index];
      notifyListeners();
    }
  }

  // Calculate safety score based on weather conditions
  int calculateSafetyScore() {
    if (_currentHour == null) return 50;

    int score = 100;

    // Temperature factors
    if (_currentHour!.temp != null) {
      final temp = _currentHour!.temp.toDouble();
      if (temp > 40 || temp < -10) {
        score -= 30; // Extreme temperatures
      } else if (temp > 35 || temp < 0) {
        score -= 15; // Hot or cold
      }
    }

    // Wind speed factor
    if (_currentHour!.windspeed != null) {
      final windSpeed = _currentHour!.windspeed.toDouble();
      if (windSpeed > 50) {
        score -= 40; // Very strong winds
      } else if (windSpeed > 30) {
        score -= 20; // Strong winds
      }
    }

    // Precipitation factor
    if (_currentHour!.precip != null && _currentHour!.precip > 0) {
      score -= 15; // Rain/snow
    }

    // Visibility factor
    if (_currentHour!.visibility != null) {
      final visibility = _currentHour!.visibility.toDouble();
      if (visibility < 1) {
        score -= 30; // Poor visibility
      } else if (visibility < 5) {
        score -= 15; // Reduced visibility
      }
    }

    // Cloud cover factor
    if (_currentHour!.cloudcover != null) {
      final cloudCover = _currentHour!.cloudcover.toDouble();
      if (cloudCover > 80) {
        score -= 10; // Overcast
      }
    }

    return score.clamp(0, 100);
  }

  String getSafetyStatusText() {
    final score = calculateSafetyScore();
    if (score > 75) return "Very Safe";
    if (score > 50) return "Safe";
    if (score > 25) return "Caution Advised";
    return "Unsafe Conditions";
  }

  String getSafetyStatusDescription() {
    final score = calculateSafetyScore();
    if (score > 75) return "Excellent weather conditions for travel";
    if (score > 50) return "Good weather conditions with minor concerns";
    if (score > 25) return "Some weather concerns, exercise caution";
    return "Poor weather conditions, consider postponing outdoor activities";
  }
}
