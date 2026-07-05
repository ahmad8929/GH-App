import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Thin service layer mirroring `GH-Web/src/lib/api/endpoints.ts`.

Paginated<T> _paginated<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) parse,
) =>
    Paginated(
      data: (json['data'] as List? ?? [])
          .map((e) => parse(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] is Map<String, dynamic>
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : Pagination.empty,
    );

class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  Future<AuthSession> login(String email, String password) async {
    final res = await _client
        .post('/auth/login', body: {'email': email, 'password': password});
    return AuthSession(
      accessToken: res['accessToken'] as String,
      refreshToken: res['refreshToken'] as String,
      user: AuthUser.fromJson(res['data'] as Map<String, dynamic>),
    );
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String userType,
  }) async {
    final res = await _client.post('/auth/register', body: {
      'name': name,
      'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'password': password,
      'userType': userType,
    });
    return AuthSession(
      accessToken: res['accessToken'] as String,
      refreshToken: res['refreshToken'] as String,
      user: AuthUser.fromJson(res['data'] as Map<String, dynamic>),
    );
  }

  Future<AuthUser> me() async {
    final res = await _client.get('/auth/me');
    return AuthUser.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> forgotPassword(String email) =>
      _client.post('/auth/forgot-password', body: {'email': email});

  Future<void> verifyOtp(String email, String code) =>
      _client.post('/auth/verify-otp', body: {'email': email, 'code': code});

  Future<void> resetPassword(String email, String code, String newPassword) =>
      _client.post('/auth/reset-password',
          body: {'email': email, 'code': code, 'newPassword': newPassword});
}

class ProfileApi {
  ProfileApi(this._client);
  final ApiClient _client;

  Future<MeProfile> me() async {
    final res = await _client.get('/profile/me');
    return MeProfile.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> update(Map<String, dynamic> fields) =>
      _client.put('/profile/me', body: fields);

  Future<void> updateInfo({String? name, String? email}) =>
      _client.patch('/profile/me/info', body: {
        'name': ?name,
        'email': ?email,
      });

  Future<String> uploadAvatar(XFile file) async {
    final form = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final res = await _client.post('/profile/me/avatar', form: form);
    return (res['data'] as Map<String, dynamic>)['avatar'] as String;
  }
}

class ListingsApi {
  ListingsApi(this._client);
  final ApiClient _client;

  Future<Paginated<Listing>> list({
    String? search,
    String? categoryId,
    String? listingType,
    String? condition,
    String? city,
    num? minPrice,
    num? maxPrice,
    String sort = 'newest',
    int page = 1,
    int limit = 12,
  }) async {
    final res = await _client.get('/listings', query: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (listingType != null && listingType.isNotEmpty)
        'listingType': listingType,
      if (condition != null && condition.isNotEmpty) 'condition': condition,
      if (city != null && city.isNotEmpty) 'city': city,
      'minPrice': ?minPrice,
      'maxPrice': ?maxPrice,
      'sort': sort,
      'page': page,
      'limit': limit,
    });
    return _paginated(res, Listing.fromJson);
  }

  Future<Listing> byId(String id) async {
    final res = await _client.get('/listings/$id');
    return Listing.fromJson(res['data'] as Map<String, dynamic>);
  }
}

class CartApi {
  CartApi(this._client);
  final ApiClient _client;

  Future<List<CartItem>> get() async {
    final res = await _client.get('/cart');
    final data = res['data'] as Map<String, dynamic>;
    return (data['items'] as List? ?? [])
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(String listingId) =>
      _client.post('/cart', body: {'listingId': listingId});

  Future<void> removeItem(String cartItemId) =>
      _client.delete('/cart/items/$cartItemId');

  Future<void> clear() => _client.delete('/cart');
}

class CouponsApi {
  CouponsApi(this._client);
  final ApiClient _client;

  Future<CouponValidation> validate(String code) async {
    final res = await _client.post('/coupons/validate', body: {'code': code});
    return CouponValidation.fromJson(res['data'] as Map<String, dynamic>);
  }
}

class OrdersApi {
  OrdersApi(this._client);
  final ApiClient _client;

