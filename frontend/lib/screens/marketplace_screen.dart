import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class MarketplaceScreen extends StatefulWidget {
  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<dynamic> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/marketplace/'));

    if (response.statusCode == 200) {
      if(mounted){
        setState(() {
          _vehicles = json.decode(response.body);
          _isLoading = false;
        });
      }
    } else {
      if(mounted){
        setState(() => _isLoading = false);
      }
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

  void _showAddVehicleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddVehicleForm(onVehicleAdded: _fetchVehicles),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Basic screen parsing logic
    final String imageBaseUrl = ApiService.baseUrl.replaceAll('/api', '');

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVehicleDialog,
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add_circle, color: Colors.white),
        label: const Text('List Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _vehicles.isEmpty
              ? const Center(child: Text('No vehicles available in the marketplace.', style: TextStyle(color: Colors.white54)))
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
                            if (imagePath != null)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                                    backgroundColor: Colors.black,
                                    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
                                    body: Center(
                                      child: InteractiveViewer(
                                        panEnabled: true,
                                        minScale: 1,
                                        maxScale: 4,
                                        child: Image.network(imageUrl),
                                      )
                                    )
                                  )));
                                },
                                child: Image.network(
                                  imageUrl,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    color: const Color(0xFF334155),
                                    child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48)),
                                  ),
                                ),
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
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '₹${vehicle['price']}',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                      ),
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
                                  const Divider(color: Colors.white12, height: 24),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 16, color: Color(0xFF3B82F6)),
                                      const SizedBox(width: 8),
                                      Text(vehicle['contact_info'] ?? '', style: const TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  InkWell(
                                     onTap: hasAccidents ? () => _showHistoryDialog(context, vehicle) : null,
                                     child: Container(
                                       padding: const EdgeInsets.all(12),
                                       decoration: BoxDecoration(
                                         color: !hasAccidents 
                                            ? const Color(0xFF10B981).withOpacity(0.1) 
                                            : const Color(0xFFEF4444).withOpacity(0.1),
                                         borderRadius: BorderRadius.circular(12),
                                         border: Border.all(
                                            color: !hasAccidents 
                                              ? const Color(0xFF10B981).withOpacity(0.5) 
                                              : const Color(0xFFEF4444).withOpacity(0.5)
                                         )
                                       ),
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Row(
                                             children: [
                                               Icon(
                                                 !hasAccidents ? Icons.check_circle : Icons.warning,
                                                 color: !hasAccidents ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                 size: 20,
                                               ),
                                               const SizedBox(width: 8),
                                               const Text('History Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                             ],
                                           ),
                                           const SizedBox(height: 8),
                                           Text(
                                             !hasAccidents ? 'Clean History - No accidents reported' : 'Accident History Found! (Tap to View Details)',
                                             style: const TextStyle(color: Colors.white70, fontSize: 13),
                                           ),
                                         ],
                                       ),
                                     )
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

class AddVehicleForm extends StatefulWidget {
  final VoidCallback onVehicleAdded;
  const AddVehicleForm({required this.onVehicleAdded});

  @override
  _AddVehicleFormState createState() => _AddVehicleFormState();
}

class _AddVehicleFormState extends State<AddVehicleForm> {
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();
  
  File? _image;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty || _modelController.text.isEmpty || _yearController.text.isEmpty ||
        _plateController.text.isEmpty || _priceController.text.isEmpty || _descController.text.isEmpty ||
        _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all text fields.'), backgroundColor: Colors.redAccent));
      return;
    }
    
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An image of the vehicle is mandatory.'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await ApiService.getToken();
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/marketplace/'));
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['vehicle_name'] = _nameController.text;
      request.fields['model'] = _modelController.text;
      request.fields['year'] = _yearController.text;
      request.fields['plate_number'] = _plateController.text.toUpperCase();
      request.fields['price'] = _priceController.text;
      request.fields['description'] = _descController.text;
      request.fields['contact_info'] = _contactController.text;
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

      final response = await request.send();
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle listed successfully!'), backgroundColor: Color(0xFF10B981)));
        Navigator.pop(context);
        widget.onVehicleAdded();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to list vehicle. Please try again.'), backgroundColor: Colors.redAccent));
      }
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred.'), backgroundColor: Colors.redAccent));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('List a Vehicle', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Make / Brand')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _modelController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Model'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _yearController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Year'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _plateController, textCapitalization: TextCapitalization.characters, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Plate Number'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _priceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Asking Price (₹)'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _contactController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Contact Info (Phone/Email)')),
                  const SizedBox(height: 12),
                  TextField(controller: _descController, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 24),
                  const Text('Vehicle Photo (Mandatory)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
                      ),
                      child: _image == null
                          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.camera_alt, color: Color(0xFF3B82F6), size: 40), SizedBox(height: 8), Text('Tap to select image', style: TextStyle(color: Colors.white54))])
                          : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('SUBMIT LISTING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                ),
        ],
      ),
    );
  }
}

