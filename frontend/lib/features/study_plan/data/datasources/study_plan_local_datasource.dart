import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/study_plan_models.dart';

/// Local persistence for study plans using Hive.
class StudyPlanLocalDataSource {
  const StudyPlanLocalDataSource({required Box<String> plansBox})
      : _plansBox = plansBox;

  final Box<String> _plansBox;

  Future<void> savePlan(StudyPlan plan) async {
    await _plansBox.put(plan.id, jsonEncode(plan.toJson()));
  }

  List<StudyPlan> getPlans() {
    return _plansBox.values
        .map((json) => StudyPlan.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.config.createdAt.compareTo(a.config.createdAt));
  }

  StudyPlan? getPlanById(String id) {
    final json = _plansBox.get(id);
    if (json == null) return null;
    return StudyPlan.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> deletePlan(String id) async {
    await _plansBox.delete(id);
  }

  Future<void> clearAll() async {
    await _plansBox.clear();
  }
}
