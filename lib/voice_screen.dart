import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'hotel_all.dart'; // hotel_all.dart 파일 추가
import 'hotel_ai.dart'; // hotel_ai.dart 파일 추가
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'like_screen.dart'; // like_screen.dart 파일 추가

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  VoiceScreenState createState() => VoiceScreenState();
}

class VoiceScreenState extends State<VoiceScreen> {
  late stt.SpeechToText _speech;
  String _text = '대전에서 특별한 여행지를 탐색해보세요!';
  bool _isListening = false;
  int _selectedIndex = 2; // Voice 페이지의 기본 선택 인덱스

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _searchController.text = _text; // 초기값 설정
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });
      _speech.listen(onResult: (result) {
        setState(() {
          _text = result.recognizedWords;  // 음성 인식 결과를 _text에 저장
          _searchController.text = _text;  // 검색창에 텍스트 반영
          _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _text.length));  // 커서 위치를 텍스트 끝으로 설정
        });
      });
    }
  }

  void _stopListening() async {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Hotel 아이콘을 눌렀을 때 hotel_all.dart로 이동
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HotelAllPage()),
      );
    }

    // Favorites 아이콘을 눌렀을 때 like_screen.dart로 이동
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LikeScreen()),  // like_screen.dart로 이동
      );
    }
  }

  Future<void> _sendVoiceTextToBackend(String voiceText) async {
    final response = await http.post(
      Uri.parse('http://107.23.187.64:8000/api/ai-response/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'voice_text': voiceText,  // 요청에 voice_text만 포함
      }),
    );

    if (response.statusCode == 200) {
      // 응답을 디코드하여 데이터 처리
      var responseData = json.decode(response.body);
      // 응답에서 recommended_hotels 필드를 추출하여 hotelData에 저장
      List<dynamic> hotelData = responseData['recommended_hotels'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelAiPage(
            hotelData: hotelData,
            voiceText: voiceText,
          ),
        ),
      );
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          child: Stack(
            children: [
              Positioned(
                left: 140,
                top: 140,
                child: Row(
                  children: [
                    SizedBox(
                      width: 40.05,
                      height: 40,
                      child: FlutterLogo(),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'AITRAVEL',
                      style: TextStyle(
                        color: Color(0xFF163C9F),
                        fontSize: 16.42,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 44,
                top: 280,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      '안녕하세요!',
                      style: TextStyle(
                        color: Color(0xFF2E3E5C),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: 327,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F6FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextField(
                              controller: _searchController, // 검색창과 연결
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '검색어를 입력하세요',
                                hintStyle: TextStyle(
                                  color: Color(0xFF8089B0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.26,
                                ),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF8089B0),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.26,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                              color: Colors.blue,
                            ),
                            iconSize: 30,
                            onPressed: () {
                              if (_isListening) {
                                _stopListening();
                              } else {
                                _startListening();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 327,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF153C9F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF153C9F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          _sendVoiceTextToBackend(_searchController.text);
                        }, // 검색 버튼 동작
                        child: const Text(
                          '검색',
                          style: TextStyle(
                            color: Color(0xFFF2F2F2),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        selectedItemColor: Color(0xFF153C9F),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
