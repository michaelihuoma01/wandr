// lib/services/photo_verification_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';
import 'package:crypto/crypto.dart';
import '../models/visit_models.dart';
import '../models/models.dart';

class PhotoVerificationService {
  static final PhotoVerificationService _instance = PhotoVerificationService._internal();
  factory PhotoVerificationService() => _instance;
  PhotoVerificationService._internal();

  // AI verification endpoint - replace with your actual endpoint
  static const String _aiEndpoint = 'YOUR_AI_VERIFICATION_ENDPOINT';
  static const String _apiKey = 'YOUR_API_KEY';

  Future<PhotoVerificationResult> verifyPhoto({
    required File photoFile,
    required PlaceDetails place,
    DateTime? captureTime,
  }) async {
    try {
      // Step 1: Basic photo analysis
      final basicAnalysis = await _analyzePhotoBasics(photoFile);
      if (!basicAnalysis.isValid) {
        return basicAnalysis;
      }

      // Step 2: EXIF data verification
      final exifAnalysis = await _verifyExifData(photoFile);
      
      // Step 3: AI-powered verification
      final aiAnalysis = await _performAIAnalysis(photoFile, place);

      // Step 4: Combine results
      return _combineAnalysisResults(basicAnalysis, exifAnalysis, aiAnalysis, place);
    } catch (e) {
      return PhotoVerificationResult(
        isValid: false,
        credibilityScore: 0.0,
        isRecent: false,
        isOriginal: false,
        isRelevant: false,
        suggestedTags: [],
        analysis: 'Error during verification',
        error: e.toString(),
      );
    }
  }

