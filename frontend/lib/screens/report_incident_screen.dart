import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ReportIncidentScreen extends StatefulWidget {
  @override
  _ReportIncidentScreenState createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _plateController = TextEditingController();
  final _descController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  String? _aiEstimation;

  final ImagePicker _picker = ImagePicker();

  bool _hasValidAiEstimation() {
    final text = _aiEstimation?.trim() ?? '';
    if (text.isEmpty) return false;
    final lower = text.toLowerCase();
    return !lower.startsWith('failed') && !lower.startsWith('error');
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _getAiEstimation();
    }
  }

  Future<void> _getAiEstimation() async {
    if (_image == null) return;
    
    final token = await ApiService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/ai/estimate-damage'));
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

    setState(() => _isLoading = true);
    
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        setState(() {
          _aiEstimation = "Damage: ${data['percentage']}%\\n${data['estimation']}";
        });
      } else {
        setState(() => _aiEstimation = "Failed to get AI estimation.");
      }
    } catch(e) {
      setState(() => _aiEstimation = "Error during AI estimation.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReport() async {
    if (_plateController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields.'), backgroundColor: Colors.redAccent));
      return;
    }

    if (_image != null && !_hasValidAiEstimation()) {
      await _getAiEstimation();
    }

    setState(() => _isLoading = true);

    final token = await ApiService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/reports/'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['plate_number'] = _plateController.text.toUpperCase();
    request.fields['description'] = _descController.text;
    if (_hasValidAiEstimation()) {
      request.fields['ai_damage_estimation'] = _aiEstimation!.trim();
    }
    
    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully!'), backgroundColor: Color(0xFF10B981)));
      _plateController.clear();
      _descController.clear();
      setState(() {
        _image = null;
        _aiEstimation = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit report.'), backgroundColor: Colors.redAccent));
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Report Incident', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Submit vehicle damage details securely.', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          TextField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(labelText: 'Plate Number', prefixIcon: Icon(Icons.badge, color: Color(0xFF3B82F6))),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Incident Description', alignLabelWithHint: true, prefixIcon: Padding(padding: EdgeInsets.only(bottom: 60), child: Icon(Icons.description, color: Color(0xFF3B82F6)))),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5), width: 2, style: BorderStyle.solid),
              ),
              child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.camera_alt, size: 48, color: Color(0xFF3B82F6)),
                        SizedBox(height: 8),
                        Text('Tap to capture or pick photo', style: TextStyle(color: Colors.white70)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
                    ),
            ),
          ),
          if (_aiEstimation != null) ...[
            const SizedBox(height: 24),
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
                      Text('AI Analysis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_aiEstimation!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
              : ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('SUBMIT REPORT'),
                  onPressed: _submitReport,
                ),
        ],
      ),
    );
  }
}
