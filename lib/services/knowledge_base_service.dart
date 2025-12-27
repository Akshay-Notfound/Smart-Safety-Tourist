class KnowledgeBaseService {
  final Map<String, String> _knowledge = {
    'safety':
        'Safety Status is an ML-based feature that rates locations on a scale of 0-100. It uses crime data and user reports to determine how safe an area is.',
    'rating':
        'The Safety Rating is a score from 0-100. Higher scores mean safer areas. A score above 80 is "Very Safe", while below 40 is "Unsafe".',
    'document':
        'We use Machine Learning to detect fake IDs and documents. Upload a photo of an Aadhaar card or ID, and our system verifies its authenticity.',
    'fake':
        'Our system can flag users who upload fake documents. This helps keep the community safe from fraud.',
    'weather':
        'Real-time weather updates help you plan your trips. We provide current temperature, conditions, and forecasts for your location.',
    'emergency':
        'In case of emergency, press the red Panic Button. It instantly alerts your trusted contacts and local authorities with your live location.',
    'panic':
        'The Panic Button is for emergencies only. Pressing it sends an SOS with your location to your saved emergency contacts.',
    'tracking':
        'Live Tracking allows you to share your real-time location with family and friends. You can enable or disable this in the dashboard.',
    'location':
        'We track your location to provide safety alerts and live tracking features. Your privacy is important to us.',
    'hello':
        'Hello! I am your Smart Travel Assistant. Ask me about Safety, Weather, Documents, or Emergency features.',
    'hi':
        'Hi there! I can help you understand this app. Try asking "How does safety work?" or "What is the panic button?"',
    'help':
        'I can explain the following features: Safety Status, Fake Document Detection, Weather Updates, Panic Button, and Live Tracking. What would you like to know?',
    'app':
        'The Smart Safety Tourist App is designed to keep tourists safe using advanced ML technology for safety ratings and document verification.',
    'about':
        'This is a project dedicated to tourist safety, integrating ML, real-time data, and emergency response features.'
  };

  Future<String> sendMessage(String message) async {
    // Simulate a small delay for a natural feel
    await Future.delayed(const Duration(milliseconds: 500));

    final lowerMsg = message.toLowerCase();

    for (var key in _knowledge.keys) {
      if (lowerMsg.contains(key)) {
        return _knowledge[key]!;
      }
    }

    return "I'm not sure about that. I can tell you about Safety, Weather, Documents, Emergency, and Tracking. Please ask me about those!";
  }
}
