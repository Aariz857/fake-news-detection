import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fake_news_detector/core/theme/app_colors.dart';
import 'package:fake_news_detector/data/models/analysis_result.dart';
import 'package:fake_news_detector/providers/analysis_provider.dart';
import 'package:fake_news_detector/presentation/widgets/glass_card.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _savedFeedbackShown = false;

  void _shareResult(AnalysisResult result) {
    final shareText = '''🔍 Fake News Analysis Report
━━━━━━━━━━━━━━━━━━━━━━━

📋 Verdict: ${result.verdict}
🛡️ Credibility Score: ${result.credibilityScore.score}/100 (${result.credibilityScore.level})
🤖 AI Prediction: ${result.prediction.label} (${(result.prediction.confidence * 100).toStringAsFixed(1)}% confidence)

📝 Extracted Text:
${result.extractedText.isNotEmpty ? (result.extractedText.length > 300 ? '${result.extractedText.substring(0, 300)}...' : result.extractedText) : 'No text detected'}

📰 Sources Found: ${result.sources.totalFound} (${result.sources.trustedSources} trusted)

💡 AI Analysis:
${result.explanation}

━━━━━━━━━━━━━━━━━━━━━━━
Analyzed with Fake News Detector AI''';

    Share.share(shareText);
  }

  void _showSavedFeedback(BuildContext context) {
    if (_savedFeedbackShown) return;
    _savedFeedbackShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bookmark_added_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Text(
                'Saved to history',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final result = provider.result;

    if (result == null) {
      return Scaffold(
        body: Container(
          decoration:
              const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: const Center(child: Text('No results available')),
        ),
      );
    }

    // Show "Saved to history" feedback for fresh analyses
    if (provider.selectedImage != null) {
      _showSavedFeedback(context);
    }

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () {
                    provider.reset();
                    Navigator.pop(context);
                  },
                ),
                title: Text('Analysis Results',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: 'Share result',
                    onPressed: () => _shareResult(result),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Verdict Banner
                    _VerdictBanner(result: result)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.2),
                    const SizedBox(height: 20),

                    // Credibility Gauge
                    _CredibilityGauge(score: result.credibilityScore)
                        .animate()
                        .fadeIn(duration: 700.ms, delay: 200.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                    const SizedBox(height: 20),

                    // Uploaded Image
                    if (provider.selectedImage != null)
                      _ImagePreviewCard(
                              imageFile: provider.selectedImage!,
                              imageAnalysis: result.imageAnalysis)
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 300.ms),
                    const SizedBox(height: 16),

                    // Extracted Text
                    if (result.extractedText.isNotEmpty)
                      _ExtractedTextCard(text: result.extractedText)
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 400.ms),
                    const SizedBox(height: 16),

                    // Prediction Details
                    _PredictionCard(prediction: result.prediction)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 500.ms),
                    const SizedBox(height: 16),

                    // Sources
                    _SourcesCard(sources: result.sources)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 600.ms),
                    const SizedBox(height: 16),

                    // AI Explanation
                    if (result.explanation.isNotEmpty)
                      _ExplanationCard(explanation: result.explanation)
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 700.ms),
                    const SizedBox(height: 16),

                    // Score Breakdown
                    _ScoreBreakdownCard(score: result.credibilityScore)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 800.ms),

                    const SizedBox(height: 24),

                    // View History button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: GestureDetector(
                        onTap: () {
                          provider.reset();
                          Navigator.pushReplacementNamed(context, '/history');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded,
                                  color: AppColors.primary.withValues(alpha: 0.8),
                                  size: 20),
                              const SizedBox(width: 8),
                              Text('View History',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 900.ms),

                    const SizedBox(height: 12),

                    // Analyze Another Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          provider.reset();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.camera_alt_rounded,
                            color: AppColors.primary),
                        label: Text('Analyze Another Image',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================
// VERDICT BANNER
// ================================
class _VerdictBanner extends StatelessWidget {
  final AnalysisResult result;
  const _VerdictBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final isFake = result.prediction.label == 'FAKE';
    final gradient = isFake ? AppColors.dangerGradient : AppColors.successGradient;
    final icon = isFake ? Icons.warning_rounded : Icons.verified_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isFake ? AppColors.danger : AppColors.success)
                .withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            result.verdict,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Confidence: ${(result.prediction.confidence * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================
// CREDIBILITY GAUGE
// ================================
class _CredibilityGauge extends StatelessWidget {
  final CredibilityScore score;
  const _CredibilityGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getScoreColor(score.score);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Credibility Score',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            CircularPercentIndicator(
              radius: 80,
              lineWidth: 12,
              percent: score.score / 100,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${score.score}',
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    score.level,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              progressColor: color,
              backgroundColor: color.withValues(alpha: 0.15),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1500,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================
// IMAGE PREVIEW
// ================================
class _ImagePreviewCard extends StatelessWidget {
  final XFile imageFile;
  final ImageAnalysis imageAnalysis;
  const _ImagePreviewCard({required this.imageFile, required this.imageAnalysis});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.image_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Uploaded Image',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    imageAnalysis.contentType.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: FutureBuilder<Uint8List>(
              future: imageFile.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    width: double.infinity,
                    height: 200,
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
        ],
      ),
    );
  }
}

