import 'dart:math';


import '../models/exam_config_model.dart';
import '../models/exam_enums.dart';
import '../models/exam_question_model.dart';
import '../models/exam_result_model.dart';
import '../models/exam_session_model.dart';

/// Generates mock exams and grades them locally.
class MockExamService {
  final _random = Random();

  /// Generates an exam session based on the given config.
  Future<ExamSession> generateExam(ExamConfig config) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final questions = _buildQuestionsForConfig(config);
    final examId = 'exam_${DateTime.now().millisecondsSinceEpoch}';

    return ExamSession(
      examId: examId,
      config: config,
      questions: questions,
      startTime: DateTime.now(),
      timeRemainingSeconds: config.timeLimitMinutes * 60,
    );
  }

  /// Submits an exam session and returns graded results.
  Future<ExamResult> submitExam(ExamSession session) async {
    await Future.delayed(const Duration(milliseconds: 600));

    int mcqCorrect = 0;
    int mcqTotal = 0;
    double obtainedMarks = 0;
    final shortAnswerFeedback = <ShortAnswerFeedback>[];
    final topicScores = <String, List<double>>{};

    for (final question in session.questions) {
      final answer = session.getAnswerFor(question.id);
      final userAnswer = answer?.answer ?? '';

      if (question.isMcq) {
        mcqTotal++;
        final isCorrect = userAnswer.trim() == question.correctAnswer?.trim();
        if (isCorrect) {
          mcqCorrect++;
          obtainedMarks += question.marks;
        }
        topicScores.putIfAbsent(question.topic, () => []);
        topicScores[question.topic]!.add(isCorrect ? 1.0 : 0.0);
      } else if (question.isShortAnswer) {
        // Simulate partial grading for short answers
        final similarity = _calculateSimilarity(
          userAnswer.toLowerCase(),
          (question.correctAnswer ?? '').toLowerCase(),
        );
        final awarded = question.marks * similarity;
        obtainedMarks += awarded;
        shortAnswerFeedback.add(
          ShortAnswerFeedback(
            questionId: question.id,
            status: similarity >= 0.7
                ? 'correct'
                : similarity >= 0.4
                    ? 'partial'
                    : 'incorrect',
            feedback: similarity >= 0.7
                ? 'Excellent answer! Well explained.'
                : similarity >= 0.4
                    ? 'Good attempt, but some key points are missing.'
                    : 'Incorrect. Review the concept and try again.',
            awardedMarks: awarded,
          ),
        );
        topicScores.putIfAbsent(question.topic, () => []);
        topicScores[question.topic]!.add(similarity);
      } else if (question.isCq) {
        // CQ: award partial marks based on answer length as a heuristic
        final lengthScore = userAnswer.length > 50
            ? 0.6 + (_random.nextDouble() * 0.3)
            : userAnswer.length > 20
                ? 0.3 + (_random.nextDouble() * 0.3)
                : _random.nextDouble() * 0.3;
        final awarded = question.marks * lengthScore.clamp(0.0, 1.0);
        obtainedMarks += awarded;
        topicScores.putIfAbsent(question.topic, () => []);
        topicScores[question.topic]!.add(lengthScore.clamp(0.0, 1.0));
      }
    }

    final totalMarks = session.totalMarks;
    final scorePercentage = totalMarks > 0
        ? ((obtainedMarks / totalMarks) * 100).clamp(0.0, 100.0)
        : 0.0;

    // Detect weak topics
    final weakTopics = <WeakTopic>[];
    topicScores.forEach((topic, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg < 0.6) {
        weakTopics.add(
          WeakTopic(
            topic: topic,
            reason: avg < 0.4
                ? 'Fundamental concepts need review'
                : 'Practice more problems on this topic',
            score: (avg * 100).roundToDouble(),
          ),
        );
      }
    });

    // Readiness score: 60% exam score + 40% consistency
    final consistency = topicScores.values
            .map((s) => s.reduce((a, b) => a + b) / s.length)
            .fold<double>(0, (a, b) => a + b) /
        topicScores.length;
    final readinessScore =
        ((0.6 * scorePercentage) + (0.4 * consistency * 100))
            .clamp(0.0, 100.0);

    final timeTaken = session.config.timeLimitMinutes * 60 -
        session.timeRemainingSeconds;

    return ExamResult(
      attemptId: 'attempt_${DateTime.now().millisecondsSinceEpoch}',
      examId: session.examId,
      studentId: 1,
      scorePercentage: scorePercentage,
      totalMarks: totalMarks,
      obtainedMarks: obtainedMarks,
      mcqCorrect: mcqCorrect,
      mcqTotal: mcqTotal,
      shortAnswerFeedback: shortAnswerFeedback,
      weakTopics: weakTopics,
      readinessScore: readinessScore,
      timeTakenSeconds: timeTaken,
      submittedAt: DateTime.now(),
      subject: session.config.subject,
      topic: session.config.topic,
      difficulty: session.config.difficulty.label,
    );
  }

  List<ExamQuestion> _buildQuestionsForConfig(ExamConfig config) {
    if (config.examType == ExamType.ssc) {
      return _buildSscExam(config);
    }
    if (config.examType == ExamType.hsc) {
      return _buildHscExam(config);
    }
    return _buildPracticeExam(config);
  }

  List<ExamQuestion> _buildPracticeExam(ExamConfig config) {
    final pool = _getQuestionPoolForSubject(config.subject);
    final filtered = pool.where((q) {
      // Adaptive difficulty filtering
      if (config.difficulty == ExamDifficulty.easy) {
        return q.difficulty != ExamDifficulty.hard;
      }
      if (config.difficulty == ExamDifficulty.hard) {
        return q.difficulty != ExamDifficulty.easy;
      }
      return true;
    }).toList();

    filtered.shuffle(_random);

    final count = config.numQuestions.clamp(1, filtered.length);
    return filtered.take(count).toList();
  }

  List<ExamQuestion> _buildSscExam(ExamConfig config) {
    final pool = _getQuestionPoolForSubject(config.subject);
    final mcqs = pool.where((q) => q.isMcq).toList()..shuffle(_random);
    final shorts = pool.where((q) => q.isShortAnswer).toList()..shuffle(_random);
    final cqs = pool.where((q) => q.isCq).toList()..shuffle(_random);

    return [
      ...mcqs.take(30),
      ...cqs.take(5).map((q) => q.copyWith(marks: 10)),
      ...shorts.take(3).map((q) => q.copyWith(marks: 5)),
    ];
  }

  List<ExamQuestion> _buildHscExam(ExamConfig config) {
    // Same structure as SSC but with higher complexity
    final pool = _getQuestionPoolForSubject(config.subject);
    final mcqs = pool.where((q) => q.isMcq).toList()..shuffle(_random);
    final shorts = pool.where((q) => q.isShortAnswer).toList()..shuffle(_random);
    final cqs = pool.where((q) => q.isCq).toList()..shuffle(_random);

    return [
      ...mcqs.take(30),
      ...cqs.take(5).map((q) => q.copyWith(marks: 10)),
      ...shorts.take(3).map((q) => q.copyWith(marks: 5)),
    ];
  }

  List<ExamQuestion> _getQuestionPoolForSubject(String subject) {
    final lower = subject.toLowerCase();
    if (lower.contains('physics') || lower.contains('physics')) {
      return _physicsQuestions;
    }
    if (lower.contains('chemistry') || lower.contains('chemistry')) {
      return _chemistryQuestions;
    }
    if (lower.contains('biology') || lower.contains('biology')) {
      return _biologyQuestions;
    }
    return _scienceQuestions; // default
  }

  /// Simple string similarity for mock grading.
  double _calculateSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 1.0;
    final aWords = a.split(' ').toSet();
    final bWords = b.split(' ').toSet();
    final intersection = aWords.intersection(bWords).length;
    final union = aWords.union(bWords).length;
    return union == 0 ? 0.0 : intersection / union;
  }

  // --------------------------------------------------------------------------
  // Mock Question Banks
  // --------------------------------------------------------------------------

  late final List<ExamQuestion> _scienceQuestions = [
    // MCQ - Easy
    const ExamQuestion(
      id: 's1',
      type: QuestionType.mcq,
      topic: 'Cell Biology',
      prompt: 'কোষের শক্তি উৎপাদনকারী অঙ্গাণুর নাম কী?\nWhat is the name of the organelle that produces energy in a cell?',
      options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi body'],
      marks: 1,
      correctAnswer: 'Mitochondria',
      explanation: 'Mitochondria are known as the powerhouse of the cell because they generate ATP through cellular respiration.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 's2',
      type: QuestionType.mcq,
      topic: 'Photosynthesis',
      prompt: 'সবুজ উদ্ভিদ কোন গ্যাস শোষণ করে?\nWhich gas do green plants absorb?',
      options: ['Oxygen', 'Carbon dioxide', 'Nitrogen', 'Hydrogen'],
      marks: 1,
      correctAnswer: 'Carbon dioxide',
      explanation: 'Plants absorb CO₂ from the air during photosynthesis to produce glucose and oxygen.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 's3',
      type: QuestionType.mcq,
      topic: 'States of Matter',
      prompt: 'পানির স্ফুটনাঙ্ক কত ডিগ্রি সেলসিয়াস?\nWhat is the boiling point of water in °C?',
      options: ['90°C', '100°C', '110°C', '120°C'],
      marks: 1,
      correctAnswer: '100°C',
      explanation: 'At standard atmospheric pressure, water boils at 100°C.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 's4',
      type: QuestionType.mcq,
      topic: 'Human Body',
      prompt: 'মানবদেহের বৃহত্তম অঙ্গ কোনটি?\nWhat is the largest organ of the human body?',
      options: ['Liver', 'Brain', 'Skin', 'Heart'],
      marks: 1,
      correctAnswer: 'Skin',
      explanation: 'The skin is the largest organ, covering the entire body and protecting it from external threats.',
      difficulty: ExamDifficulty.easy,
    ),
    // MCQ - Medium
    const ExamQuestion(
      id: 's5',
      type: QuestionType.mcq,
      topic: 'Acids and Bases',
      prompt: 'pH স্কেলে কোন মান নিরপেক্ষ বলে বিবেচিত হয়?\nWhich value on the pH scale is considered neutral?',
      options: ['0', '7', '14', '10'],
      marks: 1,
      correctAnswer: '7',
      explanation: 'A pH of 7 is neutral. Values below 7 are acidic and above 7 are basic.',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 's6',
      type: QuestionType.mcq,
      topic: 'Force and Motion',
      prompt: 'নিউটনের দ্বিতীয় সূত্র অনুযায়ী, বল = ?\nAccording to Newton\'s second law, Force = ?',
      options: ['mass × velocity', 'mass × acceleration', 'velocity × time', 'mass × time'],
      marks: 1,
      correctAnswer: 'mass × acceleration',
      explanation: 'Newton\'s second law states F = ma, where F is force, m is mass, and a is acceleration.',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 's7',
      type: QuestionType.mcq,
      topic: 'Electricity',
      prompt: 'বিদ্যুৎ প্রবাহের একক কী?\nWhat is the SI unit of electric current?',
      options: ['Volt', 'Ohm', 'Ampere', 'Watt'],
      marks: 1,
      correctAnswer: 'Ampere',
      explanation: 'The ampere (A) is the SI base unit of electric current.',
      difficulty: ExamDifficulty.medium,
    ),
    // MCQ - Hard
    const ExamQuestion(
      id: 's8',
      type: QuestionType.mcq,
      topic: 'Chemical Reactions',
      prompt: 'H₂ + O₂ → ?\nWhat is the balanced product?',
      options: ['H₂O₂', 'H₂O', 'HO', 'OH'],
      marks: 1,
      correctAnswer: 'H₂O',
      explanation: 'Hydrogen and oxygen combine to form water: 2H₂ + O₂ → 2H₂O.',
      difficulty: ExamDifficulty.hard,
    ),
    // Short Answer
    const ExamQuestion(
      id: 's9',
      type: QuestionType.shortAnswer,
      topic: 'Photosynthesis',
      prompt: 'সংশ্লেষণ প্রক্রিয়ার সমীকরণটি লিখুন।\nWrite the equation for photosynthesis.',
      marks: 2,
      correctAnswer: '6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂',
      explanation: 'Plants use carbon dioxide and water in the presence of sunlight to produce glucose and oxygen.',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 's10',
      type: QuestionType.shortAnswer,
      topic: 'Human Body',
      prompt: 'হৃৎপিণ্ডের চারটি কক্ষের নাম লিখুন।\nName the four chambers of the heart.',
      marks: 2,
      correctAnswer: 'Right atrium, right ventricle, left atrium, left ventricle',
      explanation: 'The heart has four chambers: two atria (upper) and two ventricles (lower).',
      difficulty: ExamDifficulty.medium,
    ),
    // CQ
    const ExamQuestion(
      id: 's11',
      type: QuestionType.cq,
      topic: 'Ecosystem',
      prompt: 'পরিবেশ ব্যবস্থার ভারসাম্য রক্ষায় প্রযুক্তির ভূমিকা সম্পর্কে একটি সৃজনশীল প্রশ্নের উত্তর দিন।\nAnswer the following creative question on the role of technology in maintaining ecological balance.',
      marks: 10,
      correctAnswer: '',
      explanation: 'CQ answers require detailed explanations covering multiple aspects of the topic.',
      difficulty: ExamDifficulty.medium,
      subParts: ['(a) Define ecosystem and give two examples.', '(b) Explain how technology helps monitor environmental changes.', '(c) Discuss renewable energy sources and their impact.'],
    ),
    const ExamQuestion(
      id: 's12',
      type: QuestionType.cq,
      topic: 'Force and Motion',
      prompt: 'বল ও গতি সম্পর্কিত একটি সৃজনশীল প্রশ্নের উত্তর দিন।\nAnswer the creative question on Force and Motion.',
      marks: 10,
      correctAnswer: '',
      explanation: 'CQs test comprehensive understanding through structured sub-questions.',
      difficulty: ExamDifficulty.hard,
      subParts: ['(a) State Newton\'s three laws of motion.', '(b) Derive F = ma from the second law.', '(c) Give two real-life applications.'],
    ),
    // More MCQs
    const ExamQuestion(
      id: 's13',
      type: QuestionType.mcq,
      topic: 'Sound',
      prompt: 'শব্দের গতি বাতাসে প্রায় কত?\nWhat is the approximate speed of sound in air?',
      options: ['330 m/s', '3000 m/s', '30 m/s', '300 m/s'],
      marks: 1,
      correctAnswer: '330 m/s',
      explanation: 'The speed of sound in air at 20°C is approximately 343 m/s, often rounded to 330 m/s.',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 's14',
      type: QuestionType.mcq,
      topic: 'Microorganisms',
      prompt: 'অ্যামিবার কোষে কোনটি থাকে না?\nWhich of the following is NOT present in an amoeba cell?',
      options: ['Nucleus', 'Cytoplasm', 'Cell wall', 'Pseudopodia'],
      marks: 1,
      correctAnswer: 'Cell wall',
      explanation: 'Amoeba is a protozoan and lacks a cell wall; it uses pseudopodia for movement.',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 's15',
      type: QuestionType.shortAnswer,
      topic: 'Reproduction',
      prompt: 'যৌন প্রজনন ও অযৌন প্রজননের মধ্যে দুটি পার্থক্য লিখুন।\nWrite two differences between sexual and asexual reproduction.',
      marks: 2,
      correctAnswer: 'Sexual involves two parents and genetic variation; asexual involves one parent and no variation',
      explanation: 'Sexual reproduction produces genetically diverse offspring, while asexual produces clones.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 's16',
      type: QuestionType.mcq,
      topic: 'Light',
      prompt: 'আলোর বিক্ষেপণ কোন মাধ্যমে ঘটে?\nIn which medium does light scattering occur?',
      options: ['Vacuum', 'Transparent medium', 'Colloid', 'All of the above'],
      marks: 1,
      correctAnswer: 'Colloid',
      explanation: 'Scattering of light is most prominent in colloidal solutions where particles are small but larger than molecules.',
      difficulty: ExamDifficulty.hard,
    ),
    const ExamQuestion(
      id: 's17',
      type: QuestionType.shortAnswer,
      topic: 'Metals',
      prompt: 'ধাতু ও অধাতুর মধ্যে তিনটি পার্থক্য লিখুন।\nWrite three differences between metals and non-metals.',
      marks: 3,
      correctAnswer: 'Metals are shiny, good conductors, malleable; non-metals are dull, poor conductors, brittle',
      explanation: 'Metals typically have high electrical/thermal conductivity, luster, and malleability.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 's18',
      type: QuestionType.cq,
      topic: 'Weather',
      prompt: 'আবহাওয়া ও জলবায়ুর পার্থক্য এবং প্রভাব নিয়ে সৃজনশীল উত্তর দিন।\nWrite a creative answer on weather vs climate and their effects.',
      marks: 10,
      correctAnswer: '',
      explanation: 'Weather refers to short-term atmospheric conditions; climate is the long-term pattern.',
      difficulty: ExamDifficulty.medium,
      subParts: ['(a) Define weather and climate.', '(b) List factors affecting climate.', '(c) Explain the greenhouse effect.'],
    ),
    const ExamQuestion(
      id: 's19',
      type: QuestionType.mcq,
      topic: 'Nutrition',
      prompt: 'ভিটামিন C এর অভাবে কোন রোগ হয়?\nWhich disease is caused by vitamin C deficiency?',
      options: ['Rickets', 'Scurvy', 'Night blindness', 'Beriberi'],
      marks: 1,
      correctAnswer: 'Scurvy',
      explanation: 'Scurvy is caused by a deficiency of vitamin C (ascorbic acid), leading to bleeding gums and weakness.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 's20',
      type: QuestionType.mcq,
      topic: 'Magnetism',
      prompt: 'চৌম্বকের সবচেয়ে শক্তিশালী অংশ কোনটি?\nWhich part of a magnet is the strongest?',
      options: ['Center', 'Poles', 'Middle', 'Sides'],
      marks: 1,
      correctAnswer: 'Poles',
      explanation: 'The magnetic poles (north and south) are the strongest regions of a magnet.',
      difficulty: ExamDifficulty.easy,
    ),
  ];

  late final List<ExamQuestion> _physicsQuestions = [
    const ExamQuestion(
      id: 'p1',
      type: QuestionType.mcq,
      topic: 'Kinematics',
      prompt: 'একটি বস্তু 5 m/s বেগে চলছে। 2 সেকেন্ডে এর গতিবেগ 15 m/s হলে ত্বরণ কত?\nAn object moving at 5 m/s reaches 15 m/s in 2 s. What is its acceleration?',
      options: ['5 m/s²', '10 m/s²', '7.5 m/s²', '20 m/s²'],
      marks: 1,
      correctAnswer: '5 m/s²',
      explanation: 'a = (v - u) / t = (15 - 5) / 2 = 5 m/s².',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 'p2',
      type: QuestionType.mcq,
      topic: 'Newton\'s Laws',
      prompt: 'বলের একক কী?\nWhat is the SI unit of force?',
      options: ['Joule', 'Watt', 'Newton', 'Pascal'],
      marks: 1,
      correctAnswer: 'Newton',
      explanation: 'The newton (N) is the SI unit of force, defined as kg·m/s².',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 'p3',
      type: QuestionType.mcq,
      topic: 'Work and Energy',
      prompt: '10 N বলে 5 m দূরত্বে কাজের পরিমাণ কত?\nWhat is the work done by a 10 N force over 5 m?',
      options: ['2 J', '50 J', '15 J', '5 J'],
      marks: 1,
      correctAnswer: '50 J',
      explanation: 'Work = Force × Displacement = 10 N × 5 m = 50 J.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 'p4',
      type: QuestionType.mcq,
      topic: 'Gravitation',
      prompt: 'পৃথিবীর অভিকর্ষজ ত্বরণের মান কত?\nWhat is the value of gravitational acceleration on Earth?',
      options: ['8.9 m/s²', '9.8 m/s²', '10 m/s²', '9.2 m/s²'],
      marks: 1,
      correctAnswer: '9.8 m/s²',
      explanation: 'Standard gravitational acceleration g ≈ 9.8 m/s² (often approximated as 10 m/s²).',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 'p5',
      type: QuestionType.mcq,
      topic: 'Optics',
      prompt: 'আলোর বেগ কোন মাধ্যমে সবচেয়ে বেশি?\nIn which medium does light travel fastest?',
      options: ['Water', 'Glass', 'Air', 'Vacuum'],
      marks: 1,
      correctAnswer: 'Vacuum',
      explanation: 'Light travels fastest in a vacuum at approximately 3 × 10⁸ m/s.',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 'p6',
      type: QuestionType.mcq,
      topic: 'Thermodynamics',
      prompt: 'কেলভিন তাপমাত্রার একক। 27°C = ? K\nWhat is 27°C in Kelvin?',
      options: ['300 K', '273 K', '250 K', '320 K'],
      marks: 1,
      correctAnswer: '300 K',
      explanation: 'K = °C + 273.15, so 27°C ≈ 300 K.',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 'p7',
      type: QuestionType.shortAnswer,
      topic: 'Waves',
      prompt: 'তরঙ্গের বেগ, কম্পাঙ্ক ও তরঙ্গদৈর্ঘ্যের মধ্যে সম্পর্ক লিখুন।\nWrite the relation between wave velocity, frequency, and wavelength.',
      marks: 2,
      correctAnswer: 'v = fλ',
      explanation: 'Wave velocity (v) equals frequency (f) multiplied by wavelength (λ).',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 'p8',
      type: QuestionType.shortAnswer,
      topic: 'Electricity',
      prompt: 'ওহমের সূত্রটি লিখুন এবং প্রতিটি চলকের একক উল্লেখ করুন।\nState Ohm\'s law and mention the units of each variable.',
      marks: 3,
      correctAnswer: 'V = IR; V in Volts, I in Amperes, R in Ohms',
      explanation: 'Ohm\'s law states that voltage equals current times resistance.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 'p9',
      type: QuestionType.cq,
      topic: 'Motion',
      prompt: 'গতির সরলরেখায় বিবরণ দিন।\nDescribe motion in a straight line.',
      marks: 10,
      correctAnswer: '',
      explanation: 'Covers position, displacement, velocity, acceleration, and equations of motion.',
      difficulty: ExamDifficulty.medium,
      subParts: ['(a) Define displacement and distance.', '(b) Derive the three equations of motion.', '(c) Plot velocity-time graph for uniform acceleration.'],
    ),
    const ExamQuestion(
      id: 'p10',
      type: QuestionType.cq,
      topic: 'Energy',
      prompt: 'শক্তির রূপান্তর ও সংরক্ষণ নিয়ে আলোচনা করুন।\nDiscuss energy transformation and conservation.',
      marks: 10,
      correctAnswer: '',
      explanation: 'Energy cannot be created or destroyed, only transformed from one form to another.',
      difficulty: ExamDifficulty.hard,
      subParts: ['(a) State the law of conservation of energy.', '(b) Give examples of energy transformation.', '(c) Calculate potential and kinetic energy for a falling object.'],
    ),
    const ExamQuestion(
      id: 'p11',
      type: QuestionType.mcq,
      topic: 'Rotational Motion',
      prompt: 'কোণীয় ত্বরণের একক কী?\nWhat is the unit of angular acceleration?',
      options: ['rad/s', 'rad/s²', 'm/s²', 'N·m'],
      marks: 1,
      correctAnswer: 'rad/s²',
      explanation: 'Angular acceleration is measured in radians per second squared (rad/s²).',
      difficulty: ExamDifficulty.hard,
    ),
    const ExamQuestion(
      id: 'p12',
      type: QuestionType.mcq,
      topic: 'Electromagnetism',
      prompt: 'ফ্যারাডের বিদ্যুৎচৌম্বকীয় আবেশ সূত্রটি প্রযোজ্য কোন ক্ষেত্রে?\nFaraday\'s law of electromagnetic induction applies when:',
      options: ['Current is constant', 'Magnetic flux changes', 'Voltage is zero', 'Resistance is infinite'],
      marks: 1,
      correctAnswer: 'Magnetic flux changes',
      explanation: 'Faraday\'s law states that an EMF is induced when the magnetic flux through a circuit changes.',
      difficulty: ExamDifficulty.hard,
    ),
  ];

  late final List<ExamQuestion> _chemistryQuestions = [
    const ExamQuestion(
      id: 'c1',
      type: QuestionType.mcq,
      topic: 'Periodic Table',
      prompt: 'পর্যায় সারণির প্রথম ধাতু কোনটি?\nWhich is the first element in the periodic table?',
      options: ['Helium', 'Lithium', 'Hydrogen', 'Carbon'],
      marks: 1,
      correctAnswer: 'Hydrogen',
      explanation: 'Hydrogen (H) is the lightest and first element in the periodic table with atomic number 1.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 'c2',
      type: QuestionType.mcq,
      topic: 'Chemical Bonding',
      prompt: 'NaCl-এ কোন ধরনের বন্ধন থাকে?\nWhat type of bond exists in NaCl?',
      options: ['Covalent', 'Ionic', 'Metallic', 'Hydrogen'],
      marks: 1,
      correctAnswer: 'Ionic',
      explanation: 'Sodium chloride has an ionic bond formed by the transfer of an electron from Na to Cl.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 'c3',
      type: QuestionType.mcq,
      topic: 'Acids and Bases',
      prompt: 'HCl + NaOH → ?\nWhat is the product of this neutralization reaction?',
      options: ['NaCl + H₂O', 'NaCl + H₂', 'NaOH + Cl₂', 'Na + HClO'],
      marks: 1,
      correctAnswer: 'NaCl + H₂O',
      explanation: 'HCl (acid) reacts with NaOH (base) to form NaCl (salt) and H₂O (water).',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 'c4',
      type: QuestionType.mcq,
      topic: 'Organic Chemistry',
      prompt: 'মিথেনের রাসায়নিক সংকেত কী?\nWhat is the chemical formula of methane?',
      options: ['C₂H₆', 'CH₄', 'C₂H₄', 'CO₂'],
      marks: 1,
      correctAnswer: 'CH₄',
      explanation: 'Methane is the simplest hydrocarbon with the formula CH₄.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 'c5',
      type: QuestionType.shortAnswer,
      topic: 'Mole Concept',
      prompt: 'মোল সংক্রান্ত সূত্রটি লিখুন।\nWrite the formula relating mole, mass, and molar mass.',
      marks: 2,
      correctAnswer: 'n = m / M',
      explanation: 'Number of moles (n) = given mass (m) / molar mass (M).',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 'c6',
      type: QuestionType.cq,
      topic: 'Electrochemistry',
      prompt: 'তড়িৎরসায়নের মৌলিক ধারণা ব্যাখ্যা করুন।\nExplain the basic concepts of electrochemistry.',
      marks: 10,
      correctAnswer: '',
      explanation: 'Electrochemistry deals with the interconversion of electrical and chemical energy.',
      difficulty: ExamDifficulty.hard,
      subParts: ['(a) Define oxidation and reduction.', '(b) Explain electrolysis of water.', '(c) Write cell notation for a galvanic cell.'],
    ),
    const ExamQuestion(
      id: 'c7',
      type: QuestionType.mcq,
      topic: 'Atomic Structure',
      prompt: 'ইলেকট্রনের আবিষ্কারক কে?\nWho discovered the electron?',
      options: ['Rutherford', 'Thomson', 'Bohr', 'Chadwick'],
      marks: 1,
      correctAnswer: 'Thomson',
      explanation: 'J.J. Thomson discovered the electron in 1897 through cathode ray experiments.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 'c8',
      type: QuestionType.mcq,
      topic: 'Chemical Equilibrium',
      prompt: 'সাম্যাবস্থায় বিক্রিয়ার হারের সম্পর্ক কী?\nAt equilibrium, the rates of forward and reverse reactions are:',
      options: ['Zero', 'Equal', 'Different', 'Maximum'],
      marks: 1,
      correctAnswer: 'Equal',
      explanation: 'At chemical equilibrium, the forward and reverse reaction rates become equal.',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 'c9',
      type: QuestionType.shortAnswer,
      topic: 'Gases',
      prompt: 'আদর্শ গ্যাসের সমীকরণটি লিখুন।\nWrite the ideal gas equation.',
      marks: 2,
      correctAnswer: 'PV = nRT',
      explanation: 'P = pressure, V = volume, n = moles, R = gas constant, T = temperature.',
      difficulty: ExamDifficulty.medium,
    ),
    const ExamQuestion(
      id: 'c10',
      type: QuestionType.cq,
      topic: 'Organic Reactions',
      prompt: 'জৈব যৌগের বিক্রিয়াসমূহের বিবরণ দিন।\nDescribe the reactions of organic compounds.',
      marks: 10,
      correctAnswer: '',
      explanation: 'Covers substitution, addition, elimination, and combustion reactions.',
      difficulty: ExamDifficulty.hard,
      subParts: ['(a) Define substitution reaction with an example.', '(b) Distinguish between saturated and unsaturated hydrocarbons.', '(c) Write the combustion reaction of ethane.'],
    ),
  ];

  late final List<ExamQuestion> _biologyQuestions = [
    const ExamQuestion(
      id: 'b1',
      type: QuestionType.mcq,
      topic: 'Cell Biology',
      prompt: 'উদ্ভিদ কোষে কোনটি প্রাণী কোষে থাকে না?\nWhich structure is found in plant cells but NOT animal cells?',
      options: ['Nucleus', 'Cell membrane', 'Cell wall', 'Mitochondria'],
      marks: 1,
      correctAnswer: 'Cell wall',
      explanation: 'Plant cells have a rigid cell wall made of cellulose, which animal cells lack.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 'b2',
      type: QuestionType.mcq,
      topic: 'Genetics',
      prompt: 'DNA-এর পূর্ণরূপ কী?\nWhat is the full form of DNA?',
      options: ['Deoxyribonucleic acid', 'Dinucleic acid', 'Ribonucleic acid', 'Dioxide nucleic acid'],
      marks: 1,
      correctAnswer: 'Deoxyribonucleic acid',
      explanation: 'DNA stands for Deoxyribonucleic Acid, the molecule carrying genetic instructions.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 'b3',
      type: QuestionType.shortAnswer,
      topic: 'Human Digestion',
      prompt: 'খাদ্যনালির অংশগুলোর নাম লিখুন।\nName the parts of the alimentary canal.',
      marks: 3,
      correctAnswer: 'Mouth, esophagus, stomach, small intestine, large intestine, anus',
      explanation: 'The alimentary canal is the pathway food takes from ingestion to egestion.',
      difficulty: ExamDifficulty.easy,
    ),
    const ExamQuestion(
      id: 'b4',
      type: QuestionType.cq,
      topic: 'Evolution',
      prompt: 'বিবর্তনের তত্ত্ব আলোচনা করুন।\nDiscuss the theory of evolution.',
      marks: 10,
      correctAnswer: '',
      explanation: 'Evolution explains how species change over time through natural selection.',
      difficulty: ExamDifficulty.hard,
      subParts: ['(a) State Darwin\'s theory of natural selection.', '(b) Explain survival of the fittest.', '(c) Give evidence of evolution.'],
    ),
    const ExamQuestion(
      id: 'b5',
      type: QuestionType.mcq,
      topic: 'Ecology',
      prompt: 'খাদ্যশৃঙ্খলার প্রথম স্তর কোনটি?\nWhich is the first trophic level in a food chain?',
      options: ['Herbivore', 'Carnivore', 'Producer', 'Decomposer'],
      marks: 1,
      correctAnswer: 'Producer',
      explanation: 'Producers (plants) form the first trophic level by converting sunlight into energy.',
      difficulty: ExamDifficulty.easy,
    ),
  ];
}
