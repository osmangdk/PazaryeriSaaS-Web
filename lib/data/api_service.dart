import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://pazaryerisaas-production.up.railway.app/api',
      connectTimeout: const Duration(seconds: 5),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password
      });
      final token = response.data['token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
      }
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDashboardMetrics() async {
    try {
      final response = await _dio.get('/tenant/dashboard');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> getProducts() async {
    try {
      final response = await _dio.get('/products');
      return response.data;
    } catch (e) {
      return null;
    }
  }
}