// ================================
// EXTRACTED TEXT
// ================================
class _ExtractedTextCard extends StatefulWidget {
  final String text;
  const _ExtractedTextCard({required this.text});

  @override
  State<_ExtractedTextCard> createState() => _ExtractedTextCardState();
}

class _ExtractedTextCardState extends State<_ExtractedTextCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final displayText = _expanded
        ? widget.text
        : (widget.text.length > 200
            ? '${widget.text.substring(0, 200)}...'
            : widget.text);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_snippet_rounded,
                    color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Text('Extracted Text',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                const Spacer(),
                Text('${widget.text.split(' ').length} words',
                    style:
                        GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                displayText,
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white70, height: 1.5),
              ),
            ),
            if (widget.text.length > 200)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show Less' : 'Show More',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.primary)),
              ),
          ],
        ),
      ),
    );
  }
}

// ================================
// PREDICTION DETAILS
// ================================
class _PredictionCard extends StatelessWidget {
  final PredictionResult prediction;
  const _PredictionCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('AI Prediction',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            // Real probability bar
            _probabilityBar('Real', prediction.realProbability, AppColors.success),
            const SizedBox(height: 10),
            // Fake probability bar
            _probabilityBar('Fake', prediction.fakeProbability, AppColors.danger),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.memory, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Text(
                  'Model: ${prediction.modelUsed}',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _probabilityBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 45,
          child: Text(
            '${(value * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }
}

// ================================
// SOURCES LIST
// ================================
class _SourcesCard extends StatelessWidget {
  final SourcesResult sources;
  const _SourcesCard({required this.sources});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.newspaper_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text('News Sources',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${sources.totalFound} found',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${sources.trustedSources} from trusted outlets',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 12),
            // Articles list
            ...sources.articles
                .take(5)
                .map((article) => _SourceTile(article: article)),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final SourceArticle article;
  const _SourceTile({required this.article});

  Color _getTierColor() {
    switch (article.credibilityTier) {
      case 'high':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.danger;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final url = Uri.parse(article.url);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Credibility indicator
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: _getTierColor(),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        article.source,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getTierColor()),
                      ),
                      const Spacer(),
                      Text(
                        article.credibilityTier.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _getTierColor(),
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ================================
// AI EXPLANATION
// ================================
class _ExplanationCard extends StatelessWidget {
  final String explanation;
  const _ExplanationCard({required this.explanation});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_fix_high_rounded,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text('AI Analysis',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              explanation,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white70, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================
// SCORE BREAKDOWN
// ================================
class _ScoreBreakdownCard extends StatelessWidget {
  final CredibilityScore score;
  const _ScoreBreakdownCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final breakdown = score.breakdown;
    final maxValues = {
      'AI Prediction': 40.0,
      'Source Coverage': 30.0,
      'Source Quality': 20.0,
      'Image Analysis': 10.0,
    };
    final values = {
      'AI Prediction': breakdown.aiPrediction,
      'Source Coverage': breakdown.sourceCoverage,
      'Source Quality': breakdown.sourceQuality,
      'Image Analysis': breakdown.imageAnalysis,
    };

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_rounded,
                    color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Text('Score Breakdown',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            ...values.entries.map((entry) {
              final max = maxValues[entry.key]!;
              final value = entry.value;
              final percent = max > 0 ? value / max : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white60)),
                        Text(
                            '${value.toStringAsFixed(1)} / ${max.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent.clamp(0.0, 1.0),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                            AppColors.getScoreColor(score.score)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
