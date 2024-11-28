// hotel_ai.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'voice_screen.dart'; // VoiceScreen 임포트
import 'review_screen.dart'; // ReviewScreen 임포트
import 'like_screen.dart'; // LikeScreen 임포트

class HotelAiPage extends StatefulWidget {
  final dynamic hotelData;
  const HotelAiPage({super.key, required this.hotelData});

  @override
  State<HotelAiPage> createState() => _HotelAiPageState();
}

class _HotelAiPageState extends State<HotelAiPage> {
  int _selectedIndex = 4; // Search 아이콘 기본 선택
  bool _isLoading = true;
  List<Hotel> _hotelList = [];
  List<int> _likedHotels = []; // 좋아요 호텔 ID 리스트

  void _onItemTapped(int index) {
    if (index == 2) {
      // Home 아이콘 클릭 시 VoiceScreen으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VoiceScreen()),
      );
    } else if (index == 3) {
      // Favorite 아이콘 클릭 시 LikeScreen으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LikeScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchHotelData();
  }

  Future<void> fetchHotelData() async {
    try {
      final response = await http.post(
        Uri.parse('http://107.23.187.64:8000/api/ai-response/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}), // 필요하면 요청 바디 추가
      );

      if (response.statusCode == 200) {
        List<dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes))['recommended_hotels'];

        setState(() {
          _hotelList = data.map((json) => Hotel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        print('Failed to load hotels, status code: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error occurred: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '추천 숙소',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'NanumGothic',
          ),
        ),
        backgroundColor: const Color(0xFFA8C6F1),
        centerTitle: false,  // 왼쪽 정렬
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        color: Colors.white,
        child: ListView.builder(
          itemCount: _hotelList.length,
          itemBuilder: (context, index) {
            final hotel = _hotelList[index];
            return HotelCard(
              hotel: hotel,
              onLike: () {
                setState(() {
                  if (_likedHotels.contains(hotel.id)) {
                    _likedHotels.remove(hotel.id); // 이미 좋아요 한 호텔은 제거
                  } else {
                    _likedHotels.add(hotel.id); // 좋아요 추가
                  }
                });
              },
              isLiked: _likedHotels.contains(hotel.id),
            );
          },
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
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HotelCard extends StatelessWidget {
  final Hotel hotel;
  final VoidCallback onLike;
  final bool isLiked;

  const HotelCard({
    super.key,
    required this.hotel,
    required this.onLike,
    required this.isLiked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 호텔을 클릭하면 해당 호텔의 리뷰 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewScreen(accommodationName: hotel.name), // Hotel 객체를 ReviewScreen에 전달
          ),
        );
      },
      child: Card(
        color: const Color(0xFFB0E0E6),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hotel.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NanumGothic',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                hotel.address,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'NanumGothic',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '가격: ${hotel.price == 0 ? '가격 정보 없음' : '${hotel.price}원'}',
                style: const TextStyle(
                  color: Color(0xFF163C9F),
                  fontFamily: 'NanumGothic',
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '평점: ${hotel.ranks}',
                    style: const TextStyle(fontFamily: 'NanumGothic'),
                  ),
                  Row(
                    children: [
                      // 좋아요 버튼
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: onLike,
                      ),
                      // 전화 버튼을 원형 버튼 안에 넣기
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF163C9F),
                        child: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.white),
                          onPressed: () {
                            showSnackBar(context, '전화 버튼 클릭됨');
                          },
                        ),
                      ),
                      const SizedBox(width: 10), // 버튼 간격
                      // 지도 버튼을 원형 버튼 안에 넣기
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF163C9F),
                        child: IconButton(
                          icon: const Icon(Icons.map, color: Colors.white),
                          onPressed: () {
                            showSnackBar(context, '지도 버튼 클릭됨');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class Hotel {
  final int id;
  final String name;
  final String address;
  final int price;
  final String ranks;

  Hotel({
    required this.id,
    required this.name,
    required this.address,
    required this.price,
    required this.ranks,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      price: json['price'],
      ranks: json['ranks'],
    );
  }
}
