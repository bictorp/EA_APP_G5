import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';
import '../constants/api_constants.dart';

class UploadService {
  final Dio _dio = AuthService.dio;

  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      String fileName = imageFile.name;
      if (fileName.isEmpty) {
        fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      FormData formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/upload',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
