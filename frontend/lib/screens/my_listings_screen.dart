import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class MyListingsScreen extends StatefulWidget {
  @override
  _MyListingsScreenState createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<dynamic> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyListings();
  }

  Future<void> _fetchMyListings() async {
    final token = await ApiService.getToken();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/marketplace/my-listings'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if(mounted){
      if (response.statusCode == 200) {
        setState(() {
          _vehicles = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteListing(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Listing', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to permanently delete this listing?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = await ApiService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/marketplace/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing deleted successfully.'), backgroundColor: Colors.green));
      _fetchMyListings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete listing.'), backgroundColor: Colors.redAccent));
    }
  }

  void _showHistoryDialog(BuildContext context, dynamic vehicle) {
    if (vehicle['accident_reports'] == null || vehicle['accident_reports'].isEmpty) return;
    final String imageBaseUrl = ApiService.baseUrl.replaceAll('/api', '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Accident History Report', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: vehicle['accident_reports'].length,
                itemBuilder: (context, index) {
                  final r = vehicle['accident_reports'][index];
                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (r['image_path'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network('$imageBaseUrl/${r['image_path']}'),
                              ),
                            ),
                          const Text('Incident Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(r['description'] ?? '', style: const TextStyle(color: Colors.white70)),
                          const Divider(height: 24, color: Colors.white24),
                          const Text('AI Damage Estimation', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                          Text(
                            (r['ai_damage_estimation'] ?? r['ai_estimation'] ?? '').toString().trim().isNotEmpty
                                ? (r['ai_damage_estimation'] ?? r['ai_estimation']).toString().trim()
                                : 'No AI data',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              )
            )
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imageBaseUrl = ApiService.baseUrl.replaceAll('/api', '');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _vehicles.isEmpty
              ? const Center(child: Text('You have no active listings.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    final String? imagePath = vehicle['image_path'];
                    final String imageUrl = imagePath != null ? '$imageBaseUrl/$imagePath' : '';
                    final bool hasAccidents = vehicle['accident_reports'] != null && vehicle['accident_reports'].isNotEmpty;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 24.0),
                      color: const Color(0xFF1E293B).withOpacity(0.9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Stack(
                              children: [
                                if (imagePath != null)
                                  Image.network(
                                    imageUrl,
                                    height: 200, width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 200, color: const Color(0xFF334155),
                                      child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48)),
                                    ),
                                  ),
                                Positioned(
                                  top: 8, right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                    style: IconButton.styleFrom(backgroundColor: Colors.redAccent),
                                    onPressed: () => _deleteListing(vehicle['id']),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${vehicle['year'] ?? ''} ${vehicle['vehicle_name']} ${vehicle['model'] ?? ''}'.trim(),
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                      Text('\$${vehicle['price']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(8)),
                                    child: Text('Plate: ${vehicle['plate_number']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(vehicle['description'] ?? '', style: const TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 16),
                                  InkWell(
                                    onTap: hasAccidents ? () => _showHistoryDialog(context, vehicle) : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: hasAccidents ? const Color(0xFFEF4444).withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: hasAccidents ? const Color(0xFFEF4444).withOpacity(0.5) : const Color(0xFF10B981).withOpacity(0.5))
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(hasAccidents ? Icons.warning : Icons.check_circle, color: hasAccidents ? const Color(0xFFEF4444) : const Color(0xFF10B981), size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              hasAccidents ? 'Accident History Found (Tap to Details)' : 'Clean Accident History',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
