import 'dart:async';
import 'dart:math';

import '../models/explanation_mode.dart';

/// Mock service that simulates AI responses for the Study Companion.
/// Returns a [Stream<String>] for a word-by-word typing effect.
class MockStudyCompanionService {
  final _random = Random();

  Stream<String> generateResponse({
    required String query,
    required ExplanationMode mode,
    String? fileName,
  }) async* {
    // Simulate network delay (1.5–3 seconds)
    await Future.delayed(
      Duration(milliseconds: 1500 + _random.nextInt(1500)),
    );

    final response = _buildResponse(query: query, mode: mode, fileName: fileName);
    final words = response.split(' ');

    // Stream words with realistic typing speed
    var buffer = '';
    for (var i = 0; i < words.length; i++) {
      buffer += '${i == 0 ? '' : ' '}${words[i]}';
      yield buffer;
      // Variable delay: faster for short words, slower for punctuation
      final word = words[i];
      final baseDelay = word.endsWith('.') || word.endsWith('?') || word.endsWith('!')
          ? 80
          : word.endsWith(',') || word.endsWith(':') || word.endsWith(';')
              ? 50
              : 30;
      await Future.delayed(
        Duration(milliseconds: baseDelay + _random.nextInt(20)),
      );
    }
  }

  String _buildResponse({
    required String query,
    required ExplanationMode mode,
    String? fileName,
  }) {
    final context = fileName != null
        ? '\n\n*(Based on: **$fileName**)*\n\n'
        : '\n\n';

    switch (mode) {
      case ExplanationMode.easyBengali:
        return _easyBengaliResponse(query, context);
      case ExplanationMode.easyEnglish:
        return _easyEnglishResponse(query, context);
      case ExplanationMode.explainLike10:
        return _explainLike10Response(query, context);
      case ExplanationMode.summary:
        return _summaryResponse(query, context);
      case ExplanationMode.importantQuestions:
        return _importantQuestionsResponse(query, context);
      case ExplanationMode.commonMistakes:
        return _commonMistakesResponse(query, context);
      case ExplanationMode.examTips:
        return _examTipsResponse(query, context);
    }
  }

  String _easyBengaliResponse(String query, String context) {
    return '''# সহজ বাংলায় ব্যাখ্যা

$query$context
**ফোটোসিন্থেসিস** মানে হলো উদ্ভিদদের খাদ্য তৈরির প্রক্রিয়া। চলো সহজভাবে বুঝি:

## মূল বিষয়গুলো:
- **সূর্যের আলো** — উদ্ভিদ পাতা সূর্যের আলো শোষণ করে
- **পানি** — মাটি থেকে শিকড় দিয়ে পানি তোলে
- **কার্বন ডাই-অক্সাইড** — বাতাস থেকে নেয়

## সহজ সূত্র:
```
সূর্যালো + পানি + CO₂ = খাদ্য (গ্লুকোজ) + অক্সিজেন
```

> **মনে রাখো:** উদ্ভিদ আমাদের জন্য অক্সিজেন তৈরি করে — তাই গাছ লাগানো জরুরি! 🌱

আর কিছু জানতে চাইলে জিজ্ঞাসা করো!'''; // Bengali explanation of photosynthesis as example
  }

  String _easyEnglishResponse(String query, String context) {
    return '''# Simple Explanation

$query$context
Let me break this down into easy-to-understand pieces:

## What You Need to Know

**Photosynthesis** is how plants make their own food. Think of it like a tiny factory inside every green leaf!

### The Three Ingredients
1. **Sunlight** — captured by the green pigment called *chlorophyll*
2. **Water** — absorbed from the soil through roots
3. **Carbon Dioxide** — taken from the air through tiny pores called *stomata*

### The Result
The plant produces **glucose** (sugar for energy) and releases **oxygen** into the air — which is what we breathe!

> **Analogy:** Imagine a plant is like a little chef. The sun is the stove, water and CO₂ are the ingredients, and the meal it cooks is glucose!

**Key takeaway:** Without photosynthesis, there would be no oxygen for animals and humans to survive. 🌍'''; // Simple English with analogies
  }

  String _explainLike10Response(String query, String context) {
    return '''# Hey there, little scientist! 🧪

You asked about *$query* — awesome question!$context

Imagine you have a **magic leaf**. When the sun shines on it, the leaf does something super cool — it makes its own lunch! 🍕

## Here's the story:

**Once upon a time...**
> A little plant woke up in the morning. The sun said "Good morning!" and the plant opened its leaves wide. It drank some water through its feet (roots) and took a big breath of air.

Then — *POOF!* — inside the leaf, a tiny kitchen started working!

### The Recipe:
- ☀️ 1 cup of sunlight
- 💧 1 cup of water
- 🌬️ A pinch of air (CO₂)

**Mix them together** and you get:
- 🍬 Sugar (food for the plant)
- 💨 Oxygen (air for us to breathe!)

### Cool fact:
> Trees are basically Earth's superheroes. They clean our air and give us oxygen to breathe! How cool is that?

So next time you see a tree, give it a high-five! 🌳✋'''; // Child-friendly with story format
  }

