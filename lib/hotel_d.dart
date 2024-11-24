import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HotelDetailsPage extends StatefulWidget {
  final Map<String, dynamic> hotelData; // 호텔 데이터 (이름, 위치 등)

  HotelDetailsPage({required this.hotelData});

  @override
  _HotelDetailsScreenState createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsPage> {
  List<dynamic> reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReviews(); // 리뷰 데이터를 가져옴
  }

  Future<void> fetchReviews() async {
    final url = Uri.parse('http://107.23.187.64:8000/api/review-info/'); // API URL
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['reviews'] is List) {
          setState(() {
            reviews = data['reviews']; // 리뷰가 리스트인 경우
            isLoading = false;
          });
        } else {
          throw Exception('Reviews data is not a list');
        }
      } else {
        throw Exception('Failed to load reviews');
      }

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hotelData['name'] ?? '호텔 상세정보'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 표시
          : Column(
        children: [
          // 호텔 정보 표시
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hotelData['name'] ?? '호텔 이름 없음',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text('위치: ${widget.hotelData['location'] ?? '정보 없음'}'),
                Text('가격: ${widget.hotelData['price'] ?? '정보 없음'}원'),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.phone),
                      onPressed: () {
                        // 전화 기능 추가
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.map),
                      onPressed: () {
                        // 지도 기능 추가
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            // 리뷰 목록 표시
            child: ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(
                      review['content'] ?? '리뷰 내용 없음',
                      style: TextStyle(fontSize: 14.0),
                    ),
                    subtitle: Text(
                      '평점: ${review['rating']}점',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
