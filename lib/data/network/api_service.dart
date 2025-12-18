import 'dart:convert';
import 'dart:io';
import '../app_exceptions.dart';
import 'base_api_service.dart';

class ApiService extends BaseApiService {
  @override
  Future<dynamic> getApi(String url) async {
    dynamic jsonResponse;
    try {
      final uri = Uri.parse(url);
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        jsonResponse = jsonDecode(responseBody);
      } else {
        jsonResponse = _handleErrorResponse(response.statusCode);
      }
    } on SocketException {
      throw InternetException('No Internet');
    } on Exception {
      throw FetchDataException('Error occurred while communicating with server');
    }
    return jsonResponse;
  }

  dynamic _handleErrorResponse(int statusCode) {
    switch (statusCode) {
      case 400:
        throw FetchDataException('Bad Request');
      case 401:
        throw FetchDataException('Unauthorized');
      case 403:
        throw FetchDataException('Forbidden');
      case 404:
        throw FetchDataException('Not Found');
      case 500:
        throw ServerException('Internal Server Error');
      default:
        throw FetchDataException(
            'Error occurred while communicating with server with status code $statusCode');
    }
  }
}