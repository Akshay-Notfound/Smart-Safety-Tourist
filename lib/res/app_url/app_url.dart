class AppUrl {
  // Using Visual Crossing Weather API - more comprehensive than OpenWeatherMap
  static const String baseUrl = 'https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline';
  
  // API key from your generated code
  static const String apiKey = 'RXV3DU74MYRUWSL2JYQZNUDN7';
  
  // Example URL with parameters from your generated code
  static String getWeatherUrl(double latitude, double longitude) {
    return '$baseUrl/$latitude,$longitude?key=$apiKey&unitGroup=metric&include=alerts,current,days,minutes&contentType=json';
  }
  
  // For city-based search (alternative)
  static String getWeatherUrlByCity(String cityName) {
    return '$baseUrl/$cityName?key=$apiKey&unitGroup=metric&include=alerts,current,days,minutes&contentType=json';
  }
}