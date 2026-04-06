import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fake_news_detector/data/models/analysis_result.dart';
import 'package:fake_news_detector/data/services/api_service.dart';
import 'package:fake_news_detector/data/services/storage_service.dart';

enum AnalysisState { idle, picking, uploading, analyzing, success, error }

class AnalysisProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  AnalysisState _state = AnalysisState.idle;
  AnalysisResult? _result;
  XFile? _selectedImage;
  String _errorMessage = '';
  String _statusMessage = '';
  List<AnalysisResult> _history = [];
  bool _historyLoaded = false;

  // Getters
  AnalysisState get state => _state;
  AnalysisResult? get result => _result;
  XFile? get selectedImage => _selectedImage;
  String get errorMessage => _errorMessage;
  String get statusMessage => _statusMessage;
  bool get isLoading =>
      _state == AnalysisState.uploading || _state == AnalysisState.analyzing;
  List<AnalysisResult> get history => _history;

  /// Set the selected image file
  void setImage(XFile image) {
    _selectedImage = image;
    _state = AnalysisState.idle;
    _result = null;
    _errorMessage = '';
    notifyListeners();
  }

  /// Run the full analysis pipeline
  Future<void> analyzeImage() async {
    if (_selectedImage == null) {
      _errorMessage = 'No image selected';
      _state = AnalysisState.error;
      notifyListeners();
      return;
    }

    try {
      // Stage 1: Uploading
      _state = AnalysisState.uploading;
      _statusMessage = 'Uploading image...';
      _errorMessage = '';
      notifyListeners();

      // Small delay for UI feedback
      await Future.delayed(const Duration(milliseconds: 500));

      // Stage 2: Analyzing
      _state = AnalysisState.analyzing;
      _statusMessage = 'Analyzing content...';
      notifyListeners();

      // Call API
      _result = await _apiService.analyzeImage(_selectedImage!);

      // Stage 3: Success
      _state = AnalysisState.success;
      _statusMessage = 'Analysis complete!';
      notifyListeners();

      // Save to local history
      if (_result != null) {
        await _saveToHistory(_result!);
      }
    } catch (e) {
      _state = AnalysisState.error;
      _errorMessage = e.toString();
      _statusMessage = '';
      notifyListeners();
    }
  }

  /// Reset the analysis state
  void reset() {
    _state = AnalysisState.idle;
    _result = null;
    _selectedImage = null;
    _errorMessage = '';
    _statusMessage = '';
    notifyListeners();
  }

  /// Load a past result for viewing
  void viewHistoryResult(AnalysisResult result) {
    _result = result;
    _selectedImage = null;
    _state = AnalysisState.success;
    notifyListeners();
  }

  // ========== History Management ==========

  /// Load history from local storage
  Future<void> loadHistory() async {
    if (_historyLoaded) return;
    try {
      _history = await _storageService.getHistory();
      _historyLoaded = true;
      notifyListeners();
    } catch (e) {
      _history = [];
    }
  }

  /// Force-reload history from storage
  Future<void> refreshHistory() async {
    _historyLoaded = false;
    await loadHistory();
  }

  /// Save a result to local history
  Future<void> _saveToHistory(AnalysisResult result) async {
    try {
      await _storageService.saveResult(result);
      // Reload to keep in sync
      _history = await _storageService.getHistory();
      _historyLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save to history: $e');
    }
  }

  /// Delete a single entry from history
  Future<void> deleteFromHistory(String id) async {
    try {
      await _storageService.deleteResult(id);
      _history.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete from history: $e');
    }
  }

  /// Clear all history
  Future<void> clearHistory() async {
    try {
      await _storageService.clearHistory();
      _history.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear history: $e');
    }
  }

  /// Check backend health
  Future<bool> checkHealth() async {
    try {
      final health = await _apiService.healthCheck();
      return health['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }
}
