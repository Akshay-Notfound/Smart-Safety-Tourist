import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  static Future<String?> uploadImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return null;

      File file = File(image.path);
      String fileName = 'uploads/${DateTime.now().millisecondsSinceEpoch}.jpg';

      UploadTask uploadTask = FirebaseStorage.instance.ref(fileName).putFile(file);

      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  static Future<String?> uploadDocument(File file, String fileName) async {
    try {
      UploadTask uploadTask = FirebaseStorage.instance
          .ref('documents/$fileName')
          .putFile(file);

      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading document: $e');
      return null;
    }
  }
}