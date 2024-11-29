import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'voice_screen.dart'; // VoiceScreen 임포트
import 'review_screen.dart'; // ReviewScreen 임포트
import 'time_screen.dart';
import 'like_screen.dart';  // like_screen 임포트
import 'hotel_all.dart'; // hotel_all.dart 임포트 추가

class HotelAiPage extends StatefulWidget {
  final List<dynamic> hotelData; // API로 받아온 호텔 데이터
  final String voiceText; // 음성 텍스트를 전달받음

  const HotelAiPage({super.key, required this.hotelData, required this.voiceText});

  @override
  _HotelAiPageState createState() => _HotelAiPageState();
}

class _HotelAiPageState extends State<HotelAiPage> {
  int _currentIndex = 4; // 기본 선택 아이콘을 Search로 설정

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '추천 숙소',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            fontFamily: 'NanumGothic',
          ),
        ),
        backgroundColor: const Color(0xFFA8C6F1),
        centerTitle: false,  // 왼쪽 정렬
      ),
      body: widget.hotelData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
        color: Colors.white,
        child: ListView.builder(
          itemCount: widget.hotelData.length,
          itemBuilder: (context, index) {
            final hotel = Hotel.fromJson(widget.hotelData[index]);
            return HotelCard(
              hotel: hotel,
              onFavoriteChanged: () {}, // 기본적으로 빈 콜백 추가
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex, // 현재 선택된 아이템을 설정
        selectedItemColor: const Color(0xFF163C9F), // 활성화된 아이템 색상 설정
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
        onTap: (index) {
          setState(() {
            _currentIndex = index; // 클릭한 아이콘을 활성화

            if (index == 2) {
              // Home 아이콘 클릭 시 VoiceScreen으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VoiceScreen()),
              );
            } else if (index == 3) {
              // Favorites 아이콘 클릭 시 like_screen.dart로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LikeScreen()), // LikeScreen 추가
              );
            } else if (index == 1) {
              // Hotel 아이콘 클릭 시 hotel_all.dart로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HotelAllPage()), // HotelAllPage로 이동
              );
            }
          });
        },
      ),
    );
  }
}

class HotelCard extends StatefulWidget {
  final Hotel hotel;
  final VoidCallback onFavoriteChanged; // 좋아요 상태 변경 콜백

  const HotelCard({
    super.key,
    required this.hotel,
    required this.onFavoriteChanged,
  });

  @override
  _HotelCardState createState() => _HotelCardState();
}

class _HotelCardState extends State<HotelCard> {
  bool _isLiked = false;
  bool _buttonPressed = false;

  // 버튼 눌렀다 떼기
  Future<void> _onLikePressed() async {
    setState(() {
      _buttonPressed = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://107.23.187.64:8000/api/like-accommodation/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": 1,
          "accommodation_name": widget.hotel.name,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isLiked = true;
        });
        showSnackBar(context, '북마크에 추가되었습니다!');
      } else {
        showSnackBar(context, '추가 실패');
      }
    } catch (e) {
      showSnackBar(context, '네트워크 오류: $e');
    }

    // 버튼 눌렀다 떼는 효과 복구
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _buttonPressed = false;
        _isLiked = false; // 원상태로 복구
      });
    });
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 호텔을 클릭하면 해당 호텔의 리뷰 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReviewScreen(accommodationName: widget.hotel.name),
          ),
        );
      },
      child: Card(
        color: const Color(0xFFFFFFFF),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.hotel.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NanumGothic',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.hotel.address,
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontFamily: 'NanumGothic',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '가격: ${widget.hotel.price == 0 ? '가격 정보 없음' : widget.hotel.price.toString()}',
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
                    '평점: ${widget.hotel.ranks.toString()}',  // ranks를 String으로 변환
                    style: const TextStyle(fontFamily: 'NanumGothic'),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF163C9F),
                        child: IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: _buttonPressed
                                ? Colors.red
                                : Colors.white, // 눌렀다 떼는 효과
                          ),
                          onPressed: _onLikePressed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF163C9F),
                        child: IconButton(
                          icon: const Icon(Icons.map, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TimeScreen(hotelName: widget.hotel.name),
                              ),
                            );
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
}

class Hotel {
  final int id;
  final String name;
  final String address;
  final double price;  // 수정: double 타입으로 변경
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
      name: utf8.decode(json['name'].runes.toList()),  // UTF-8 디코딩
      address: utf8.decode(json['address'].runes.toList()),  // UTF-8 디코딩
      price: json['price'] is String ? double.tryParse(json['price']) ?? 0.0 : json['price'].toDouble(),
      ranks: json['ranks'].toString(),  // ranks를 String으로 변환
    );
  }
}

Future<List<dynamic>> fetchHotelData() async {
  try {
    final response = await http.get(Uri.parse('http://107.23.187.64:8000/api/hotels/'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load hotel data');
    }
  } catch (e) {
    throw Exception('Failed to load hotel data: $e');
  }
}
