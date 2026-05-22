import '../models/handwritten_models.dart';

/// Simulates OCR processing and AI evaluation with realistic delay.
class MockOcrService {
  static Future<HandwrittenEvaluation> processHandwritten(
    HandwrittenUpload upload,
  ) async {
    // Simulate multi-stage processing
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await Future<void>.delayed(const Duration(milliseconds: 800));

    return HandwrittenEvaluation(
      id: 'eval_${upload.id}',
      uploadId: upload.id,
      overallScore: 68.0,
      grade: 'C+',
      feedback: const [
        HandwrittenFeedback(
          category: 'Legibility',
          score: 72.0,
          comment:
              'Your handwriting is mostly readable, but some letters blend together in longer words.',
          suggestions: [
            'Practice writing with more space between letters',
            'Use ruled paper to maintain consistent baseline',
            'Slow down while writing complex words',
          ],
        ),
        HandwrittenFeedback(
          category: 'Spelling',
          score: 65.0,
          comment:
              'Several spelling errors were detected, particularly in scientific terminology.',
          suggestions: [
            'Create flashcards for commonly misspelled terms',
            'Proofread your answers aloud before submitting',
            'Focus on root words and prefixes',
          ],
        ),
        HandwrittenFeedback(
          category: 'Grammar',
          score: 58.0,
          comment:
              'Sentence structure needs improvement. Run-on sentences and missing punctuation detected.',
          suggestions: [
            'Break long sentences into shorter ones',
            'Practice using commas and periods correctly',
            'Review subject-verb agreement rules',
          ],
        ),
        HandwrittenFeedback(
          category: 'Structure',
          score: 75.0,
          comment:
              'Good paragraph organization. Answers follow a logical flow with clear introductions.',
          suggestions: [
            'Add more transition words between paragraphs',
            'Use bullet points for listing multiple items',
            'Include a brief conclusion at the end',
          ],
        ),
        HandwrittenFeedback(
          category: 'Content',
          score: 70.0,
          comment:
              'Answers demonstrate understanding of core concepts but lack depth in explanations.',
          suggestions: [
            'Elaborate on "why" not just "what"',
            'Include real-world examples where possible',
            'Reference formulas and theorems explicitly',
          ],
        ),
      ],
      weakAreas: const [
        WeakArea(
          area: 'Scientific Terminology',
          description:
              'Frequent misspelling of key terms like "photosynthesis", "mitochondria", and "chlorophyll"',
          severity: 78.0,
        ),
        WeakArea(
          area: 'Sentence Construction',
          description:
              'Long run-on sentences make answers difficult to follow and grade accurately',
          severity: 65.0,
        ),
        WeakArea(
          area: 'Punctuation Usage',
          description:
              'Missing commas and periods affect readability and clarity of responses',
          severity: 55.0,
        ),
      ],
      aiComment:
          'Overall, this is a solid attempt that shows you understand the material. Your handwriting is legible enough for grading, but improving spacing between letters will help the OCR engine (and your teacher) read your work more accurately. Focus on spelling scientific terms correctly and breaking up long sentences. With consistent practice on these two areas, you could easily improve your score by 15-20 points.',
      evaluatedAt: DateTime.now(),
    );
  }
}
