import 'dart:convert';

/// Data model representing the full analysis response from the backend API.
class AnalysisResult {
  final String id;
  final String timestamp;
  final String status;
  final String extractedText;
  final String textLanguage;
  final ImageAnalysis imageAnalysis;
  final PredictionResult prediction;
  final SourcesResult sources;
  final CredibilityScore credibilityScore;
  final String explanation;
  final String verdict;

  AnalysisResult({
    required this.id,
    required this.timestamp,
    required this.status,
    required this.extractedText,
    required this.textLanguage,
    required this.imageAnalysis,
    required this.prediction,
    required this.sources,
    required this.credibilityScore,
    required this.explanation,
    required this.verdict,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      status: json['status'] ?? 'unknown',
      extractedText: json['extracted_text'] ?? '',
      textLanguage: json['text_language'] ?? 'en',
      imageAnalysis: ImageAnalysis.fromJson(json['image_analysis'] ?? {}),
      prediction: PredictionResult.fromJson(json['prediction'] ?? {}),
      sources: SourcesResult.fromJson(json['sources'] ?? {}),
      credibilityScore:
          CredibilityScore.fromJson(json['credibility_score'] ?? {}),
      explanation: json['explanation'] ?? '',
      verdict: json['verdict'] ?? 'UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'status': status,
        'extracted_text': extractedText,
        'text_language': textLanguage,
        'image_analysis': imageAnalysis.toJson(),
        'prediction': prediction.toJson(),
        'sources': sources.toJson(),
        'credibility_score': credibilityScore.toJson(),
        'explanation': explanation,
        'verdict': verdict,
      };

  /// Serialize to JSON string for local storage.
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string.
  factory AnalysisResult.fromJsonString(String jsonStr) {
    return AnalysisResult.fromJson(jsonDecode(jsonStr));
  }
}

class ImageAnalysis {
  final String contentType;
  final double confidence;
  final String description;

  ImageAnalysis({
    required this.contentType,
    required this.confidence,
    required this.description,
  });

  factory ImageAnalysis.fromJson(Map<String, dynamic> json) {
    return ImageAnalysis(
      contentType: json['content_type'] ?? 'unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'content_type': contentType,
        'confidence': confidence,
        'description': description,
      };
}

class PredictionResult {
  final String label;
  final double confidence;
  final double realProbability;
  final double fakeProbability;
  final String modelUsed;

  PredictionResult({
    required this.label,
    required this.confidence,
    required this.realProbability,
    required this.fakeProbability,
    required this.modelUsed,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      label: json['label'] ?? 'UNKNOWN',
      confidence: (json['confidence'] ?? 0).toDouble(),
      realProbability: (json['real_probability'] ?? 0.5).toDouble(),
      fakeProbability: (json['fake_probability'] ?? 0.5).toDouble(),
      modelUsed: json['model_used'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'real_probability': realProbability,
        'fake_probability': fakeProbability,
        'model_used': modelUsed,
      };
}

class SourceArticle {
  final String title;
  final String source;
  final String url;
  final String publishedAt;
  final String credibilityTier;
  final double similarityScore;

  SourceArticle({
    required this.title,
    required this.source,
    required this.url,
    required this.publishedAt,
    required this.credibilityTier,
    required this.similarityScore,
  });

  factory SourceArticle.fromJson(Map<String, dynamic> json) {
    return SourceArticle(
      title: json['title'] ?? '',
      source: json['source'] ?? 'Unknown',
      url: json['url'] ?? '',
      publishedAt: json['published_at'] ?? '',
      credibilityTier: json['credibility_tier'] ?? 'unknown',
      similarityScore: (json['similarity_score'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'source': source,
        'url': url,
        'published_at': publishedAt,
        'credibility_tier': credibilityTier,
        'similarity_score': similarityScore,
      };
}

class SourcesResult {
  final int totalFound;
  final int trustedSources;
  final List<SourceArticle> articles;

  SourcesResult({
    required this.totalFound,
    required this.trustedSources,
    required this.articles,
  });

  factory SourcesResult.fromJson(Map<String, dynamic> json) {
    return SourcesResult(
      totalFound: json['total_found'] ?? 0,
      trustedSources: json['trusted_sources'] ?? 0,
      articles: (json['articles'] as List<dynamic>?)
              ?.map((a) => SourceArticle.fromJson(a))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'total_found': totalFound,
        'trusted_sources': trustedSources,
        'articles': articles.map((a) => a.toJson()).toList(),
      };
}

class ScoreBreakdown {
  final double aiPrediction;
  final double sourceCoverage;
  final double sourceQuality;
  final double imageAnalysis;

  ScoreBreakdown({
    required this.aiPrediction,
    required this.sourceCoverage,
    required this.sourceQuality,
    required this.imageAnalysis,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      aiPrediction: (json['ai_prediction'] ?? 0).toDouble(),
      sourceCoverage: (json['source_coverage'] ?? 0).toDouble(),
      sourceQuality: (json['source_quality'] ?? 0).toDouble(),
      imageAnalysis: (json['image_analysis'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'ai_prediction': aiPrediction,
        'source_coverage': sourceCoverage,
        'source_quality': sourceQuality,
        'image_analysis': imageAnalysis,
      };
}

class CredibilityScore {
  final int score;
  final String level;
  final ScoreBreakdown breakdown;

  CredibilityScore({
    required this.score,
    required this.level,
    required this.breakdown,
  });

  factory CredibilityScore.fromJson(Map<String, dynamic> json) {
    return CredibilityScore(
      score: json['score'] ?? 50,
      level: json['level'] ?? 'MEDIUM',
      breakdown: ScoreBreakdown.fromJson(json['breakdown'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'level': level,
        'breakdown': breakdown.toJson(),
      };
}
