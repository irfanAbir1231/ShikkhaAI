import 'package:hive/hive.dart';

import '../models/topic_models.dart';

/// Hive-based local persistence for topics overview.
class TopicsLocalDataSource {
  const TopicsLocalDataSource({required Box<String> topicsBox})
      : _topicsBox = topicsBox;

  final Box<String> _topicsBox;

  static const String _overviewKey = 'topics_overview';

  Future<void> cacheTopicsOverview(TopicsOverview overview) async {
    await _topicsBox.put(_overviewKey, overview.toJsonString());
  }

  TopicsOverview? getCachedTopicsOverview() {
    final raw = _topicsBox.get(_overviewKey);
    if (raw == null) return null;
    try {
      return TopicsOverview.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    await _topicsBox.delete(_overviewKey);
  }
}
