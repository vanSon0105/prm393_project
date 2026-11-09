import 'dart:typed_data';

import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/profile/profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GET and multipart update use the existing profile API', () async {
    final api = _RecordingApiProvider();
    final repository = ProfileRepository(api);

    final profile = await repository.getProfile(17);
    expect(api.lastParam?.path, '/api/17/profile');
    expect(api.lastParam?.method, Method.get);
    expect(profile.fullName, 'Alex');
    expect(profile.phoneNumber, '0912345678');

    final saved = await repository.updateProfile(
      17,
      ProfileChanges(
        fullName: 'Alex Updated',
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageName: 'avatar.png',
      ),
    );
    final param = api.lastParam!;
    expect(param.path, '/api/17/profile');
    expect(param.method, Method.post);
    expect(param.contentType, HeaderContentType.multipartFormData);
    expect(param.useMultipart, isTrue);
    final form = await param.formData;
    expect(
      form.fields.any(
        (field) => field.key == 'full_name' && field.value == 'Alex Updated',
      ),
      isTrue,
    );
    expect(form.fields.any((field) => field.key == 'phone_number'), isFalse);
    expect(form.files.single.key, 'image');
    expect(form.files.single.value.filename, 'avatar.png');
    expect(saved.id, 17);
  });
}

class _RecordingApiProvider extends ApiProvider {
  _RecordingApiProvider() : super(Dio());

  ApiParam? lastParam;

  @override
  Future<dynamic> requestApi({required ApiParam param}) async {
    lastParam = param;
    return {
      'data': {
        'profile_id': 17,
        'user_name': 'alex',
        'full_name': 'Alex',
        'phone_number': '0912345678',
        'address': 'Ha Noi',
        'image': '',
      },
    };
  }
}
