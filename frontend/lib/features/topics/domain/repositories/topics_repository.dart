import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/topics_local_datasource.dart';
import '../../data/datasources/topics_remote_datasource.dart';
import '../../data/models/topic_models.dart';
import '../../data/services/mock_topics_service.dart';
import 'topics_repository_interface.dart';

/// Concrete repository coordinating remote API, local persistence, and mock fallback.
class TopicsRepository implements TopicsRepositoryInterface {
  TopicsRepository({
    required TopicsLocalDataSource localDataSource,
    TopicsRemoteDataSource? remoteDataSource,
    bool useMockFallback = true,
  })  : _local = localDataSource,
        _remote = remoteDataSource ?? TopicsRemoteDataSource(),
        _useMockFallback = useMockFallback;

  final TopicsLocalDataSource _local;
  final TopicsRemoteDataSource _remote;
  final bool _useMockFallback;

  @override
  Future<Result<TopicsOverview>> getTopicsOverview(int studentId) async {
    try {
      final overview = await _remote.fetchTopicsOverview(studentId);
      await _local.cacheTopicsOverview(overview);
      return Result.success(overview);
    } on AppException catch (e) {
      final cached = _local.getCachedTopicsOverview();
      if (cached != null) {
        return Result.success(cached);
      }
      if (_useMockFallback) {
        final mock = await const MockTopicsService().fetchTopicsOverview(studentId);
        return Result.success(mock);
      }
      return Result.failure(mapExceptionToFailure(e));
    }
  }
}
