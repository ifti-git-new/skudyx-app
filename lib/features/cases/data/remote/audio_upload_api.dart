import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class AudioUploadApi {
  final Dio dio;

  AudioUploadApi({required this.dio});

  Future<Map<String, dynamic>> uploadAudio({
    required String caseId,
    required File audioFile,
  }) async {
    final formData = FormData.fromMap({
      'case_id': caseId,
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        filename: p.basename(audioFile.path),
      ),
    });

    final res = await dio.post(
      '/api/v1/cases/upload-audio',
      data: formData,
      options: Options(
        extra: const {'requiresAuth': true},
        contentType: 'multipart/form-data',
      ),
    );

    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'Audio upload failed';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg,
      );
    }

    return body;
  }
}