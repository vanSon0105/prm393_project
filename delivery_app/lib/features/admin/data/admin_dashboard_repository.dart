import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/data/network/base/provider.dart';

class AdminRatedDriver {
  const AdminRatedDriver({
    required this.id,
    required this.name,
    required this.rating,
    required this.completedTrips,
  });

  final int id;
  final String name;
  final double rating;
  final int completedTrips;

  factory AdminRatedDriver.fromJson(Map<String, dynamic> json) {
    return AdminRatedDriver(
      id: (json['driver_id'] as num).toInt(),
      name: json['full_name'] as String,
      rating: (json['rating'] as num).toDouble(),
      completedTrips: (json['completed_trips'] as num).toInt(),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return '${parts.first[0]}${parts.length > 1 ? parts.last[0] : ''}'
        .toUpperCase();
  }
}

class AdminDashboardOverview {
  const AdminDashboardOverview({
    required this.totalDrivers,
    required this.approvedDrivers,
    required this.pendingRequests,
    required this.topRatedDrivers,
  });

  final int totalDrivers;
  final int approvedDrivers;
  final int pendingRequests;
  final List<AdminRatedDriver> topRatedDrivers;

  factory AdminDashboardOverview.fromJson(Map<String, dynamic> json) {
    final drivers = json['top_rated_drivers'];
    if (drivers is! List) {
      throw const FormatException('Invalid top rated driver list');
    }
    return AdminDashboardOverview(
      totalDrivers: (json['total_drivers'] as num).toInt(),
      approvedDrivers: (json['approved_drivers'] as num).toInt(),
      pendingRequests: (json['pending_requests'] as num).toInt(),
      topRatedDrivers: drivers
          .map(
            (item) => AdminRatedDriver.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class AdminDashboardRepository {
  const AdminDashboardRepository(this._api);

  final ApiProvider _api;

  Future<AdminDashboardOverview> getOverview() async {
    final response = await _api.requestApi(param: _AdminDashboardParam());
    if (response is! Map || response['data'] is! Map) {
      throw const FormatException('Invalid admin dashboard response');
    }
    return AdminDashboardOverview.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}

class _AdminDashboardParam extends ApiParam {
  @override
  String get path => '/api/admin/dashboard';
}
