import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/theme.dart';
import '../utils/config.dart';

class VisionScannerScreen extends ConsumerStatefulWidget {
  final String initialMode; // 'landmark' or 'menu'

  const VisionScannerScreen({super.key, this.initialMode = 'landmark'});

  @override
  ConsumerState<VisionScannerScreen> createState() => _VisionScannerScreenState();
}

class _VisionScannerScreenState extends ConsumerState<VisionScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  late String _selectedMode;
  Uint8List? _imageBytes;
  String? _imageMimeType;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _analysisResult;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageMimeType = file.mimeType ?? 'image/jpeg';
          _analysisResult = null;
          _errorMessage = null;
        });
        _analyzeImage();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture or load image: $e';
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Please log in to use AI Vision features.');
      }

      final base64Image = base64Encode(_imageBytes!);

      final response = await _dio.post(
        '${AppConfig.baseUrl}/vision/analyze',
        data: {
          'imageBase64': base64Image,
          'mimeType': _imageMimeType ?? 'image/jpeg',
          'mode': _selectedMode,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      setState(() {
        _isLoading = false;
        _analysisResult = response.data['result'] as Map<String, dynamic>?;
      });
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to analyze image with AI Vision.';
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Vision Scanner', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Segmented Switcher
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      'landmark',
                      Icons.account_balance,
                      'Landmark',
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      'menu',
                      Icons.restaurant_menu,
                      'Menu Translate',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Image Preview or Placeholder
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder, width: 1.5),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedMode == 'landmark' ? Icons.camera_alt_outlined : Icons.document_scanner_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedMode == 'landmark'
                              ? 'Capture or select a monument / landmark'
                              : 'Capture or select a foreign restaurant menu',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Action Buttons (Camera / Gallery)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text('Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Loading / Error / Results Card
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.accent),
                      SizedBox(height: 16),
                      Text('Gemini Vision is analyzing the image...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              )
            else if (_analysisResult != null)
              _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String modeKey, IconData icon, String label) {
    final isSelected = _selectedMode == modeKey;
    return GestureDetector(
      onTap: () {
        if (_selectedMode != modeKey) {
          setState(() {
            _selectedMode = modeKey;
            _analysisResult = null;
          });
          if (_imageBytes != null) {
            _analyzeImage();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final data = _analysisResult!;

    if (_selectedMode == 'landmark') {
      final name = data['name'] ?? 'Landmark Identified';
      final city = data['city'] ?? '';
      final history = data['historicalSummary'] ?? '';
      final style = data['architecturalStyle'] ?? '';
      final funFact = data['funFact'] ?? '';
      final tips = (data['visitingTips'] as List?)?.map((t) => t.toString()).toList() ?? [];

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      if (city.isNotEmpty) Text(city, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (style.isNotEmpty) ...[
              _buildBadge('Architecture', style),
              const SizedBox(height: 12),
            ],
            if (history.isNotEmpty) ...[
              const Text('Historical Significance:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(history, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
              const SizedBox(height: 12),
            ],
            if (tips.isNotEmpty) ...[
              const Text('Visiting Tips:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              ...tips.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(t, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],
            if (funFact.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Fun Fact: $funFact', style: const TextStyle(color: Colors.white, fontSize: 11, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    } else {
      final menuTitle = data['menuTitle'] ?? 'Menu Translation';
      final recommendation = data['recommendation'] ?? '';
      final dishes = (data['dishes'] as List?) ?? [];

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.translate, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(menuTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
            if (recommendation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Chef Recommendation: $recommendation', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Translated Dishes:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            if (dishes.isEmpty)
              const Text('No specific dishes detected.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
            else
              ...dishes.map((d) {
                final orig = d['originalName'] ?? '';
                final trans = d['translatedName'] ?? '';
                final desc = d['description'] ?? '';
                final alert = d['dietaryAlert'] ?? '';
                final price = d['estimatedPrice'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              trans.isNotEmpty ? trans : orig,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                          ),
                          if (price.isNotEmpty) Text(price, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      if (orig.isNotEmpty && orig != trans)
                        Text(orig, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                      if (alert.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(alert, style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ]
                    ],
                  ),
                );
              }),
          ],
        ),
      );
    }
  }

  Widget _buildBadge(String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Text('$title: $val', style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
