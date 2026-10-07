import '../api_posts_sample/post_response.dart';

abstract class ApiRepository {
  Future<PostResponse> getPostResponse();
}
