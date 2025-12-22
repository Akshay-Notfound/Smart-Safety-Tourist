import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionCheckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> checkVersion() async {
    try {
      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // Fetch latest version info from Firestore
      // Assuming a collection 'app_config' and document 'updates'
      DocumentSnapshot snapshot =
          await _firestore.collection('app_config').doc('updates').get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        String latestVersion = data['latest_version'] ?? currentVersion;
        String apkUrl = data['apk_url'] ?? '';
        String changes = data['changes'] ?? '';

        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          return {
            'updateAvailable': true,
            'latestVersion': latestVersion,
            'apkUrl': apkUrl,
            'changes': changes,
          };
        }
      }
    } catch (e) {
      print("Error checking version: $e");
    }
    return null;
  }

  bool _isUpdateAvailable(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      int currentPart = (i < currentParts.length) ? currentParts[i] : 0;
      int latestPart = latestParts[i];

      if (latestPart > currentPart) {
        return true;
      } else if (latestPart < currentPart) {
        return false;
      }
    }
    return false;
  }
}
