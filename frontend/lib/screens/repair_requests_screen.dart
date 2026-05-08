import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

class RepairRequestsScreen extends StatefulWidget {
  @override
  _RepairRequestsScreenState createState() => _RepairRequestsScreenState();
}

class _RepairRequestsScreenState extends State<RepairRequestsScreen> {
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
      Uri.parse('${ApiService.baseUrl}/repairs/'),
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

  Future<void> _startChat(int bidId, String partnerName, String partName) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final token = await ApiService.getToken();
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}/chat/threads'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'bid_id': bidId}),
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

  Future<void> _deleteRequest(int requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Delete Request', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this spare part request?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    final token = await ApiService.getToken();
    final res = await http.delete(
      Uri.parse('${ApiService.baseUrl}/repairs/$requestId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 204) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request deleted'), backgroundColor: Colors.green));
      _fetchRequests();
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete'), backgroundColor: Colors.red));
    }
  }

  void _showRequestDialog() {
    final partNameController = TextEditingController();
    final carModelController = TextEditingController();
    final descriptionController = TextEditingController();
    File? selectedImage;
    final picker = ImagePicker();
    bool isSubmitting = false;

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
                TextField(controller: partNameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Vehicle Details')),
                const SizedBox(height: 12),
                TextField(controller: carModelController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Damage Description')),
                const SizedBox(height: 12),
                TextField(controller: descriptionController, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Additional Details')),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setModalState(() {
                        selectedImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      image: selectedImage != null ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover) : null,
                    ),
                    child: selectedImage == null ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white54, size: 32),
                        SizedBox(height: 8),
                        Text('Attach Photo (Optional)', style: TextStyle(color: Colors.white54)),
                      ],
                    ) : null,
                  ),
                ),
                const SizedBox(height: 24),
                isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          if (partNameController.text.isEmpty || carModelController.text.isEmpty) return;
                          setModalState(() => isSubmitting = true);
                          final token = await ApiService.getToken();
                          
                          final request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/repairs/'));
                          request.headers['Authorization'] = 'Bearer $token';
                          request.fields['vehicle_details'] = partNameController.text;
                          request.fields['damage_description'] = carModelController.text;
                          request.fields['description'] = descriptionController.text;
                          
                          if (selectedImage != null) {
                            request.files.add(await http.MultipartFile.fromPath('image', selectedImage!.path));
                          }
                          
                          final streamedResponse = await request.send();
                          final res = await http.Response.fromStream(streamedResponse);
                          
                          if (!context.mounted) return;

                          if (res.statusCode == 200) {
                            Navigator.pop(context);
                            _fetchRequests();
                          } else {
                            setModalState(() => isSubmitting = false);
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

  void _showBidDialog(int requestId, String partName) {
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;

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
                Text('Bid for: $partName', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: priceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Asking Price (₹)')),
                const SizedBox(height: 12),
                TextField(controller: notesController, maxLines: 2, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Condition / Notes')),
                const SizedBox(height: 24),
                isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          if (priceController.text.isEmpty) return;
                          setModalState(() => isSubmitting = true);
                          final token = await ApiService.getToken();
                          final res = await http.post(
                            Uri.parse('${ApiService.baseUrl}/repairs/$requestId/bids'),
                            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                            body: json.encode({
                              'amount': double.tryParse(priceController.text) ?? 0,
                              'notes': notesController.text,
                            }),
                          );

                          if (!context.mounted) return;

                          if (res.statusCode == 200) {
                            Navigator.pop(context);
                            _fetchRequests();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid submitted successfully!'), backgroundColor: Colors.green));
                          } else {
                            setModalState(() => isSubmitting = false);
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
              label: const Text('Request Repair', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    final List bids = req['bids'] ?? [];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 24.0),
                      color: const Color(0xFF1E293B).withValues(alpha: 0.9),
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
                                Expanded(child: Text(req['vehicle_details'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(8)),
                                  child: Text(req['damage_description'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                ),
                                if (role == 'user' || role == 'admin')
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteRequest(req['id']),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (req['image_path'] != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '${ApiService.baseUrl.replaceAll('/api', '')}/${req['image_path']}',
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(req['description'] ?? '', style: const TextStyle(color: Colors.white70)),
                            const Divider(color: Colors.white12, height: 24),
                            if ((role == 'user' || role == 'admin') && bids.isNotEmpty) ...[
                              const Text('Workshop Bids', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...bids.map((o) => Container(
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
                                        Text('₹${o['amount']}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () => _startChat(o['id'], 'Workshop', req['vehicle_details']),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('MESSAGE', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        )
                                      ]
                                    ),
                                  ],
                                ),
                              )),
                            ],
                            if ((role == 'user' || role == 'admin') && bids.isEmpty)
                              const Text('Awaiting bids from workshops...', style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),
                            if (role == 'workshop')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(vertical: 12)),
                                    onPressed: () => _showBidDialog(req['id'], req['vehicle_details']),
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
