import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _threads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchThreads();
  }

  Future<void> _fetchThreads() async {
    final token = await ApiService.getToken();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/chat/threads'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          _threads = json.decode(response.body);
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))));
    if (_threads.isEmpty) return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: Text("You have no active chats.", style: TextStyle(color: Colors.white54))));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _threads.length,
        itemBuilder: (context, index) {
          final thread = _threads[index];
          return Card(
            color: const Color(0xFF1E293B).withOpacity(0.9),
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(backgroundColor: Color(0xFF3B82F6), child: Icon(Icons.person, color: Colors.white)),
              title: Text(thread['partner_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Re: ${thread['part_name']}', style: const TextStyle(color: Colors.white70)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                  threadId: thread['id'], 
                  title: '${thread['partner_name']} - ${thread['part_name']}'
                ))).then((_) => _fetchThreads());
              },
            ),
          );
        },
      ),
    );
  }
}
