import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'report_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _searched = false;

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _searched = true;
    });

    final query = _searchController.text.trim().toUpperCase();
    if (query.isEmpty) {
      setState((() => _isLoading = false));
      return;
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/search/$query'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _searchResults = json.decode(response.body);
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'ENTER PLATE...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF3B82F6)),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _search,
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Center(child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading) const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))),
        if (!_isLoading && _searched && _searchResults.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No approved reports found for this plate number.', style: TextStyle(color: Colors.white54, fontSize: 16)),
            ),
          ),
        if (!_isLoading && _searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final report = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailScreen(report: report),
                        ),
                      );
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.history, color: Color(0xFF10B981)),
                    ),
                    title: Text(
                      'Plate: ${report['plate_number']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Report: ${report['description']}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
