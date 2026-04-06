import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:fake_news_detector/data/models/analysis_result.dart';

class ApiService {
  // Production backend on Render.com — accessible from anywhere
  static const String _baseUrl = 'https://fake-news-detection-zi59.onrender.com';

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
      },
    ));

    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: true,
      logPrint: (obj) => debugPrint('[API] $obj'),
    ));
  }

  /// Check backend health status
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get('/api/v1/health');
      return response.data;
    } catch (e) {
      throw ApiException('Failed to connect to server: $e');
    }
  }

  /// Upload image and get full analysis (cross-platform: works on web + mobile)
  Future<AnalysisResult> analyzeImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
        ),
      });

      final response = await _dio.post(
        '/api/v1/analyze',
        data: formData,
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(0);
          debugPrint('[API] Upload progress: $progress%');
        },
      );

      return AnalysisResult.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final detail = e.response?.data?['detail'] ?? 'Unknown error';
        throw ApiException('Analysis failed: $detail');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ApiException(
            'Connection timed out. Make sure the backend is running.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException(
            'Cannot connect to server. Make sure the backend is running on $_baseUrl');
      } else {
        throw ApiException('Network error: ${e.message}');
      }
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
