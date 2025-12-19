// import 'dart:io'; // Removed for Web compatibility
import 'dart:async';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Cloudinary configuration
  static const String cloudName = 'dk9fbodpq';
  static const String apiKey = '183653851345643';
  static const String apiSecret = 'Rzw6_ZyjLuIS51FNbs3QrWjVQqY';
  static const String preset = 'Smart_Tourist_App';
  static const String baseUrl = 'https://api.cloudinary.com/v1_1';

  // Upload a file to Cloudinary
  static Future<Map<String, dynamic>?> uploadFile(XFile file) async {
    try {
      final url = Uri.parse('$baseUrl/$cloudName/image/upload');

      // Create multipart request
      final request = http.MultipartRequest('POST', url);

      // Prepare parameters for signature
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = {
        'timestamp': timestamp.toString(),
        'upload_preset': preset,
      };

      // Generate signature
      final signature = _generateSignature(params);

      // Add required fields for signed upload
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      request.fields['upload_preset'] = preset;

      // Add file
      final fileBytes = await file.readAsBytes();

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: file.name,
      );

      request.files.add(multipartFile);

      // Send request with timeout
      final response = await request.send().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('Upload timeout', const Duration(seconds: 45));
        },
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        print('Cloudinary upload successful');
        return jsonResponse;
      } else {
        print('Cloudinary upload failed with status: ${response.statusCode}');
        print('Response: $responseBody');

        throw Exception(
            'Upload failed: ${response.statusCode} - $responseBody');
      }
    } on TimeoutException catch (e) {
      print('Cloudinary upload timeout: $e');
      throw Exception('Connection timed out. Please check your internet.');
      // } on SocketException catch (e) { // Removed for Web compatibility
      //   print('Network error during Cloudinary upload: $e');
      //   throw Exception('Network error. Please check your internet connection.');
    } on http.ClientException catch (e) {
      print('HTTP client error during Cloudinary upload: $e');
      throw Exception('Connection failed. Please try again.');
    } catch (e) {
      print('Unexpected error uploading to Cloudinary: $e');
      throw Exception('Upload failed: $e');
    }
  }

  // Generate signature for signed uploads
  static String _generateSignature(Map<String, String> params) {
    // Clone params to avoid modifying the original map
    final paramsToSign = Map<String, String>.from(params);
    // paramsToSign.remove('upload_preset'); // Fixed: Do NOT remove upload_preset for signed uploads

    // Sort parameters by key
    final sortedParams = Map.fromEntries(
        paramsToSign.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

    // Create signature string
    final signatureString = sortedParams.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join('&') +
        apiSecret;

    // Generate SHA-1 hash
    return sha1.convert(utf8.encode(signatureString)).toString();
  }

  // Get the secure URL of an uploaded resource
  static String? getSecureUrl(Map<String, dynamic> response) {
    return response['secure_url'] as String?;
  }

  // Get the public ID of an uploaded resource
  static String? getPublicId(Map<String, dynamic> response) {
    return response['public_id'] as String?;
  }
}
