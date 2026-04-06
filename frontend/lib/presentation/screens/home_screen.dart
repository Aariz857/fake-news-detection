import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fake_news_detector/core/theme/app_colors.dart';
import 'package:fake_news_detector/providers/analysis_provider.dart';

import 'package:fake_news_detector/presentation/widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final provider = context.read<AnalysisProvider>();
        provider.setImage(image);
        _showAnalyzeSheet();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showAnalyzeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AnalyzeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider for potential state-driven UI changes
    context.watch<AnalysisProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // History button row
                _buildTopBar()
                    .animate()
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 12),

                // App Logo & Title
                _buildHeader()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.3),

                const SizedBox(height: 32),

                // Hero Card
                _buildHeroCard()
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .scale(begin: const Offset(0.9, 0.9)),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideY(begin: 0.3),

                const SizedBox(height: 32),

                // Features Section
                _buildFeaturesSection()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 600.ms),

                const SizedBox(height: 32),

                // Stats Section
                _buildStatsRow()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 800.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/history'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded,
                    size: 18,
                    color: AppColors.primary.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  'History',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Shield icon with glow
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.shield_outlined, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'Fake News Detector',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'AI-Powered News Verification',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white54,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Animated scan icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: 0.3 + _pulseController.value * 0.4,
                      ),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: _pulseController.value * 0.3,
                        ),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.document_scanner_outlined,
                    size: 48,
                    color: AppColors.primary.withValues(
                      alpha: 0.7 + _pulseController.value * 0.3,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Scan News for Authenticity',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Capture or upload an image of any news content. Our AI will analyze it using OCR, deep learning, and source verification.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white60,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Camera Button (Primary)
        SizedBox(
          width: double.infinity,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded, size: 24),
              label: Text(
                'Take a Photo',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Gallery Button (Secondary)
        SizedBox(
          width: double.infinity,
          height: 60,
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded,
                size: 24, color: AppColors.primary),
            label: Text(
              'Upload from Gallery',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.text_snippet_outlined,
        'title': 'OCR Extraction',
        'desc': 'Extract text from images'
      },
      {
        'icon': Icons.psychology_outlined,
        'title': 'AI Classification',
        'desc': 'Deep learning analysis'
      },
      {
        'icon': Icons.travel_explore,
        'title': 'Source Verification',
        'desc': 'Cross-reference news sources'
      },
      {
        'icon': Icons.analytics_outlined,
        'title': 'Credibility Score',
        'desc': 'Multi-factor trust rating'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final f = features[index];
            return GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    f['icon'] as IconData,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    f['title'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f['desc'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 100 * index))
                .fadeIn()
                .scale(begin: const Offset(0.8, 0.8));
          },
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('AI Models', '3+', Icons.memory),
            _divider(),
            _statItem('Sources', '20+', Icons.newspaper),
            _divider(),
            _statItem('Accuracy', '94%', Icons.verified),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white12,
    );
  }
}

/// Bottom sheet shown after image selection
class _AnalyzeBottomSheet extends StatelessWidget {
  const _AnalyzeBottomSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Image preview
          if (provider.selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FutureBuilder<Uint8List>(
                future: provider.selectedImage!.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  }
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),

          // Status
          if (provider.isLoading) ...[
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              provider.statusMessage,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
          ] else if (provider.state == AnalysisState.error) ...[
            Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage,
              style: GoogleFonts.inter(color: AppColors.danger, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => provider.analyzeImage(),
              child: const Text('Retry'),
            ),
          ] else ...[
            Text(
              'Ready to analyze',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our AI will extract text, verify sources, and determine credibility.',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),

          // Analyze button
          if (!provider.isLoading)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await provider.analyzeImage();
                    if (provider.state == AnalysisState.success && context.mounted) {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.pushNamed(context, '/result');
                    }
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(
                    'Analyze Now',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
