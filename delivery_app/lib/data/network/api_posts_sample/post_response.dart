class PostResponse {
  final List<Post> posts;

  PostResponse({this.posts = const []});

  factory PostResponse.fromJsonList(List<dynamic> jsonArray) {
    return PostResponse(
      posts: jsonArray.map((json) => Post.fromJson(json)).toList(),
    );
  }
}

class Post {
  final int? userId;
  final int? id;
  final String? title;
  final String? body;

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    userId: json['userId'],
    id: json['id'],
    title: json['title'],
    body: json['body'],
  );

  Post({this.userId, this.id, this.title, this.body});

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'id': id, 'title': title, 'body': body};
  }
}
