import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/weather_service.dart';
import 'package:smart_tourist_app/models/weather_data_model.dart';

class WeatherInfoSheet extends StatelessWidget {
  const WeatherInfoSheet({super.key});

  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return Icons.cloud_outlined;
    
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'partially cloudy':
        return Icons.cloud_queue;
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
        return Icons.water_drop;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'mist':
      case 'fog':
        return Icons.foggy;
      default:
        return Icons.cloud_outlined;
    }
  }

  Color _getWeatherColor(String? condition) {
    if (condition == null) return Colors.blue;
    
    switch (condition.toLowerCase()) {
      case 'clear':
        return Colors.orange;
      case 'partially cloudy':
        return Colors.blueGrey;
      case 'cloudy':
        return Colors.grey;
      case 'rain':
        return Colors.blue;
      case 'snow':
        return Colors.lightBlue;
      case 'thunderstorm':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherService = Provider.of<WeatherService>(context);
    
    if (!weatherService.hasData) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.blue.shade300,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Weather Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading weather data...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final currentHour = weatherService.currentHour;
    if (currentHour == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.blue.shade300,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Weather Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Icon(Icons.error, size: 60, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Weather data unavailable',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final condition = currentHour.conditions ?? 'Unknown';
    final temp = currentHour.temp?.toInt() ?? 0;
    final feelsLike = currentHour.feelslike?.toInt() ?? 0;
    final windSpeed = currentHour.windspeed?.toInt() ?? 0;
    final humidity = currentHour.humidity?.toInt() ?? 0;
    final visibility = currentHour.visibility?.toInt() ?? 0;
    final pressure = currentHour.pressure?.toInt() ?? 0;
    final cloudCover = currentHour.cloudcover?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade300,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weather Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Icon(
            _getWeatherIcon(condition),
            size: 60,
            color: _getWeatherColor(condition),
          ),
          const SizedBox(height: 16),
          Text(
            condition,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${temp}°C',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Feels like ${feelsLike}°C',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(Icons.air, 'Wind', '$windSpeed km/h'),
              _buildWeatherDetail(Icons.water_drop, 'Humidity', '$humidity%'),
              _buildWeatherDetail(Icons.visibility, 'Visibility', '$visibility km'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(Icons.speed, 'Pressure', '$pressure mb'),
              _buildWeatherDetail(Icons.cloud, 'Clouds', '$cloudCover%'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSafetyIndicator(context),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyIndicator(BuildContext context) {
    final weatherService = Provider.of<WeatherService>(context, listen: false);
    final safetyScore = weatherService.calculateSafetyScore();
    final safetyText = weatherService.getSafetyStatusText();
    final safetyDescription = weatherService.getSafetyStatusDescription();
    
    Color scoreColor;
    if (safetyScore > 75) {
      scoreColor = Colors.green;
    } else if (safetyScore > 50) {
      scoreColor = Colors.lightGreen;
    } else if (safetyScore > 25) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Text(
            'Safety Assessment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$safetyScore/100',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            safetyText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            safetyDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}