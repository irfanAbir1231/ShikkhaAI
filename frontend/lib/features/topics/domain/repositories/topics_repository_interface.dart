import '../../../../core/utils/result.dart';
import '../../data/models/topic_models.dart';

/// Abstract contract for topics data operations.
abstract class TopicsRepositoryInterface {
  /// Fetches the complete topic overview for a student.
  Future<Result<TopicsOverview>> getTopicsOverview(int studentId);
}