  String _summaryResponse(String query, String context) {
    return '''# Quick Summary

$query$context
## Key Points

- **Definition:** Photosynthesis is the process by which green plants convert light energy into chemical energy
- **Location:** Occurs in the chloroplasts of plant cells
- **Reactants:** 6CO₂ + 6H₂O + Light Energy
- **Products:** C₆H₁₂O₆ (Glucose) + 6O₂
- **Types:**
  - **Light-dependent reactions** — produce ATP and NADPH
  - **Calvin cycle (Light-independent)** — produces glucose

## Important Terms
| Term | Meaning |
|------|---------|
| Chlorophyll | Green pigment that absorbs light |
| Stomata | Tiny pores for gas exchange |
| ATP | Energy currency of the cell |

> **Remember:** The overall equation is **6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂**

**Study tip:** Focus on the inputs, outputs, and where each stage happens!'''; // Bullet-point condensed version
  }

  String _importantQuestionsResponse(String query, String context) {
    return '''# Important Exam Questions

$query$context
## Likely Questions for Your Exam

### 1. Short Answer (2-3 marks)
**Q:** What is photosynthesis? Name the raw materials required.
**A:** Photosynthesis is the process by which green plants synthesize food using sunlight. Raw materials: CO₂, water, and sunlight.

### 2. Diagram-Based (3-4 marks)
**Q:** Draw a labeled diagram of a chloroplast and mark the thylakoid and stroma.
**A:** *(Practice drawing this — it comes almost every year!)*

### 3. Long Answer (5 marks)
**Q:** Explain the process of photosynthesis with a balanced chemical equation.
**A:**
- Mention light-dependent and light-independent reactions
- Write the equation: 6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂
- Explain the role of chlorophyll, stomata, and chloroplasts

### 4. MCQ-style
**Q:** In which part of the plant cell does photosynthesis occur?
- (a) Mitochondria
- (b) **Chloroplast** ✅
- (c) Nucleus
- (d) Ribosome

### 5. Comparison (3 marks)
**Q:** Differentiate between aerobic and anaerobic respiration.

> **Pro tip:** Questions on the **chemical equation** and **diagram of chloroplast** appear in almost every board exam!'''; // Numbered exam questions
  }

  String _commonMistakesResponse(String query, String context) {
    return '''# Common Mistakes to Avoid ⚠️

$query$context
## Mistakes Students Often Make

### ❌ Mistake 1: Confusing Inputs and Outputs
**Wrong:** "Plants take in oxygen and give out CO₂ during photosynthesis"
**Right:** Plants take in **CO₂** and give out **Oxygen** during photosynthesis

> **Why it happens:** Students confuse photosynthesis with respiration!

### ❌ Mistake 2: Forgetting Light is Required
**Wrong:** "Photosynthesis happens all the time, day and night"
**Right:** The **light-dependent reactions** need sunlight. The Calvin cycle can happen without light but needs the products from the light reactions.

### ❌ Mistake 3: Wrong Chemical Equation
**Wrong:** Writing CO + H₂O → products
**Right:** **6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂** (balance the atoms!)

### ❌ Mistake 4: Calling it "Photo-syntheSIS" (wrong stress)
**Right:** "Photo-SYN-the-sis"

## Quick Checklist Before the Exam ✅
- [ ] Memorize the balanced equation
- [ ] Know the difference between stomata and chloroplast
- [ ] Remember: only **green plants** do photosynthesis
- [ ] Don't confuse it with respiration

> **Teacher's secret:** The most common error is mixing up photosynthesis and respiration. If you get this right, you're already ahead of 50% of students!'''; // Highlighted pitfalls
  }

  String _examTipsResponse(String query, String context) {
    return '''# Exam Tips & Strategy 🎯

$query$context
## How to Score Full Marks

### Before the Exam
1. **Draw the diagram** at least 5 times from memory
2. **Practice the equation** until you can write it in your sleep
3. **Make flashcards** for key terms: chlorophyll, stomata, chloroplast, ATP, NADPH

### During the Exam

#### Time Management
| Question Type | Suggested Time |
|---------------|----------------|
| MCQ (1 mark) | 1 minute |
| Short Answer (2-3 marks) | 3-4 minutes |
| Long Answer (5 marks) | 8-10 minutes |
| Diagram (3-4 marks) | 5 minutes |

#### Presentation Tips
- **Always draw diagrams with a pencil** first, then go over with pen
- **Label every part** — unlabeled diagrams get 0 marks!
- **Write the chemical equation** whenever relevant — examiners love it
- **Use bullet points** for 3+ mark questions

### Keywords Examiners Look For
> chlorophyll, chloroplast, stomata, glucose, oxygen, carbon dioxide, sunlight, ATP, NADPH, thylakoid, stroma, Calvin cycle

### Last-Minute Hack
If you forget the equation, remember:
> **"6 carbons, 6 waters, light makes sugar and 6 oxygens"**

**You've got this! 💪**'''; // Strategy and time-management
  }
}
