import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherApiService {
  // استخدم الـ API المجاني بدل المميز
  static const String _baseUrl = "https://api.openweathermap.org/data/2.5/weather";
  static const String _apiKey = "fcbe3cd66973d26ea5d976b7217ad733";
  static const String _units = "metric"; // Celsius

  Future<WeatherModel> fetchWeather(
    double lat,
    double lon,
    DateTime date,
  ) async {
    try {
      print('🌤️ جلب بيانات الطقس من API...');
      print('📍 الموقع: $lat, $lon');
      print('📅 التاريخ المطلوب: $date');
      
      // الـ API المجاني مش بياخد تاريخ، بيجب بيانات اللحظة الحالية
      final url = Uri.parse(
        "$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=$_units&lang=ar",
      );

      print('🔗 URL: $url');

      final response = await http.get(url);

      print('📡 كود الاستجابة: ${response.statusCode}');
      print('📦 بيانات الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ تم تحويل JSON بنجاح');
        return WeatherModel.fromJson(data);
      } else {
        final errorMsg = "فشل في جلب البيانات: ${response.statusCode} - ${response.body}";
        print('❌ $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ خطأ في fetchWeather: $e');
      rethrow;
    }
  }
}