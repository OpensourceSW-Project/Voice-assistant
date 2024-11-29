import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'voice_screen.dart';
import 'hotel_all.dart';

class LikeScreen extends StatefulWidget {
  const LikeScreen({super.key});

  @override
  _LikeScreenState createState() => _LikeScreenState();
}

class _LikeScreenState extends State<LikeScreen> {
  bool _isLoading = false;
  List<Hotel> _likedHotels = [];

  @override
  void initState() {
    super.initState();
    fetchLikedHotels();
  }

  Future<void> fetchLikedHotels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://107.23.187.64:8000/api/like-accommodation?user_id=1'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          _likedHotels = data.map((json) => Hotel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load liked hotels: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching liked hotels: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> removeHotel(int index, String accommodationName) async {
    setState(() {
      // UI 업데이트: 삭제 버튼을 눌렀을 때, 해당 호텔을 UI에서 바로 제거
      _likedHotels.removeAt(index);
    });

    try {
      final response = await http.delete(
        Uri.parse('http://107.23.187.64:8000/api/like-accommodation/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': 1,
          'accommodation_name': accommodationName,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete hotel: ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing hotel: $e');
    }
  }




  void _onItemTapped(int index) {
    setState(() {
      if (index == 1) { // Hotel 아이콘 클릭 시
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HotelAllPage()), // hotel_all.dart로 이동
        );
      } else if (index == 2) { // Home 아이콘 클릭 시
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VoiceScreen()), // voice_screen.dart로 이동
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bookmarks',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFA8C6F1), // 상단 배경색 변경
        centerTitle: true, // 제목을 중앙에 배치
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _likedHotels.isEmpty
          ? const Center(child: Text('좋아요한 숙소가 없습니다.'))
          : ListView.builder(
        itemCount: _likedHotels.length,
        itemBuilder: (context, index) {
          final hotel = _likedHotels[index];
          return Card(
            color: const Color(0xFFA8D8E8),
            margin: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    hotel.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22, // 호텔 이름 크기 키움
                    ),
                  ),
                  subtitle: Text(
                    hotel.address,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF), // 주소 색상 변경
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Text(
                    '₩${hotel.price}', // ₩ 기호를 직접 사용
                    style: const TextStyle(
                      color: Color(0xFF153C9F), // 가격 색상 변경
                      fontSize: 18, // 가격 크기 키움
                      fontWeight: FontWeight.bold, // 가격 굵은 글씨
                    ),
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFEB3B)), // 별 아이콘 추가
                          const SizedBox(width: 5), // 아이콘과 텍스트 사이의 간격
                          Text(
                            '${hotel.ranks}',
                            style: const TextStyle(
                              color: Colors.black, // 평점 텍스트는 검은색으로
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Color(0xFFFFFFFF),
                            ), // 휴지통 아이콘
                            onPressed: () {
                              removeHotel(index, hotel.name);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.map, color: Color(0xFFFFFFFF)),
                            onPressed: () {
                              // 지도 기능 미구현
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
        currentIndex: 3,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class Hotel {
  final int id;
  final String name;
  final int price;
  final String ranks;
  final String address;

  Hotel({
    required this.id,
    required this.name,
    required this.price,
    required this.ranks,
    required this.address,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'],
      name: json['name'],
      price: json['price'] ?? 0,
      ranks: json['ranks'] ?? '0.0',
      address: json['address'] ?? '주소 정보 없음',
    );
  }
}
