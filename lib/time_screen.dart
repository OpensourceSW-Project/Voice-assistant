import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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

  @override
  void initState() {
    super.initState();
    _getUserLocation();  // 사용자 위치를 가져오는 함수 호출
  }

  // 사용자의 위치를 가져오는 함수
  Future<void> _getUserLocation() async {
    // 위치 서비스가 활성화되어 있는지 확인
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showSnackBar('위치 서비스가 비활성화되어 있습니다.');
      return;
    }

    // 위치 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 권한이 거부된 경우 권한 요청
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showSnackBar('위치 권한이 거부되었습니다.');
        return;
      }
    }

    // 위치 권한이 승인되었으면 위치 정보 가져오기
    if (permission == LocationPermission.deniedForever) {
      showSnackBar('위치 권한이 영구히 거부되었습니다. 설정에서 권한을 수정해주세요.');
      return;
    }

    try {
      // 위치 정보 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLocation = [position.latitude, position.longitude];  // 위치 정보 저장
      });

      fetchRouteData();  // 위치를 가져온 후, 경로 정보 요청
    } catch (e) {
      showSnackBar('위치 정보를 가져오는 데 실패했습니다: $e');
    }
  }

  Future<void> fetchRouteData() async {
    if (userLocation == null) return;  // 사용자의 위치가 없으면 요청하지 않음

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('호텔 지도: ${widget.hotelName}'),
        backgroundColor: const Color(0xFFA8C6F1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용자의 위치와 호텔 이름 출력
            userLocation == null
                ? const Center(child: CircularProgressIndicator())
                : Text(
              '사용자 위치: 위도 ${userLocation![0]}, 경도 ${userLocation![1]}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '호텔 이름: ${widget.hotelName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30, color: Colors.grey),

            // 데이터 로딩 중 상태 출력
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _routeInfo == null
                ? const Text('데이터를 불러올 수 없습니다.')
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '숙소 이름: ${_routeInfo!['name']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text('주소: ${_routeInfo!['address']}'),
                const SizedBox(height: 10),
                Text('위도: ${_routeInfo!['latitude']}'),
                Text('경도: ${_routeInfo!['longitude']}'),
                const SizedBox(height: 10),
                Text('대중교통 소요 시간: ${_routeInfo!['transit_time']}'),
                Text('차량 소요 시간: ${_routeInfo!['car_time']}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
