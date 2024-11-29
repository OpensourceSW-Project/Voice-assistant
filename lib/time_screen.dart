import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'hotel_all.dart';  // hotel_all.dart 임포트
import 'voice_screen.dart';  // voice_screen.dart 임포트
import 'like_screen.dart';  // like_screen.dart 임포트

class TimeScreen extends StatefulWidget {
  final String hotelName;

  const TimeScreen({super.key, required this.hotelName});

  @override
  _TimeScreenState createState() => _TimeScreenState();
}

class _TimeScreenState extends State<TimeScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _routeInfo;
  List<double>? userLocation;  // 사용자 위치를 담을 변수
  int _selectedIndex = 0;  // BottomNavigationBar의 초기 선택 인덱스를 0으로 설정 (Map 아이콘)

  @override
  void initState() {
    super.initState();
    _getUserLocation();  // 사용자 위치를 가져오는 함수 호출
  }

  // 사용자의 위치를 가져오는 함수
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showSnackBar('위치 서비스가 비활성화되어 있습니다.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showSnackBar('위치 권한이 거부되었습니다.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showSnackBar('위치 권한이 영구히 거부되었습니다. 설정에서 권한을 수정해주세요.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLocation = [position.latitude, position.longitude];
      });

      fetchRouteData();
    } catch (e) {
      showSnackBar('위치 정보를 가져오는 데 실패했습니다: $e');
    }
  }

  Future<void> fetchRouteData() async {
    if (userLocation == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://107.23.187.64:8000/api/route-response/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_location": userLocation,
          "hotel_name": widget.hotelName,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _routeInfo = jsonDecode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
      } else {
        showSnackBar('요청 실패: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      showSnackBar('네트워크 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // 네비게이션 로직
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HotelAllPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VoiceScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LikeScreen()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AITRAVEL'),
        backgroundColor: const Color(0xFFA8C6F1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userLocation == null
                ? const Center(child: CircularProgressIndicator())
                : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _routeInfo == null
                ? const Text('데이터를 불러올 수 없습니다.')
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 호텔 이름 가운데 정렬
                Center(
                  child: Text(
                    widget.hotelName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF163C9F),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 주소 앞에 지도 아이콘 추가
                Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF828282)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '주소: ${_routeInfo!['address']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF828282),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 대중교통 소요시간 옆에 버스 아이콘 추가
                Row(
                  children: [
                    Icon(Icons.directions_bus, color: Color(0xFF828282)),
                    const SizedBox(width: 8),
                    Text(
                      '대중교통 소요시간: ${_routeInfo!['transit_time']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF828282),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 차량 소요시간 옆에 차 아이콘 추가
                Row(
                  children: [
                    Icon(Icons.directions_car, color: Color(0xFF828282)),
                    const SizedBox(width: 8),
                    Text(
                      '차량 소요시간: ${_routeInfo!['car_time']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF828282),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Hotel',
          ),
          BottomNavigationBarItem(
            icon: FlutterLogo(size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF163C9F),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
