import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Ideally, this should be in an Env file, but for this task we use it directly as provided.
  static const String _apiKey = 'AIzaSyDsbCrNQK3JQReyrNUTFEaKQmKceQ1YL54';

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
          'You are the Smart Travel Assistant for the Smart Safety Tourist App. '
          'Your goal is to help tourists with safety, travel plans, and explaining app features. '
          'Key Features you know about: '
          '1. Safety Status: ML-based safety rating (0-100) for locations. '
          '2. Fake Document Detection: Checks for fake IDs. '
          '3. Real-time Weather: Live updates. '
          '4. Emergency: Panic button and trusted contacts. '
          '5. Live Tracking: Share live location with family. '
          'Always be helpful, concise, and prioritize safety.'),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
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
      // Return the actual error for debugging purposes
      return "AI Connection Error: ${e.toString()}";
    }
  }
}
