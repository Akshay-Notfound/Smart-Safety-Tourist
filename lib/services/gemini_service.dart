import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Ideally, this should be in an Env file, but for this task we use it directly as provided.
  static const String _apiKey = 'AIzaSyDsbCrNQK3JQReyrNUTFEaKQmKceQ1YL54';

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );
    _chatSession = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      return response.text ?? "I'm sorry, I couldn't understand that.";
    } catch (e) {
      print('Gemini Error: $e');
      if (e.toString().contains('403') ||
          e.toString().contains('PERMISSION_DENIED')) {
        return "Error: API Key Restricted. Please remove Android restrictions in Google Cloud Console.";
      }
      return "I'm having trouble connecting to the AI. Please try again later.";
    }
  }
}
