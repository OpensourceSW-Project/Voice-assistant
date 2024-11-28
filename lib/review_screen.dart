import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'voice_screen.dart';  // VoiceScreen import 추가

class ReviewScreen extends StatefulWidget {
  final String accommodationName;

  ReviewScreen({required this.accommodationName});

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<dynamic> reviews = [];
  int page = 1;
  final int pageSize = 10;
  bool isLoading = false;
  int _selectedIndex = 1;  // 처음에는 Hotel 아이콘이 선택되도록 수정

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  // 리뷰 조회 API 호출
  Future<void> fetchReviews() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse('http://107.23.187.64:8000/api/review-info/?accommodation_name=${widget.accommodationName}&page=$page&page_size=$pageSize'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        reviews = data['reviews'];
        isLoading = false;
      });
    } else {
      // 오류 처리
      setState(() {
        isLoading = false;
      });
      print('Failed to load reviews');
    }
  }

  // 리뷰 생성 API 호출
  Future<void> createReview(String content, double rank) async {
    final response = await http.post(
      Uri.parse('http://107.23.187.64:8000/api/review-info/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'accommodation_name': widget.accommodationName,
        'content': content,
        'rank': rank,
      }),
    );

    if (response.statusCode == 200) {
      // 리뷰 추가 성공 시
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['message'] == 'Review added successfully') {
        fetchReviews(); // 새로운 리뷰 리스트를 다시 가져옴
      }
    } else {
      // 오류 처리
      print('Failed to add review');
    }
  }

  // 리뷰 삭제 API 호출
  Future<void> deleteReview(int reviewId) async {
    final response = await http.delete(
      Uri.parse('http://107.23.187.64:8000/api/review-info/$reviewId/'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['message'] == 'Review deleted successfully') {
        setState(() {
          reviews.removeWhere((review) => review['id'] == reviewId);
        });
      }
    } else {
      print('Failed to delete review');
    }
  }

  // 리뷰 작성 UI
  Widget buildReviewForm() {
    final TextEditingController contentController = TextEditingController();
    double rating = 5;

    return Column(
      children: [
        TextField(
          controller: contentController,
          decoration: InputDecoration(hintText: '경험을 적어주세요.'),
        ),
        ElevatedButton(
          onPressed: () {
            createReview(contentController.text, rating);
          },
          child: Text('리뷰 쓰기'),
        ),
      ],
    );
  }

  // 리뷰 목록 UI
  Widget buildReviewList() {
    return ListView.builder(
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Padding(
          padding: const EdgeInsets.all(8.0), // 간격을 조금 두기 위해 패딩 추가
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // 내부 배경을 흰색으로 설정
              border: Border.all(color: const Color(0xFFA8C6F1), width: 2), // 실선 테두리 색상
              borderRadius: BorderRadius.circular(8), // 둥근 모서리 적용
            ),
            child: ListTile(
              title: Text(review['content']),
              subtitle: Text('평점: ${review['rating']}'),
            ),
          ),
        );
      },
    );
  }

  // BottomNavigationBar 탭 처리
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Home 버튼이 클릭된 경우 VoiceScreen으로 이동
    if (index == 2) {  // index 2는 Home 아이콘에 해당
      setState(() {
        _selectedIndex = 1;  // Hotel 아이콘을 선택 상태로 설정
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VoiceScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.accommodationName}'),
        backgroundColor: const Color(0xFFA8C6F1),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(child: buildReviewList()),  // 리뷰 목록은 상단에
          Padding(
            padding: const EdgeInsets.all(8.0),  // 간격을 주기 위해 패딩 추가
            child: buildReviewForm(),  // 리뷰 폼은 하단에 위치
          ),
        ],
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