import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleQuizApp());
}

class SimpleQuizApp extends StatelessWidget {
  const SimpleQuizApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const QuizHomePage(),
    );
  }
}

class QuizHomePage extends StatelessWidget {
  const QuizHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Quiz App'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Welcome to Flutter Quiz!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Test your Flutter knowledge',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Quiz feature is ready!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
