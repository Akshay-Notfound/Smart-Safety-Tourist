import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  // Cloudinary configuration
  static const String cloudName = 'dk9fbodpq';
  static const String apiKey = '183653851345643';
  static const String apiSecret = 'Rzw6_ZyjLuIS51FNbs3QrWjVQqY';
  static const String preset = 'Smart_Tourist_App';
  static const String baseUrl = 'https://api.cloudinary.com/v1_1';
  
  // Upload a file to Cloudinary
  static Future<Map<String, dynamic>?> uploadFile(File file) async {
    try {
      final url = Uri.parse('$baseUrl/$cloudName/image/upload');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      
      // Add required fields for signed upload
      request.fields['upload_preset'] = preset;
      request.fields['api_key'] = apiKey;
      
      // Add timestamp for signed requests
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      request.fields['timestamp'] = timestamp;
      
      // Create signature for signed upload
      final signature = _generateSignature(request.fields);
      request.fields['signature'] = signature;
      
      // Add overwrite parameter
      request.fields['overwrite'] = 'true';
      
      print('Uploading to Cloudinary with params:');
      request.fields.forEach((key, value) {
        // Don't print sensitive data
        if (key != 'api_key' && key != 'signature' && key != 'timestamp') {
          print('  $key: $value');
        }
      });
      
      // Add file
      final mimeType = lookupMimeType(file.path);
      final fileBytes = await file.readAsBytes();
      
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: file.path.split('/').last,
      );
      
      request.files.add(multipartFile);
      
      // Send request with timeout
      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload timeout', const Duration(seconds: 30));
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
        
        // Try to parse error message
        try {
          final errorResponse = json.decode(responseBody);
          if (errorResponse is Map && errorResponse.containsKey('error')) {
            print('Cloudinary error message: ${errorResponse['error']}');
            // Show specific error to user
            if (errorResponse['error'] is String) {
              print('Specific Cloudinary error: ${errorResponse['error']}');
            }
          }
        } catch (e) {
          print('Could not parse error response: $e');
        }
        
        return null;
      }
    } on TimeoutException catch (e) {
      print('Cloudinary upload timeout: $e');
      return null;
    } on SocketException catch (e) {
      print('Network error during Cloudinary upload: $e');
      return null;
    } on http.ClientException catch (e) {
      print('HTTP client error during Cloudinary upload: $e');
      return null;
    } catch (e) {
      print('Unexpected error uploading to Cloudinary: $e');
      return null;
    }
  }
  
  // Generate signature for signed uploads
  static String _generateSignature(Map<String, String> params) {
    // Remove upload_preset from signature calculation as it's not needed for signed uploads
    final paramsWithoutPreset = Map<String, String>.from(params);
    paramsWithoutPreset.remove('upload_preset');
    
    // Sort parameters by key
    final sortedParams = Map.fromEntries(
      paramsWithoutPreset.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    // Create signature string
    final signatureString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&') + apiSecret;
    
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