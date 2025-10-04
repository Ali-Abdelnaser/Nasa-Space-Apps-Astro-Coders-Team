import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps/data/Server/weather_api.dart';
import 'package:maps/data/models/weather_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/logic/user_cubit.dart';

class ResultPage extends StatefulWidget {
  final double lat;
  final double lon;
  final DateTime date;

  const ResultPage({
    super.key,
    required this.lat,
    required this.lon,
    required this.date,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final WeatherApiService _weatherApi = WeatherApiService();
  WeatherModel? _weather;
  bool _loading = true;
  bool _loadingSuggestions = false;
  String? _error;
  String? _suggestions;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  // 🌟 النظام الذكي للاقتراحات
  Future<void> _getSmartSuggestions() async {
    if (_weather == null) return;

    setState(() {
      _loadingSuggestions = true;
      _suggestions = null;
    });

    try {
      // المحاولة الأولى: Gemini AI
      final aiSuggestions = await _getAISuggestions();
      setState(() {
        _suggestions = aiSuggestions;
        _loadingSuggestions = false;
      });
    } catch (e) {
      // المحاولة الثانية: النظام المحلي الذكي
      print('🔄 استخدام النظام المحلي الذكي: $e');
      final localSuggestions = _getIntelligentLocalSuggestions();
      setState(() {
        _suggestions = localSuggestions;
        _loadingSuggestions = false;
      });
    }
  }

  // 🤖 الذكاء الاصطناعي المتقدم
  Future<String> _getAISuggestions() async {
    final weatherDesc = _weather!.description;
    final temp = _weather!.temperature;
    final condition = _weather!.mainCondition;
    final humidity = _weather!.humidity;
    final windSpeed = _weather!.windSpeed;

    // جلب الهوايات من المستخدم
    final userCubit = context.read<UserCubit>();
    final hobbies = await userCubit.getHobbies();

    final prompt =
        """
أنت مساعد ذكي متخصص في تقديم توصيات أنشطة ذكية بناءً على الظروف الجوية والاهتمامات الشخصية.

البيانات:
- الاهتمامات: ${hobbies.join(', ')}
- الطقس: $weatherDesc
- درجة الحرارة: ${temp.toStringAsFixed(1)}°C
- الرطوبة: $humidity%
- سرعة الرياح: ${windSpeed}m/s
- الحالة: $condition

المهمة:
قدم 3 توصيات أنشطة ذكية تراعي:
• التوافق مع الظروف الجوية الحالية
• الارتباط باهتمامات المستخدم
• الجدوى العملية والسلامة
• القيمة الترفيهية والرياضية

المتطلبات:
• اللغة: العربية الفصحى
• التنسيق: كل توصية في سطر مستقل
• الطابع: إيجابي، مشجع، عملي
• التخصص: مراعاة التفاصيل الجوية

الهدف:
توصيات ذكية تحقق الاستفادة المثلى من الظروف الجوية مع الاستمتاع بالهوايات.
""";

    return await _callGeminiAPI(prompt);
  }

  // 🔗 اتصال Gemini API محسن
  Future<String> _callGeminiAPI(String prompt) async {
    const apiKey = "AIzaSyBukxQCVOv8QMh3m7CJNVRP26-38Oc3g1U";
    const url =
        "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$apiKey";

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.8,
          'topK': 40,
          'topP': 0.9,
          'maxOutputTokens': 600,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  // 🧠 النظام المحلي الذكي المتقدم
  String _getIntelligentLocalSuggestions() {
    final condition = _weather!.mainCondition.toLowerCase();
    final temp = _weather!.temperature;
    final humidity = _weather!.humidity;
    final windSpeed = _weather!.windSpeed;

    // تحليل متقدم للظروف
    final weatherProfile = _analyzeWeatherProfile(
      condition,
      temp,
      humidity,
      windSpeed,
    );

    // توليد اقتراحات ذكية
    return _generateSmartRecommendations(weatherProfile);
  }

  // 📊 تحليل متقدم للطقس
  Map<String, dynamic> _analyzeWeatherProfile(
    String condition,
    double temp,
    int humidity,
    double windSpeed,
  ) {
    return {
      'comfortLevel': _calculateComfortLevel(temp, humidity),
      'activityType': _determineActivityType(condition, temp),
      'safetyScore': _calculateSafetyScore(windSpeed, condition),
      'timeRecommendation': _suggestBestTime(temp, condition),
      'intensity': _recommendIntensity(temp, humidity),
    };
  }

  String _generateSmartRecommendations(Map<String, dynamic> profile) {
    final comfort = profile['comfortLevel'];
    final activityType = profile['activityType'];
    final safety = profile['safetyScore'];
    final bestTime = profile['timeRecommendation'];
    final intensity = profile['intensity'];

    List<String> recommendations = [];

    // اقتراحات ذكية بناءً على التحليل
    if (comfort == 'مثالي') {
      recommendations.addAll([
        'الظروف الجوية مثالية لممارسة الأنشطة الخارجية بكامل طاقتك',
        'يمكنك الاستفادة من هذا الطقس الجميل لاكتشاف مسارات جديدة',
        'ممارسة الرياضة في الهواء الطلق ستكون ممتعة ومفيدة في هذه الأجواء',
      ]);
    } else if (comfort == 'جيد') {
      recommendations.addAll([
        'الطقس مناسب للأنشطة الخارجية مع بعض التحضيرات البسيطة',
        'يمكنك تعديل شدة النشاط لتناسب الظروف الحالية',
        'اختر الأوقات المناسبة من اليوم لممارسة هواياتك',
      ]);
    } else {
      recommendations.addAll([
        'الأنشطة الداخلية ستكون أكثر راحة في هذه الظروف',
        'يمكنك التخطيط للأنشطة الخارجية في أوقات أكثر ملاءمة',
        'استغل هذا الوقت في تطوير مهاراتك أو التخطيط لرحلات مستقبلية',
      ]);
    }

    // إضافة توصيات توقيت
    recommendations.add('الوقت المثالي: $bestTime');

    return recommendations.join('\n');
  }

  // 🎯 دوال التحليل الذكية
  String _calculateComfortLevel(double temp, int humidity) {
    if (temp >= 18 && temp <= 26 && humidity >= 30 && humidity <= 70) {
      return 'مثالي';
    } else if ((temp >= 15 && temp <= 30) &&
        (humidity >= 20 && humidity <= 80)) {
      return 'جيد';
    } else {
      return 'يتطلب تحضيرات';
    }
  }

  String _determineActivityType(String condition, double temp) {
    if (condition.contains('clear')) {
      return temp > 25 ? 'مائي' : 'هواء طلق';
    } else if (condition.contains('cloud')) {
      return 'معتدل';
    } else if (condition.contains('rain')) {
      return 'داخلي';
    } else {
      return 'متكيف';
    }
  }

  String _calculateSafetyScore(double windSpeed, String condition) {
    if (windSpeed < 5 && !condition.contains('storm')) {
      return 'آمن';
    } else if (windSpeed < 10 && !condition.contains('thunder')) {
      return 'معتدل';
    } else {
      return 'يحتاج حذر';
    }
  }

  String _suggestBestTime(double temp, String condition) {
    if (temp > 28) return 'الصباح الباكر أو المساء';
    if (condition.contains('rain')) return 'بعد انتهاء المطر';
    return 'أي وقت خلال اليوم';
  }

  String _recommendIntensity(double temp, int humidity) {
    final heatIndex = temp + (humidity / 100);
    if (heatIndex < 25) return 'عالية';
    if (heatIndex < 30) return 'متوسطة';
    return 'منخفضة';
  }

  // 🎨 واجهة المستخدم المحسنة
  Widget _buildSuggestionsSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _loadingSuggestions
          ? _buildLoadingSuggestions()
          : _suggestions == null
          ? _buildSuggestionsPlaceholder()
          : _buildSmartSuggestionsDisplay(),
    );
  }

  Widget _buildLoadingSuggestions() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.3),
                ),
                strokeWidth: 2,
              ),
              CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "جاري تحليل الطقس وهواياتك...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "نظام الذكاء الاصطناعي يقدم أفضل التوصيات",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(height: 16),
          Text(
            "توصيات ذكية لأنشطتك",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "احصل على توصيات مخصصة بناءً على طقس اليوم وهواياتك",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _getSmartSuggestions,
            icon: const Icon(Icons.psychology, size: 20),
            label: const Text(
              "تفعيل النظام الذكي",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartSuggestionsDisplay() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "توصيات ذكية مخصصة",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _getSmartSuggestions,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: "تحديث التوصيات",
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._suggestions!
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          suggestion.trim(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withOpacity(0.2), height: 20),
          Row(
            children: [
              Icon(
                Icons.verified,
                color: Colors.green.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "مقترح ذكياً بناءً على تحليل الطقس والهوايات",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // باقي الدوال الأساسية
  Future<void> _fetchWeather() async {
    try {
      final weather = await _weatherApi.fetchWeather(
        widget.lat,
        widget.lon,
        widget.date,
      );

      setState(() {
        _weather = weather;
        _loading = false;
        _error = null;
      });

      _getSmartSuggestions();
    } catch (e) {
      setState(() {
        _error = 'فشل في جلب بيانات الطقس: $e';
        _loading = false;
        _weather = null;
      });
    }
  }

  IconData _getWeatherIcon(String main) {
    switch (main.toLowerCase()) {
      case "clear":
        return Icons.wb_sunny;
      case "clouds":
        return Icons.cloud;
      case "rain":
        return Icons.beach_access;
      case "snow":
        return Icons.ac_unit;
      case "thunderstorm":
        return Icons.flash_on;
      case "drizzle":
        return Icons.grain;
      case "mist":
      case "fog":
      case "haze":
        return Icons.blur_on;
      default:
        return Icons.wb_cloudy;
    }
  }

  Color _getBackgroundColor() {
    if (_weather == null) return const Color(0xFF667eea);
    switch (_weather!.mainCondition.toLowerCase()) {
      case "clear":
        return const Color(0xFFff7e5f);
      case "clouds":
        return const Color(0xFF7b4397);
      case "rain":
        return const Color(0xFF2193b0);
      case "snow":
        return const Color(0xFF8e9eab);
      case "thunderstorm":
        return const Color(0xFF654ea3);
      default:
        return const Color(0xFF667eea);
    }
  }

  Color _getSecondaryColor() {
    if (_weather == null) return const Color(0xFF764ba2);
    switch (_weather!.mainCondition.toLowerCase()) {
      case "clear":
        return const Color(0xFFfeb47b);
      case "clouds":
        return const Color(0xFFdc2430);
      case "rain":
        return const Color(0xFF6dd5ed);
      case "snow":
        return const Color(0xFFeef2f3);
      case "thunderstorm":
        return const Color(0xFFeaafc8);
      default:
        return const Color(0xFF764ba2);
    }
  }

  Widget _buildLoading() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.8),
              ),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              "جاري تحميل بيانات الطقس...",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "عذراً!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error ?? "حدث خطأ غير متوقع",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _fetchWeather,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(
                  "إعادة المحاولة",
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final formattedDate = DateFormat('dd/MM/yyyy').format(widget.date);
    final backgroundColor = _getBackgroundColor();
    final secondaryColor = _getSecondaryColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 30),
            child: Column(
              children: [
                Text(
                  "طقس اليوم",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getWeatherIcon(_weather!.mainCondition),
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${_weather!.temperature.toStringAsFixed(1)}°",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "يشعر بـ ${_weather!.feelsLike.toStringAsFixed(1)}°",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _weather!.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                Icons.water_drop,
                                "الرطوبة",
                                "${_weather!.humidity}%",
                              ),
                              _buildStatItem(
                                Icons.compress,
                                "الضغط",
                                "${_weather!.pressure} hPa",
                              ),
                              _buildStatItem(
                                Icons.air,
                                "الرياح",
                                "${_weather!.windSpeed} m/s",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${widget.lat.toStringAsFixed(4)}, ${widget.lon.toStringAsFixed(4)}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSuggestionsSection(),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "آخر تحديث: ${DateFormat('HH:mm').format(DateTime.now())}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "الطقس والأنشطة",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
          ? _buildError()
          : _weather != null
          ? _buildWeatherCard()
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  "لا توجد بيانات",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                  ),
                ),
              ),
            ),
    );
  }
}
