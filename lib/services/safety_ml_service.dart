import 'package:smart_tourist_app/models/weather_data_model.dart';

class SafetyMLService {
  /*
   * Calculates a 'Safety Score' (0-100) using a heuristic model.
   * 
   * Inputs:
   * - Weather Data (Temp, Wind, Rain, Severity)
   * - Location Status (Tracking, Panic, Offline)
   * 
   * Logic:
   * - Base Score: 100
   * - Weather Penalties:
   *    - Extreme Temp: -30
   *    - Heavy Rain: -20
   *    - High Wind: -20
   *    - Poor Visibility: -15
   * - Location Context Modifiers:
   *    - 'panic': Force Score to 10 (Critical)
   *    - 'tracking': +10 Bonus (Verified Safe Location)
   *    - 'inactive': -10 Penalty (Uncertainty)
   */
  static Map<String, dynamic> analyzeSafety({
    required Hours? currentWeather,
    required String locationStatus,
  }) {
    // 1. Handle Critical Override (Panic Mode)
    if (locationStatus.toLowerCase() == 'panic') {
      return {
        'score': 10,
        'level': 'Critical',
        'color': 0xFFFF0000, // Red
        'reason': 'User triggered Panic Button',
      };
    }

    double score = 100;
    List<String> riskFactors = [];

    // 2. Weather Analysis (If available)
    if (currentWeather != null) {
      // Temperature
      if (currentWeather.temp != null) {
        double temp = currentWeather.temp!;
        if (temp > 40 || temp < -5) {
          score -= 30;
          riskFactors.add('Extreme Temperature ($temp°C)');
        } else if (temp > 35 || temp < 0) {
          score -= 10;
          riskFactors.add('Challenging Temperature ($temp°C)');
        }
      }

      // Wind
      if (currentWeather.windspeed != null) {
        double wind = currentWeather.windspeed!;
        if (wind > 50) {
          score -= 25;
          riskFactors.add('Dangerous Winds (${wind.toInt()} km/h)');
        } else if (wind > 30) {
          score -= 10;
          riskFactors.add('Strong Breeze');
        }
      }

      // Precipitation
      if (currentWeather.precip != null && currentWeather.precip! > 0) {
        score -= 15;
        riskFactors.add('Precipitation detected');
      }

      // Visibility
      if (currentWeather.visibility != null && currentWeather.visibility! < 5) {
        score -= 15;
        riskFactors.add('Low Visibility');
      }

      // Cloud Cover (Minor factor)
      if (currentWeather.cloudcover != null &&
          currentWeather.cloudcover! > 90) {
        score -= 5;
      }
    } else {
      score -= 20; // Penalty for missing weather data (Uncertainty)
      riskFactors.add('Weather data unavailable');
    }

    // 3. Location Context Analysis
    if (locationStatus.toLowerCase() == 'tracking' ||
        locationStatus.contains('active')) {
      // Bonus for confirmed live tracking - implies user is connected and sending data
      score += 5;
    } else {
      // Penalty for stale or offline data
      score -= 15;
      riskFactors.add('Location tracking inactive');
    }

    // Clamp score
    score = score.clamp(0, 100);

    // 4. Determine Level and Color
    String level;
    int colorValue;

    if (score >= 80) {
      level = 'Safe';
      colorValue = 0xFF4CAF50; // Green
    } else if (score >= 50) {
      level = 'Moderate';
      colorValue = 0xFFFFC107; // Amber/Orange
    } else if (score >= 25) {
      level = 'High Risk';
      colorValue = 0xFFFF9800; // Deep Orange
    } else {
      level = 'Severe';
      colorValue = 0xFFD32F2F; // Red
    }

    return {
      'score': score.toInt(),
      'level': level,
      'color': colorValue,
      'details': riskFactors.isEmpty
          ? 'Conditions are optimal.'
          : riskFactors.join(', '),
    };
  }
}
