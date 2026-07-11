// Dart models mirroring the canonical API contract in
// `GH-Web/src/lib/api/types.ts`. Prices arrive as decimal strings.

String? _s(dynamic v) => v?.toString();

double _d(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _i(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

List<String> _sl(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        total: _i(json['total']),
        page: _i(json['page']),
        limit: _i(json['limit']),
        totalPages: _i(json['totalPages']),
        hasNext: json['hasNext'] == true,
        hasPrev: json['hasPrev'] == true,
      );

  static const empty = Pagination(
      total: 0, page: 1, limit: 20, totalPages: 0, hasNext: false, hasPrev: false);
}

class Paginated<T> {
  final List<T> data;
  final Pagination pagination;
  const Paginated({required this.data, required this.pagination});
}

class CategoryRef {
  final String id;
  final String name;
  final String? slug;

  const CategoryRef({required this.id, required this.name, this.slug});

  factory CategoryRef.fromJson(Map<String, dynamic> json) => CategoryRef(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        slug: _s(json['slug']),
      );
}

/// One quantity tier of a bulk listing: at [minQty]+ units, each costs [unitPrice].
class PriceTier {
  final int minQty;
  final double unitPrice;

  const PriceTier({required this.minQty, required this.unitPrice});

  factory PriceTier.fromJson(Map<String, dynamic> json) => PriceTier(
        minQty: _i(json['minQty']),
        unitPrice: _d(json['unitPrice']),
      );

  Map<String, dynamic> toJson() => {'minQty': minQty, 'unitPrice': unitPrice};
}

class Listing {
  final String id;
  final String title;
  final String? description;
  final String? price;
  final String? originalPrice;
  final String condition; // new | like_new | good | fair | poor
  final String listingType; // sale | exchange | donate
  final String status;
  final String? categoryId;
  final String? grade;
  final String? subject;
  final List<String> images;
  final String? city;
  final bool isFeatured;
  final int viewCount;
  final CategoryRef? category;
  final DateTime? createdAt;

  // Corporate/bulk catalog: restockable products sold in quantity, with an
  // optional minimum order quantity and per-quantity price tiers.
  final bool isBulk;
  final int moq;
  final int? stock;
  final List<PriceTier> priceTiers;

  const Listing({
    required this.id,
    required this.title,
    this.description,
    this.price,
    this.originalPrice,
    required this.condition,
    required this.listingType,
    required this.status,
    this.categoryId,
    this.grade,
    this.subject,
    required this.images,
    this.city,
    required this.isFeatured,
    required this.viewCount,
    this.category,
    this.createdAt,
    this.isBulk = false,
    this.moq = 1,
    this.stock,
    this.priceTiers = const [],
  });

  double get priceValue => _d(price);
  double get originalPriceValue => _d(originalPrice);
  bool get hasDiscount =>
      originalPrice != null && originalPriceValue > priceValue;

  /// Per-unit price at [quantity] — the highest tier whose minQty is covered
  /// wins; falls back to the base price. Mirrors the backend's pricing util.
  double unitPriceFor(int quantity) {
    var best = priceValue;
    var bestMin = 0;
    for (final tier in priceTiers) {
      if (quantity >= tier.minQty && tier.minQty >= bestMin) {
        best = tier.unitPrice;
        bestMin = tier.minQty;
      }
    }
    return best;
  }

  /// Cheapest advertised per-unit price (base or any tier), for "from ₹x/unit".
  double get lowestUnitPrice => priceTiers.fold(
      priceValue, (low, tier) => tier.unitPrice < low ? tier.unitPrice : low);

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'] as String,
        title: (json['title'] ?? '') as String,
        description: _s(json['description']),
        price: _s(json['price']),
        originalPrice: _s(json['originalPrice']),
        condition: (json['condition'] ?? 'good') as String,
        listingType: (json['listingType'] ?? 'sale') as String,
        status: (json['status'] ?? 'approved') as String,
        categoryId: _s(json['categoryId']),
        grade: _s(json['grade']),
        subject: _s(json['subject']),
        images: _sl(json['images']),
        city: _s(json['city']),
        isFeatured: json['isFeatured'] == true,
        viewCount: _i(json['viewCount']),
        category: json['category'] is Map<String, dynamic>
            ? CategoryRef.fromJson(json['category'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.tryParse(_s(json['createdAt']) ?? ''),
        isBulk: json['isBulk'] == true,
        moq: json['moq'] == null ? 1 : _i(json['moq']),
        stock: json['stock'] == null ? null : _i(json['stock']),
        priceTiers: (json['priceTiers'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PriceTier.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'price': price,
        'originalPrice': originalPrice,
        'condition': condition,
        'listingType': listingType,
        'status': status,
        'categoryId': categoryId,
        'grade': grade,
        'subject': subject,
        'images': images,
        'city': city,
        'isFeatured': isFeatured,
        'viewCount': viewCount,
        'category': category == null
            ? null
            : {'id': category!.id, 'name': category!.name, 'slug': category!.slug},
        'createdAt': createdAt?.toIso8601String(),
        'isBulk': isBulk,
        'moq': moq,
        'stock': stock,
        'priceTiers': priceTiers.map((t) => t.toJson()).toList(),
      };
}

class AuthUser {
  final String id;
  final String name;
  final String email;
  final String userType;
  final String? avatar;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.avatar,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        userType: (json['userType'] ?? json['role'] ?? 'student') as String,
        avatar: _s(json['avatar']),
      );
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

/// A named color set an admin created (Admin → Themes). Named `ThemeOption`,
/// not `Theme`, to avoid clashing with `material.dart`'s `Theme` widget.
class ThemeOption {
  final String id;
  final String name;
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String textColor;
  final String headingColor;
  final String buttonBackground;
  final String buttonText;
  final String borderColor;
  final String navbarColor;
  final String footerColor;
  final bool isActive;

  const ThemeOption({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.headingColor,
    required this.buttonBackground,
    required this.buttonText,
    required this.borderColor,
    required this.navbarColor,
    required this.footerColor,
    required this.isActive,
  });

  factory ThemeOption.fromJson(Map<String, dynamic> json) => ThemeOption(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        primaryColor: (json['primaryColor'] ?? '#1e56a0') as String,
        secondaryColor: (json['secondaryColor'] ?? '#2f74c0') as String,
        backgroundColor: (json['backgroundColor'] ?? '#f6f6f6') as String,
        textColor: (json['textColor'] ?? '#5c6f88') as String,
        headingColor: (json['headingColor'] ?? '#163172') as String,
        buttonBackground: (json['buttonBackground'] ?? '#1e56a0') as String,
        buttonText: (json['buttonText'] ?? '#ffffff') as String,
        borderColor: (json['borderColor'] ?? '#d6e4f0') as String,
        navbarColor: (json['navbarColor'] ?? '#f6f6f6') as String,
        footerColor: (json['footerColor'] ?? '#163172') as String,
        isActive: json['isActive'] == true,
      );
}

class Profile {
  final String? bio;
  final String? phone;
  final String? address;
  final String? city;
  final String? avatar;
  final bool isAdvertiser;
  final ThemeOption? theme;

  const Profile({
    this.bio,
    this.phone,
    this.address,
    this.city,
    this.avatar,
    this.isAdvertiser = false,
    this.theme,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        bio: _s(json['bio']),
        phone: _s(json['phone']),
        address: _s(json['address']),
        city: _s(json['city']),
        avatar: _s(json['avatar']),
        isAdvertiser: json['isAdvertiser'] == true,
        theme: json['theme'] is Map<String, dynamic>
            ? ThemeOption.fromJson(json['theme'] as Map<String, dynamic>)
            : null,
      );
}

class MeProfile {
  final AuthUser user;
  final String? phone;
  final Profile? profile;

  const MeProfile({required this.user, this.phone, this.profile});

  factory MeProfile.fromJson(Map<String, dynamic> json) => MeProfile(
        user: AuthUser.fromJson(json),
        phone: _s(json['phone']),
        profile: json['profile'] is Map<String, dynamic>
            ? Profile.fromJson(json['profile'] as Map<String, dynamic>)
            : null,
      );
}

class CartItem {
  final String id;
  final String listingId;
  final Listing listing;
  final int quantity;

  const CartItem({
    required this.id,
    required this.listingId,
    required this.listing,
    this.quantity = 1,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        listingId: json['listingId'] as String,
        listing: Listing.fromJson(json['listing'] as Map<String, dynamic>),
        quantity: json['quantity'] == null ? 1 : _i(json['quantity']),
      );
}

class CouponValidation {
  final String code;
  final double subtotal;
  final double discountAmount;
  final double finalAmount;

  const CouponValidation({
    required this.code,
    required this.subtotal,
    required this.discountAmount,
    required this.finalAmount,
  });

  factory CouponValidation.fromJson(Map<String, dynamic> json) =>
      CouponValidation(
        code: (json['code'] ?? '') as String,
        subtotal: _d(json['subtotal']),
        discountAmount: _d(json['discountAmount']),
        finalAmount: _d(json['finalAmount']),
      );
}

class DeliveryAddress {
  final String name;
  final String phone;
  final String line1;
  final String city;
  final String pincode;

  const DeliveryAddress({
    required this.name,
    required this.phone,
    required this.line1,
    required this.city,
    required this.pincode,
  });

  Map<String, dynamic> toJson() =>
      {'name': name, 'phone': phone, 'line1': line1, 'city': city, 'pincode': pincode};

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) => DeliveryAddress(
        name: (json['name'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        line1: (json['line1'] ?? '') as String,
        city: (json['city'] ?? '') as String,
        pincode: (json['pincode'] ?? '') as String,
      );
}

class OrderItem {
  final String id;
  final String status;
  final String finalAmount;
  final String? cancelReason;
  final String? listingTitle;
  final String? listingImage;

  const OrderItem({
    required this.id,
    required this.status,
    required this.finalAmount,
    this.cancelReason,
    this.listingTitle,
    this.listingImage,
  });

  bool get cancellable =>
      const ['pending', 'confirmed', 'packed'].contains(status);

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'];
    return OrderItem(
      id: json['id'] as String,
      status: (json['status'] ?? 'pending') as String,
      finalAmount: _s(json['finalAmount']) ?? '0',
      cancelReason: _s(json['cancelReason']),
      listingTitle:
          listing is Map<String, dynamic> ? _s(listing['title']) : null,
      listingImage: listing is Map<String, dynamic>
          ? (_sl(listing['images']).isNotEmpty ? _sl(listing['images']).first : null)
          : null,
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String subtotal;
  final String discountAmount;
  final String finalAmount;
  final String paymentStatus;
  final DeliveryAddress? deliveryAddress;
  final String? deliveryNote;
  final List<OrderItem> items;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.subtotal,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentStatus,
    this.deliveryAddress,
    this.deliveryNote,
    required this.items,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        orderNumber: (json['orderNumber'] ?? '') as String,
        subtotal: _s(json['subtotal']) ?? '0',
        discountAmount: _s(json['discountAmount']) ?? '0',
        finalAmount: _s(json['finalAmount']) ?? '0',
        paymentStatus: (json['paymentStatus'] ?? 'unpaid') as String,
        deliveryAddress: json['deliveryAddress'] is Map<String, dynamic>
            ? DeliveryAddress.fromJson(
                json['deliveryAddress'] as Map<String, dynamic>)
            : null,
        deliveryNote: _s(json['deliveryNote']),
        items: (json['items'] as List? ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(_s(json['createdAt']) ?? ''),
      );
}

class Favorite {
  final String id;
  final String listingId;
  final Listing? listing;

  const Favorite({required this.id, required this.listingId, this.listing});

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
        id: json['id'] as String,
        listingId: json['listingId'] as String,
        listing: json['listing'] is Map<String, dynamic>
            ? Listing.fromJson(json['listing'] as Map<String, dynamic>)
            : null,
      );
}

class SellbackRequest {
  final String id;
  final String kind; // sell | donate
  final String title;
  final String condition;
  final String status;
  final String? expectedPrice;
  final String? agreedPrice;
  final String? rejectionReason;
  final DateTime? createdAt;

  const SellbackRequest({
    required this.id,
    required this.kind,
    required this.title,
    required this.condition,
    required this.status,
    this.expectedPrice,
    this.agreedPrice,
    this.rejectionReason,
    this.createdAt,
  });

  bool get cancellable => const ['pending', 'approved'].contains(status);

  factory SellbackRequest.fromJson(Map<String, dynamic> json) =>
      SellbackRequest(
        id: json['id'] as String,
        kind: (json['kind'] ?? 'sell') as String,
        title: (json['title'] ?? '') as String,
        condition: (json['condition'] ?? 'good') as String,
        status: (json['status'] ?? 'pending') as String,
        expectedPrice: _s(json['expectedPrice']),
        agreedPrice: _s(json['agreedPrice']),
        rejectionReason: _s(json['rejectionReason']),
        createdAt: DateTime.tryParse(_s(json['createdAt']) ?? ''),
      );
}

class BlogPost {
  final String slug;
  final String title;
  final String? cover;
  final String excerpt;
  final String contentHtml;
  final String author;
  final DateTime? publishedAt;

  const BlogPost({
    required this.slug,
    required this.title,
    this.cover,
    required this.excerpt,
    required this.contentHtml,
    required this.author,
    this.publishedAt,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) => BlogPost(
        slug: (json['slug'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        cover: _s(json['cover']),
        excerpt: _s(json['excerpt']) ?? '',
        contentHtml: _s(json['contentHtml']) ?? '',
        author: _s(json['author']) ?? 'Gyaan Hub Team',
        publishedAt: DateTime.tryParse(_s(json['publishedAt']) ?? ''),
      );
}

class AdCreative {
  final String id;
  final String image;
  final String targetUrl;

  const AdCreative({required this.id, required this.image, required this.targetUrl});

  factory AdCreative.fromJson(Map<String, dynamic> json) => AdCreative(
        id: json['id'] as String,
        image: (json['image'] ?? '') as String,
        targetUrl: (json['targetUrl'] ?? '#') as String,
      );
}

/// A purchasable advertising plan (Admin → Ad Plans).
class AdPlan {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final String? description;

  const AdPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    this.description,
  });

  factory AdPlan.fromJson(Map<String, dynamic> json) => AdPlan(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        price: _d(json['price']),
        durationDays: _i(json['durationDays']),
        description: _s(json['description']),
      );
}

/// The advertiser's submitted ad creative, pending/approved/rejected by admin.
class AdSubmission {
  final String id;
  final String? businessName;
  final String title;
  final String? description;
  final String image;
  final String? link;
  final String position;
  final String? contactPhone;
  final String? contactEmail;
  final String status; // pending | approved | rejected
  final String? rejectionReason;
  final String subscriptionId;
  final DateTime? createdAt;

  const AdSubmission({
    required this.id,
    this.businessName,
    required this.title,
    this.description,
    required this.image,
    this.link,
    required this.position,
    this.contactPhone,
    this.contactEmail,
    required this.status,
    this.rejectionReason,
    required this.subscriptionId,
    this.createdAt,
  });

  factory AdSubmission.fromJson(Map<String, dynamic> json) => AdSubmission(
        id: json['id'] as String,
        businessName: _s(json['businessName']),
        title: (json['title'] ?? '') as String,
        description: _s(json['description']),
        image: (json['image'] ?? '') as String,
        link: _s(json['link']),
        position: (json['position'] ?? 'home_top') as String,
        contactPhone: _s(json['contactPhone']),
        contactEmail: _s(json['contactEmail']),
        status: (json['status'] ?? 'pending') as String,
        rejectionReason: _s(json['rejectionReason']),
        subscriptionId: (json['subscriptionId'] ?? '') as String,
        createdAt: DateTime.tryParse(_s(json['createdAt']) ?? ''),
      );
}

/// A user's purchase of an [AdPlan] — one per plan, ever. Carries the
/// resulting [AdSubmission] once the advertiser has submitted a creative.
class AdSubscription {
  final String id;
  final String planId;
  final String status; // pending | active | cancelled | expired
  final double? amountPaid;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final AdPlan? plan;
  final AdSubmission? ad;

  const AdSubscription({
    required this.id,
    required this.planId,
    required this.status,
    this.amountPaid,
    this.startsAt,
    this.endsAt,
    this.createdAt,
    this.plan,
    this.ad,
  });

  factory AdSubscription.fromJson(Map<String, dynamic> json) => AdSubscription(
        id: json['id'] as String,
        planId: (json['planId'] ?? '') as String,
        status: (json['status'] ?? 'pending') as String,
        amountPaid: json['amountPaid'] == null ? null : _d(json['amountPaid']),
        startsAt: json['startsAt'] == null
            ? null
            : DateTime.tryParse(_s(json['startsAt']) ?? ''),
        endsAt: json['endsAt'] == null
            ? null
            : DateTime.tryParse(_s(json['endsAt']) ?? ''),
        createdAt: DateTime.tryParse(_s(json['createdAt']) ?? ''),
        plan: json['plan'] is Map<String, dynamic>
            ? AdPlan.fromJson(json['plan'] as Map<String, dynamic>)
            : null,
        ad: json['ad'] is Map<String, dynamic>
            ? AdSubmission.fromJson(json['ad'] as Map<String, dynamic>)
            : null,
      );
}

class NotebookTemplate {
  final String id;
  final String name;
  final String? description;
  final double basePrice;
  final String? cover;

  const NotebookTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.basePrice,
    this.cover,
  });

  factory NotebookTemplate.fromJson(Map<String, dynamic> json) =>
      NotebookTemplate(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        description: _s(json['description']),
        basePrice: _d(json['basePrice']),
        cover: _s(json['cover']),
      );
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final String type; // info | warning | success | maintenance

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: (json['title'] ?? '') as String,
        content: (json['content'] ?? '') as String,
        type: (json['type'] ?? 'info') as String,
      );
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final bool isBroadcast;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.isBroadcast,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: (json['title'] ?? '') as String,
        body: (json['body'] ?? '') as String,
        type: (json['type'] ?? 'system') as String,
        isRead: json['isRead'] == true,
        isBroadcast: json['userId'] == null,
        createdAt: DateTime.tryParse(_s(json['createdAt']) ?? ''),
      );
}
