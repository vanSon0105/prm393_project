import 'package:delivery_app/data/network/api_posts_sample/post_param.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/data/network/repository/repository.dart';
import 'package:flutter/widgets.dart';

import '../api_posts_sample/post_response.dart';

class ApiRepositoryImpl extends ApiRepository {
  final ApiProvider apiProvider;

  ApiRepositoryImpl({required this.apiProvider});

  @override
  Future<PostResponse> getPostResponse() async {
    final data = await apiProvider.requestApi(param: PostParam());
    debugPrint('----- data = $data');
    return PostResponse.fromJsonList(data);
  }
}
