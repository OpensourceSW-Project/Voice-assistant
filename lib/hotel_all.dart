import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'voice_screen.dart'; // VoiceScreen 임포트
import 'review_screen.dart'; // ReviewScreen 임포트
import 'like_screen.dart'; // LikeScreen 임포트
import 'time_screen.dart';

class HotelAllPage extends StatefulWidget {
  const HotelAllPage({super.key});

  @override
  State<HotelAllPage> createState() => _HotelAllPageState();
}

class _HotelAllPageState extends State<HotelAllPage> {
  int _selectedIndex = 1; // Hotel 아이콘 기본 선택
  bool _isLoading = true;
  List<Hotel> _hotelList = [];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Home 아이콘 클릭 시 VoiceScreen으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VoiceScreen()),
      );
    } else if (index == 3) {
      // Favorites 아이콘 클릭 시 LikeScreen으로 이동
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
      final response = await http.get(
        Uri.parse('http://107.23.187.64:8000/api/accommodation-info/'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes))['accommodations'];

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
          '목록',
          style: TextStyle(fontFamily: 'NanumGothic'),
        ),
        backgroundColor: const Color(0xFFA8C6F1),
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
              onFavoriteChanged: fetchHotelData, // 좋아요 변경 시 호출
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

    // 버튼 눌렀다 떼기 효과 복구
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
        color: const Color(0xFFA8C6F1),
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
                  color: Colors.white,
                  fontFamily: 'NanumGothic',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '가격: ${widget.hotel.price == 0 ? '가격 정보 없음' : '${widget.hotel.price}원'}',
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
                    '평점: ${widget.hotel.ranks}',
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
