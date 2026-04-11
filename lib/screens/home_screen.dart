import 'package:flutter/material.dart';
import 'package:mangabaka_app/widgets/mb_search_bar.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MBSearchBar(
              onChanged: (text) {
                print('User typed: $text');
              },
            ),
          ],
        ),
      ),
    );
  }
}