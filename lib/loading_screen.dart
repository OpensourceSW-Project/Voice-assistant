import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 375,
        height: 812,
        padding: const EdgeInsets.only(
          top: 342.41,
          left: 95,
          right: 96,
          bottom: 397.59,
        ),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(),
                  child: Icon(Icons.travel_explore, color: Color(0xFF587FE4), size: 40),
                ),
                const SizedBox(width: 8),
                Text(
                  'AITRAVEL',
                  style: const TextStyle(
                    color: Color(0xFF163C9F),
                    fontSize: 26,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
