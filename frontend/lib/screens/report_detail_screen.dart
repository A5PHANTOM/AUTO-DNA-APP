import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const ReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  _ReportDetailScreenState createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isLoadingAi = false;
  String? _aiEstimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAiSuggestions();
    });
  }

  Future<void> _getAiSuggestions() async {
    setState(() => _isLoadingAi = true);
    
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/ai/analyze-report/${widget.report['id']}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _aiEstimation = "Damage: ${data['percentage']}%\n${data['estimation']}";
      });
    } else {
      setState(() {
        _aiEstimation = "Error fetching AI suggestions.";
      });
    }

    setState(() => _isLoadingAi = false);
  }

  @override
  Widget build(BuildContext context) {
    final String imageBaseUrl = ApiService.baseUrl.replaceAll('/api', '');
    final String? imagePath = widget.report['image_path'];
    final String imageUrl = imagePath != null ? '$imageBaseUrl/$imagePath' : '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Report: ${widget.report['plate_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(16)),
                      child: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white54)),
                    ),
                  ),
                )
              else
                Container(
                  height: 250,
                  decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: Text('No Image Attached', style: TextStyle(color: Colors.white54, fontSize: 18))),
                ),
              const SizedBox(height: 24),
              const Text('Incident Description', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B).withOpacity(0.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                child: Text(widget.report['description'] ?? 'No description provided.', style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 32),
              if (_aiEstimation != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF10B981)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome, color: Colors.white),
                          SizedBox(width: 8),
                          Text('AI Analysis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_aiEstimation!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ] else ...[
                _isLoadingAi
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.analytics),
                      label: const Text('Get AI Suggestions'),
                      onPressed: _getAiSuggestions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
