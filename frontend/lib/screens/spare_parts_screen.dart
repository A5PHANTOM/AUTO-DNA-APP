import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

class SparePartsScreen extends StatefulWidget {
  @override
  _SparePartsScreenState createState() => _SparePartsScreenState();
}

class _SparePartsScreenState extends State<SparePartsScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final token = await ApiService.getToken();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/spare-parts/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          _requests = json.decode(response.body);
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startChat(int offerId, String partnerName, String partName) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final token = await ApiService.getToken();
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}/chat/threads'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'offer_id': offerId}),
    );
    
    if (mounted) Navigator.pop(context); // close dialog
    
    if (res.statusCode == 200 && mounted) {
      final threadId = json.decode(res.body)['id'];
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
        threadId: threadId,
        title: '$partnerName - $partName',
      )));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start chat')));
    }
  }

  void _showRequestDialog() {
    final _partNameController = TextEditingController();
    final _carModelController = TextEditingController();
    final _descriptionController = TextEditingController();
    bool _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Request Spare Part', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: _partNameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Part Name')),
                const SizedBox(height: 12),
                TextField(controller: _carModelController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Car Model & Year')),
                const SizedBox(height: 12),
                TextField(controller: _descriptionController, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Additional Details')),
                const SizedBox(height: 24),
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          if (_partNameController.text.isEmpty || _carModelController.text.isEmpty) return;
                          setModalState(() => _isSubmitting = true);
                          final token = await ApiService.getToken();
                          final res = await http.post(
                            Uri.parse('${ApiService.baseUrl}/spare-parts/'),
                            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                            body: json.encode({
                              'part_name': _partNameController.text,
                              'car_model': _carModelController.text,
                              'description': _descriptionController.text,
                            }),
                          );
                          if (res.statusCode == 200) {
                            Navigator.pop(context);
                            _fetchRequests();
                          } else {
                            setModalState(() => _isSubmitting = false);
                          }
                        },
                        child: const Text('SUBMIT REQUEST'),
                      ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showOfferDialog(int requestId, String partName) {
    final _priceController = TextEditingController();
    final _notesController = TextEditingController();
    bool _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Offer for: $partName', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: _priceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Asking Price (₹)')),
                const SizedBox(height: 12),
                TextField(controller: _notesController, maxLines: 2, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Condition / Notes')),
                const SizedBox(height: 24),
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          if (_priceController.text.isEmpty) return;
                          setModalState(() => _isSubmitting = true);
                          final token = await ApiService.getToken();
                          final res = await http.post(
                            Uri.parse('${ApiService.baseUrl}/spare-parts/$requestId/offers'),
                            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                            body: json.encode({
                              'price': double.tryParse(_priceController.text) ?? 0,
                              'notes': _notesController.text,
                            }),
                          );
                          if (res.statusCode == 200) {
                            Navigator.pop(context);
                            _fetchRequests();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer submitted successfully!'), backgroundColor: Colors.green));
                          } else {
                            setModalState(() => _isSubmitting = false);
                          }
                        },
                        child: const Text('SUBMIT OFFER'),
                      ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context).role;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: (role == 'user' || role == 'admin')
          ? FloatingActionButton.extended(
              onPressed: _showRequestDialog,
              backgroundColor: const Color(0xFF10B981),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Request Part', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _requests.isEmpty
              ? Center(child: Text(role == 'workshop' ? 'No active spare part requests.' : 'You have no requested parts.', style: const TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final List offers = req['offers'] ?? [];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 24.0),
                      color: const Color(0xFF1E293B).withOpacity(0.9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(req['part_name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(8)),
                                  child: Text(req['car_model'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(req['description'] ?? '', style: const TextStyle(color: Colors.white70)),
                            const Divider(color: Colors.white12, height: 24),
                            if ((role == 'user' || role == 'admin') && offers.isNotEmpty) ...[
                              const Text('Workshop Offers', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...offers.map((o) => Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(o['notes'] ?? 'No notes provided', style: const TextStyle(color: Colors.white70, fontSize: 13))),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('₹${o['price']}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () => _startChat(o['id'], 'Workshop', req['part_name']),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('MESSAGE', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        )
                                      ]
                                    ),
                                  ],
                                ),
                              )).toList()
                            ],
                            if ((role == 'user' || role == 'admin') && offers.isEmpty)
                              const Text('Awaiting offers from workshops...', style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),
                            if (role == 'workshop')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(vertical: 12)),
                                    onPressed: () => _showOfferDialog(req['id'], req['part_name']),
                                    icon: const Icon(Icons.local_offer, size: 18),
                                    label: const Text('SUBMIT OFFER'),
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
