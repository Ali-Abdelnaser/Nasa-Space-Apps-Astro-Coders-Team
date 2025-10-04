import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:maps/Presentation/ResultPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions = [];

  // ⚠️ تأكد من تفعيل Places API و Geocoding API لهذا المفتاح
  static const String _googleApiKey = "AIzaSyB2kKMK_FEwXD_aBmI1Rn5SftiT6vpFuBM";
  bool _loadingLocation = true;
  bool _isSearching = false;
  Position? _currentPosition;
  double? _locationAccuracy;

  // موقع زويل الافتراضي
  final LatLng _zewailCityPosition = const LatLng(
    30.0286,
    31.4996, // إحداثيات مدينة زويل التقريبية
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
    });

    try {
      // تحقق إذا كانت خدمة الموقع مفعلة
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showDialog("تفعيل الموقع", "الرجاء تفعيل خدمة الموقع على جهازك");
        setState(() {
          _loadingLocation = false;
          _selectedPosition = _zewailCityPosition;
        });
        return;
      }

      // تحقق من الصلاحيات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showDialog(
          "الإذن مرفوض",
          "الرجاء منح إذن الموقع الدائم من إعدادات التطبيق",
        );
        setState(() {
          _loadingLocation = false;
          _selectedPosition = _zewailCityPosition;
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        _showDialog("الإذن مرفوض", "الرجاء منح إذن الموقع للتطبيق");
        setState(() {
          _loadingLocation = false;
          _selectedPosition = _zewailCityPosition;
        });
        return;
      }

      // جلب الموقع الحالي
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation, // أعلى دقة
        timeLimit: const Duration(seconds: 20),
      );

      print("✅ الموقع الحالي: ${position.latitude}, ${position.longitude}");
      print("📍 دقة الموقع: ${position.accuracy} متر");

      setState(() {
        _currentPosition = position;
        _selectedPosition = LatLng(position.latitude, position.longitude);
        _locationAccuracy = position.accuracy;
        _loadingLocation = false;
      });

      // تحريك الكاميرا للموقع الحالي
      _moveToLocation(_selectedPosition!);
    } catch (e) {
      print("❌ خطأ في جلب الموقع: $e");

      // محاولة استخدام آخر موقع معروف
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          print(
            "🔄 استخدام آخر موقع معروف: ${lastPosition.latitude}, ${lastPosition.longitude}",
          );
          setState(() {
            _currentPosition = lastPosition;
            _selectedPosition = LatLng(
              lastPosition.latitude,
              lastPosition.longitude,
            );
            _locationAccuracy = lastPosition.accuracy;
            _loadingLocation = false;
          });
          _moveToLocation(_selectedPosition!);
          return;
        }
      } catch (e) {
        print("❌ خطأ في استخدام آخر موقع: $e");
      }

      _showDialog(
        "خطأ",
        "فشل في الحصول على الموقع الحالي. تم استخدام موقع مدينة زويل بدلاً من ذلك.",
      );
      setState(() {
        _loadingLocation = false;
        _selectedPosition = _zewailCityPosition;
      });
    }
  }

  void _moveToLocation(LatLng position) {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(position, 16));
    }
  }

  Future<void> _getSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    // إضافة debounce لتجنب طلبات كثيرة
    await Future.delayed(const Duration(milliseconds: 300));

    // URL محسن للبحث مع تحديد مصر
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?"
        "input=${Uri.encodeComponent(input)}"
        "&language=ar"
        "&region=eg"
        "&components=country:eg"
        "&key=$_googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data["status"] == "OK") {
        setState(() {
          _suggestions = data["predictions"];
        });
      } else {
        print("❌ خطأ في البحث: ${data["status"]}");
        setState(() => _suggestions = []);

        if (data["status"] == "REQUEST_DENIED") {
          _showDialog(
            "خطأ في API",
            "Places API غير مفعل لهذا المفتاح. الرجاء تفعيله من Google Cloud Console.",
          );
        }
      }
    } catch (e) {
      print("❌ خطأ في الاتصال: $e");
      setState(() => _suggestions = []);
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    setState(() {
      _isSearching = true;
    });

    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?"
        "place_id=$placeId"
        "&fields=name,formatted_address,geometry"
        "&key=$_googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data["status"] == "OK") {
        final location = data["result"]["geometry"]["location"];
        final lat = location["lat"];
        final lng = location["lng"];
        final name =
            data["result"]["name"] ?? data["result"]["formatted_address"];

        print("📍 المكان المحدد: $name - $lat, $lng");

        setState(() {
          _selectedPosition = LatLng(lat, lng);
          _suggestions = [];
          _searchController.clear();
          _isSearching = false;
          _currentPosition = null; // لأنه موقع مختار وليس الموقع الحالي
        });

        _moveToLocation(_selectedPosition!);
      } else {
        print("❌ خطأ في تفاصيل المكان: ${data["status"]}");
        _showDialog("خطأ", "لم يتم العثور على المكان: ${data["status"]}");
        setState(() => _isSearching = false);
      }
    } catch (e) {
      print("❌ خطأ في الاتصال: $e");
      _showDialog("خطأ", "تعذر الاتصال: $e");
      setState(() => _isSearching = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("موافق"),
          ),
        ],
      ),
    );
  }

  // دالة لتنظيف الـ suggestions عند الضغط خارجها
  void _clearSuggestions() {
    if (_suggestions.isNotEmpty) {
      setState(() {
        _suggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _clearSuggestions,
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // تعطيل الزر الافتراضي
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                if (_selectedPosition != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _moveToLocation(_selectedPosition!);
                  });
                }
              },
              initialCameraPosition: CameraPosition(
                target: _selectedPosition ?? _zewailCityPosition,
                zoom: 16,
              ),
              onTap: (position) {
                _clearSuggestions();
                setState(() {
                  _selectedPosition = position;
                  _currentPosition = null; // لأنه موقع مختار يدوياً
                });
              },
              markers: _selectedPosition != null
                  ? {
                      Marker(
                        markerId: const MarkerId("selected"),
                        position: _selectedPosition!,
                        infoWindow: InfoWindow(
                          title: _currentPosition != null
                              ? "موقعك الحالي"
                              : "الموقع المحدد",
                          snippet:
                              "${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}",
                        ),
                      ),
                    }
                  : {},
            ),

            // Loading indicator
            if (_loadingLocation)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        "جاري تحديد موقعك...",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // زر العودة للموقع الحالي
            if (!_loadingLocation)
              Positioned(
                bottom: 150,
                right: 16,
                child: FloatingActionButton(
                  onPressed: _getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
              ),

            // Search bar
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _getSuggestions,
                            decoration: InputDecoration(
                              hintText: "ابحث عن مكان في مصر...",
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _suggestions = [];
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (ctx, i) {
                          final suggestion = _suggestions[i];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                            ),
                            title: Text(
                              suggestion["description"],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () =>
                                _getPlaceDetails(suggestion["place_id"]),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        bottomSheet: _selectedPosition != null
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // معلومات الموقع
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _currentPosition != null
                                ? Icons.my_location
                                : Icons.location_pin,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentPosition != null
                                      ? "موقعك الحالي"
                                      : "الموقع المحدد",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (_locationAccuracy != null &&
                                    _currentPosition != null)
                                  Text(
                                    "دقة: ${_locationAccuracy!.toStringAsFixed(1)} متر",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date picker button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _selectedDate != null
                              ? "${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}"
                              : "اختر التاريخ",
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Result button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_selectedPosition != null &&
                              _selectedDate != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultPage(
                                  lat: _selectedPosition!.latitude,
                                  lon: _selectedPosition!.longitude,
                                  date: _selectedDate!,
                                ),
                              ),
                            );
                          } else {
                            _showDialog(
                              "تنبيه",
                              "من فضلك اختر التاريخ والمكان",
                            );
                          }
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text(
                          "عرض النتيجة",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  } 
}