  Future<Order> checkout({
    String? couponCode,
    required DeliveryAddress deliveryAddress,
    String? deliveryNote,
    required String paymentMethod,
  }) async {
    final res = await _client.post('/orders/checkout', body: {
      'couponCode': ?couponCode,
      'deliveryAddress': deliveryAddress.toJson(),
      if (deliveryNote != null && deliveryNote.isNotEmpty)
        'deliveryNote': deliveryNote,
      'paymentMethod': paymentMethod,
    });
    return Order.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Paginated<Order>> mine({int page = 1}) async {
    final res =
        await _client.get('/orders/mine', query: {'page': page, 'limit': 10});
    return _paginated(res, Order.fromJson);
  }

  Future<Order> byId(String id) async {
    final res = await _client.get('/orders/$id');
    return Order.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> cancelItem(String orderItemId, {String? reason}) =>
      _client.post('/orders/items/$orderItemId/cancel',
          body: {'reason': ?reason});
}

class FavoritesApi {
  FavoritesApi(this._client);
  final ApiClient _client;

  Future<Paginated<Favorite>> list({int page = 1, int limit = 50}) async {
    final res =
        await _client.get('/favorites', query: {'page': page, 'limit': limit});
    return _paginated(res, Favorite.fromJson);
  }

  Future<bool> toggle(String listingId) async {
    final res = await _client.post('/favorites', body: {'listingId': listingId});
    return (res['data'] as Map<String, dynamic>)['favorited'] == true;
  }
}

class SellbackApi {
  SellbackApi(this._client);
  final ApiClient _client;

  Future<SellbackRequest> submit({
    required String kind,
    required String title,
    String? description,
    required String condition,
    String? categoryId,
    String? expectedPrice,
    String? contactName,
    required String contactPhone,
    required String pickupAddress,
    required String city,
    String? pincode,
    List<XFile> images = const [],
  }) async {
    final form = FormData.fromMap({
      'kind': kind,
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      'condition': condition,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (expectedPrice != null && expectedPrice.isNotEmpty)
        'expectedPrice': expectedPrice,
      if (contactName != null && contactName.isNotEmpty)
        'contactName': contactName,
      'contactPhone': contactPhone,
      'pickupAddress': pickupAddress,
      'city': city,
      if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
    });
    for (final image in images) {
      form.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(image.path, filename: image.name),
      ));
    }
    final res = await _client.post('/sellback', form: form);
    return SellbackRequest.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Paginated<SellbackRequest>> mine({int page = 1}) async {
    final res =
        await _client.get('/sellback/mine', query: {'page': page, 'limit': 20});
    return _paginated(res, SellbackRequest.fromJson);
  }

  Future<void> cancel(String id) => _client.post('/sellback/$id/cancel');
}

class AdsApi {
  AdsApi(this._client);
  final ApiClient _client;

  Future<List<AdCreative>> serve(String placement) async {
    try {
      final res = await _client.get('/ads/serve', query: {'placement': placement});
      return (res['ads'] as List? ?? [])
          .map((e) => AdCreative.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      return const [];
    }
  }

  Future<void> impression(String id) async {
    try {
      await _client.post('/ads/$id/impression');
    } on ApiException {
      // metrics are best-effort
    }
  }

  Future<void> click(String id) async {
    try {
      await _client.post('/ads/$id/click');
    } on ApiException {
      // metrics are best-effort
    }
  }
}

class BlogsApi {
  BlogsApi(this._client);
  final ApiClient _client;

  Future<Paginated<BlogPost>> list({int page = 1}) async {
    final res = await _client.get('/blogs', query: {'page': page});
    return _paginated(res, BlogPost.fromJson);
  }

  Future<BlogPost> bySlug(String slug) async {
    final res = await _client.get('/blogs/$slug');
    return BlogPost.fromJson(res['data'] as Map<String, dynamic>);
  }
}

class NotebooksApi {
  NotebooksApi(this._client);
  final ApiClient _client;

  Future<List<NotebookTemplate>> templates() async {
    final res = await _client.get('/custom-notebooks/templates');
    return (res['data'] as List? ?? [])
        .map((e) => NotebookTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class AnnouncementsApi {
  AnnouncementsApi(this._client);
  final ApiClient _client;

  /// Signed-in users only — callers must not hit this as a guest.
  Future<List<Announcement>> list() async {
    final res = await _client.get('/announcements');
    return (res['data'] as List? ?? [])
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class NotificationsApi {
  NotificationsApi(this._client);
  final ApiClient _client;

  Future<Paginated<AppNotification>> list({int page = 1}) async {
    final res =
        await _client.get('/notifications', query: {'page': page, 'limit': 20});
    return _paginated(res, AppNotification.fromJson);
  }

  Future<void> markRead(String id) => _client.post('/notifications/read/$id');

  Future<void> registerDevice(String token, String platform) =>
      _client.post('/notifications/devices',
          body: {'token': token, 'platform': platform});
}
