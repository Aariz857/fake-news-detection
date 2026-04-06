import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fake_news_detector/core/theme/app_colors.dart';
import 'package:fake_news_detector/data/models/analysis_result.dart';
import 'package:fake_news_detector/providers/analysis_provider.dart';
import 'package:fake_news_detector/presentation/widgets/glass_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load history on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisProvider>().refreshHistory();
    });
  }

  void _confirmClearAll(BuildContext context) {
    final provider = context.read<AnalysisProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear All History?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'This will permanently delete all saved analyses. This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('History cleared',
                      style: GoogleFonts.inter(color: Colors.white)),
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.inter(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final history = provider.history;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildAppBar(context, history.length),
              // Content
              Expanded(
                child: history.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(context, history),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis History',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count ${count == 1 ? 'analysis' : 'analyses'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ),
          if (count > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: AppColors.danger, size: 24),
              tooltip: 'Clear All',
              onPressed: () => _confirmClearAll(context),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated empty icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.05, duration: 2000.ms),
            const SizedBox(height: 28),
            Text(
              'No Analyses Yet',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Scan a news image to get started.\nYour analysis history will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: Text(
                    'Start Scanning',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildHistoryList(
      BuildContext context, List<AnalysisResult> history) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final result = history[index];
        return Dismissible(
          key: Key(result.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: AppColors.dangerGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 4),
                Text(
                  'Delete',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('Delete Analysis?',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                content: Text(
                  'This analysis result will be permanently removed.',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Delete',
                        style: GoogleFonts.inter(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            context.read<AnalysisProvider>().deleteFromHistory(result.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Analysis deleted',
                    style: GoogleFonts.inter(color: Colors.white)),
                backgroundColor: AppColors.surface,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: _HistoryCard(
            result: result,
            onTap: () {
              final provider = context.read<AnalysisProvider>();
              provider.viewHistoryResult(result);
              Navigator.pushNamed(context, '/result');
            },
          ),
        )
            .animate(delay: Duration(milliseconds: 60 * index))
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.1);
      },
    );
  }
}

// ================================
// HISTORY CARD
// ================================
class _HistoryCard extends StatelessWidget {
  final AnalysisResult result;
  final VoidCallback onTap;

  const _HistoryCard({required this.result, required this.onTap});

  Color _getVerdictColor() {
    switch (result.verdict.toUpperCase()) {
      case 'LIKELY REAL':
      case 'VERIFIED':
        return AppColors.success;
      case 'UNCERTAIN':
      case 'NEEDS REVIEW':
        return AppColors.warning;
      case 'LIKELY FAKE':
      case 'FAKE':
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }

  IconData _getVerdictIcon() {
    switch (result.verdict.toUpperCase()) {
      case 'LIKELY REAL':
      case 'VERIFIED':
        return Icons.verified_rounded;
      case 'UNCERTAIN':
      case 'NEEDS REVIEW':
        return Icons.help_rounded;
      case 'LIKELY FAKE':
      case 'FAKE':
        return Icons.warning_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _formatTimestamp() {
    try {
      final dt = DateTime.parse(result.timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final verdictColor = _getVerdictColor();
    final scoreColor = AppColors.getScoreColor(result.credibilityScore.score);
    final textPreview = result.extractedText.isNotEmpty
        ? (result.extractedText.length > 80
            ? '${result.extractedText.substring(0, 80)}...'
            : result.extractedText)
        : 'No text extracted';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: verdict badge + timestamp
                Row(
                  children: [
                    // Verdict badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: verdictColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: verdictColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getVerdictIcon(),
                              size: 14, color: verdictColor),
                          const SizedBox(width: 6),
                          Text(
                            result.verdict,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: verdictColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Timestamp
                    Text(
                      _formatTimestamp(),
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Text preview
                Text(
                  textPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                // Bottom row: score + prediction + arrow
                Row(
                  children: [
                    // Credibility score pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded,
                              size: 13, color: scoreColor),
                          const SizedBox(width: 4),
                          Text(
                            '${result.credibilityScore.score}/100',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scoreColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Prediction label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(result.prediction.confidence * 100).toStringAsFixed(0)}% ${result.prediction.label}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Arrow
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
