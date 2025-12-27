import 'dart:ui';
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

    // Correctly handle Loading State
    // Correctly handle Loading State
    if (weatherService.isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade900.withOpacity(0.95),
              Colors.deepPurpleAccent.shade200.withOpacity(0.95)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
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
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Fetching live updates...',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      );
    }

    // Handle Error State
    // Handle Error State
    if (weatherService.errorMessage.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9), // Keep red but make it elegant
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Connection Error',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Icon(Icons.cloud_off, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              weatherService.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Dismiss'),
            )
          ],
        ),
      );
    }

    // Handle No Data (but no error)
    if (!weatherService.hasData) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade800.withOpacity(0.9),
              Colors.deepPurpleAccent.shade100.withOpacity(0.9)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Weather Info',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context))
            ]),
            const SizedBox(height: 30),
            const Icon(Icons.location_disabled,
                size: 50, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'No weather data available.',
              style: TextStyle(fontSize: 16, color: Colors.white),
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
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade900.withOpacity(0.95),
            Colors.deepPurpleAccent.shade200.withOpacity(0.95)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
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
            const Divider(color: Colors.white24, height: 32),
            Icon(
              _getWeatherIcon(condition),
              size: 70,
              color: _getWeatherColor(condition),
            ),
            const SizedBox(height: 16),
            Text(
              condition,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),
            Text(
              '${temp}°C',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Feels like ${feelsLike}°C',
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(Icons.air, 'Wind', '$windSpeed km/h'),
                _buildWeatherDetail(Icons.water_drop, 'Humidity', '$humidity%'),
                _buildWeatherDetail(
                    Icons.visibility, 'Visibility', '$visibility km'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(Icons.speed, 'Pressure', '$pressure mb'),
                _buildWeatherDetail(Icons.cloud, 'Clouds', '$cloudCover%'),
              ],
            ),
            const SizedBox(height: 32),
            _buildSafetyIndicator(context),
          ],
        ),
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
      scoreColor = Colors.greenAccent;
    } else if (safetyScore > 50) {
      scoreColor = Colors.lightGreenAccent;
    } else if (safetyScore > 25) {
      scoreColor = Colors.orangeAccent;
    } else {
      scoreColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety, color: scoreColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Safety Assessment',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$safetyScore/100',
            style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: scoreColor,
                shadows: [
                  Shadow(
                    color: scoreColor.withOpacity(0.5),
                    blurRadius: 10,
                  )
                ]),
          ),
          const SizedBox(height: 4),
          Text(
            safetyText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            safetyDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}