  Future<PhotoVerificationResult> _analyzePhotoBasics(File photoFile) async {
    try {
      // Check file size and format
      final fileSize = await photoFile.length();
      if (fileSize > 50 * 1024 * 1024) { // 50MB limit
        return PhotoVerificationResult(
          isValid: false,
          credibilityScore: 0.0,
          isRecent: false,
          isOriginal: false,
          isRelevant: false,
          suggestedTags: [],
          analysis: 'File too large',
          error: 'Photo exceeds size limit',
        );
      }

      // Check if it's actually an image
      final bytes = await photoFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return PhotoVerificationResult(
          isValid: false,
          credibilityScore: 0.0,
          isRecent: false,
          isOriginal: false,
          isRelevant: false,
          suggestedTags: [],
          analysis: 'Invalid image format',
          error: 'File is not a valid image',
        );
      }

      // Check for screenshot indicators (uniform dimensions, UI elements)
      final isLikelyScreenshot = _detectScreenshot(image);

      return PhotoVerificationResult(
        isValid: !isLikelyScreenshot,
        credibilityScore: isLikelyScreenshot ? 0.1 : 0.8,
        isRecent: true, // Will be verified in EXIF
        isOriginal: !isLikelyScreenshot,
        isRelevant: true, // Will be verified by AI
        suggestedTags: [],
        analysis: isLikelyScreenshot ? 'Possible screenshot detected' : 'Basic validation passed',
      );
    } catch (e) {
      return PhotoVerificationResult(
        isValid: false,
        credibilityScore: 0.0,
        isRecent: false,
        isOriginal: false,
        isRelevant: false,
        suggestedTags: [],
        analysis: 'Basic analysis failed',
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> _verifyExifData(File photoFile) async {
    try {
      final bytes = await photoFile.readAsBytes();
      final exifData = await readExifFromBytes(bytes);
      
      DateTime? dateTaken;
      bool hasGpsData = false;
      
      if (exifData.isNotEmpty) {
        // Check for date taken
        final dateTimeOriginal = exifData['EXIF DateTimeOriginal']?.toString();
        final dateTime = exifData['Image DateTime']?.toString();
        
        if (dateTimeOriginal != null) {
          dateTaken = _parseExifDate(dateTimeOriginal);
        } else if (dateTime != null) {
          dateTaken = _parseExifDate(dateTime);
        }

        // Check for GPS data (indicates camera location)
        hasGpsData = exifData.containsKey('GPS GPSLatitude') && 
                    exifData.containsKey('GPS GPSLongitude');
      }

      final now = DateTime.now();
      final isRecent = dateTaken != null && 
                      now.difference(dateTaken).inHours <= 24;

      return {
        'isRecent': isRecent,
        'dateTaken': dateTaken,
        'hasGpsData': hasGpsData,
        'hasExifData': exifData.isNotEmpty,
      };
    } catch (e) {
      return {
        'isRecent': false,
        'dateTaken': null,
        'hasGpsData': false,
        'hasExifData': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _performAIAnalysis(File photoFile, PlaceDetails place) async {
    try {
      // Encode image to base64
      final bytes = await photoFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare the prompt for AI analysis
      final prompt = _buildAnalysisPrompt(place);

      // Call AI service (using a generic HTTP client - replace with your AI service)
      final response = await http.post(
        Uri.parse(_aiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'vision-model',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _parseAIResponse(responseData);
      } else {
        return {
          'isRelevant': false,
          'credibilityScore': 0.0,
          'suggestedTags': <String>[],
          'analysis': 'AI service unavailable',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      // Fallback analysis without AI
      return {
        'isRelevant': true, // Assume relevant if AI fails
        'credibilityScore': 0.5,
        'suggestedTags': _getFallbackTags(place),
        'analysis': 'AI analysis failed, using fallback',
        'error': e.toString(),
      };
    }
  }

  String _buildAnalysisPrompt(PlaceDetails place) {
    return '''
Analyze this photo for a check-in at "${place.name}" (${place.type}).

Please provide a JSON response with:
1. "isRelevant": boolean - Does this photo look like it was taken at this type of venue?
2. "credibilityScore": number (0-1) - How authentic does this photo appear?
3. "suggestedTags": array - What vibe tags best describe this photo? Choose from: romantic, fun, relaxing, exciting, cozy, lively, intimate, energetic, trendy, hipster, family_friendly, professional, aesthetic, rustic, modern, vintage
4. "analysis": string - Brief explanation of your assessment
5. "concerns": array - Any red flags (e.g., "looks like stock photo", "no people visible", "indoor photo for outdoor venue")

Consider:
- Does the photo match the venue type and atmosphere?
- Does it look authentic vs. stock/staged?
- Are there contextual elements that support the location claim?
- What vibes/mood does the photo convey?
''';
  }

  Map<String, dynamic> _parseAIResponse(Map<String, dynamic> responseData) {
    try {
      // Extract the AI response text and parse as JSON
      final content = responseData['choices']?[0]?['message']?['content'];
      if (content == null) {
        throw Exception('No content in AI response');
      }

      final aiAnalysis = jsonDecode(content);
      
      return {
        'isRelevant': aiAnalysis['isRelevant'] ?? false,
        'credibilityScore': (aiAnalysis['credibilityScore'] ?? 0.0).toDouble(),
        'suggestedTags': List<String>.from(aiAnalysis['suggestedTags'] ?? []),
        'analysis': aiAnalysis['analysis'] ?? 'No analysis provided',
        'concerns': List<String>.from(aiAnalysis['concerns'] ?? []),
      };
    } catch (e) {
      return {
        'isRelevant': false,
        'credibilityScore': 0.0,
        'suggestedTags': <String>[],
        'analysis': 'Failed to parse AI response',
        'error': e.toString(),
      };
    }
  }

  PhotoVerificationResult _combineAnalysisResults(
    PhotoVerificationResult basic,
    Map<String, dynamic> exif,
    Map<String, dynamic> ai,
    PlaceDetails place,
  ) {
    // Calculate overall credibility score
    double overallScore = 0.0;
    
    // Basic analysis weight (30%)
    overallScore += basic.credibilityScore * 0.3;
    
    // EXIF data weight (20%)
    double exifScore = 0.0;
    if (exif['isRecent'] == true) exifScore += 0.4;
    if (exif['hasExifData'] == true) exifScore += 0.3;
    if (exif['hasGpsData'] == true) exifScore += 0.3;
    overallScore += exifScore * 0.2;
    
    // AI analysis weight (50%)
    overallScore += (ai['credibilityScore'] ?? 0.0) * 0.5;

    // Determine if photo is valid (threshold: 0.6)
    final isValid = overallScore >= 0.6 && 
                   basic.isValid && 
                   (ai['isRelevant'] ?? false);

    // Combine suggested tags
    final suggestedTags = <String>[];
    suggestedTags.addAll(ai['suggestedTags'] ?? []);
    
    // Add contextual tags based on place type
    suggestedTags.addAll(_getContextualTags(place, overallScore));

    // Build analysis summary
    final analysisPoints = <String>[];
    analysisPoints.add('Basic validation: ${basic.analysis}');
    if (exif['isRecent'] == true) {
      analysisPoints.add('✓ Photo taken within 24 hours');
    } else {
      analysisPoints.add('⚠ Unable to verify photo recency');
    }
    if (exif['hasExifData'] == true) {
      analysisPoints.add('✓ Original photo with metadata');
    }
    analysisPoints.add('AI Analysis: ${ai['analysis']}');
    
    if (ai['concerns'] != null && (ai['concerns'] as List).isNotEmpty) {
      analysisPoints.add('Concerns: ${(ai['concerns'] as List).join(', ')}');
    }

    return PhotoVerificationResult(
      isValid: isValid,
      credibilityScore: overallScore,
      isRecent: exif['isRecent'] ?? false,
      isOriginal: basic.isOriginal && (exif['hasExifData'] ?? false),
      isRelevant: ai['isRelevant'] ?? false,
      suggestedTags: suggestedTags.take(5).toList(), // Limit to top 5
      analysis: analysisPoints.join('\n'),
    );
  }

  bool _detectScreenshot(img.Image image) {
    // Simple heuristics to detect screenshots
    final width = image.width;
    final height = image.height;
    
    // Common phone screen ratios
    final commonRatios = [16/9, 18/9, 19.5/9, 20/9];
    final imageRatio = width / height;
    
    for (final ratio in commonRatios) {
      if ((imageRatio - ratio).abs() < 0.1) {
        // Additional checks could include:
        // - Looking for UI elements at edges
        // - Checking for uniform colors at borders
        // - Analyzing pixel patterns typical of screens
        return true;
      }
    }
    
    return false;
  }

  DateTime? _parseExifDate(String exifDate) {
    try {
      // EXIF date format: "YYYY:MM:DD HH:MM:SS"
      final cleanDate = exifDate.replaceRange(0, 10, exifDate.substring(0, 10).replaceAll(':', '-'));
      return DateTime.parse(cleanDate);
    } catch (e) {
      return null;
    }
  }

  List<String> _getFallbackTags(PlaceDetails place) {
    final type = place.type.toLowerCase();
    
    if (type.contains('restaurant')) {
      return ['aesthetic', 'fun'];
    } else if (type.contains('cafe') || type.contains('coffee')) {
      return ['cozy', 'relaxing'];
    } else if (type.contains('bar') || type.contains('club')) {
      return ['lively', 'energetic'];
    } else if (type.contains('hotel') || type.contains('lounge')) {
      return ['intimate', 'aesthetic'];
    }
    
    return ['trendy'];
  }

  List<String> _getContextualTags(PlaceDetails place, double credibilityScore) {
    final tags = <String>[];
    
    // Add tags based on credibility score
    if (credibilityScore > 0.8) {
      tags.add('authentic');
    }
    
    // Add tags based on place rating
    if (place.rating != null && place.rating! > 4.0) {
      tags.add('aesthetic');
    }
    
    return tags;
  }

  // Calculate credibility points based on verification result
  int calculateCredibilityPoints(PhotoVerificationResult result) {
    if (!result.isValid) return 0;
    
    int points = 0;
    
    // Base points for verified photo
    points += 10;
    
    // Bonus for high credibility score
    if (result.credibilityScore > 0.8) {
      points += 15;
    } else if (result.credibilityScore > 0.6) {
      points += 10;
    }
    
    // Bonus for recent photo
    if (result.isRecent) {
      points += 5;
    }
    
    // Bonus for original photo
    if (result.isOriginal) {
      points += 5;
    }
    
    // Bonus for relevant photo
    if (result.isRelevant) {
      points += 10;
    }
    
    return points;
  }
}