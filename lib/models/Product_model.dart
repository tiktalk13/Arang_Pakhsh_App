class ProductModel {
  final String id;
  final String title;
  final String category;
  final String unit;
  final int cartonCount;
  final int basePrice;
  final int price1to4;
  final int price5up;
  final int customerPrice;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.title,
    required this.category,
    this.unit = 'عدد',
    required this.cartonCount,
    required this.basePrice,
    required this.price1to4,
    required this.price5up,
    required this.customerPrice,
    this.imageUrl = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor برای ایجاد از Map
  factory ProductModel.fromMap(Map<String, dynamic> data) {
    return ProductModel(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      unit: data['unit']?.toString() ?? 'عدد',
      cartonCount: _parseToInt(data['carton_count']),
      basePrice: _parseToInt(data['base_price']),
      price1to4: _parseToInt(data['price_1_4']),
      price5up: _parseToInt(data['price_5up']),
      customerPrice: _parseToInt(data['customer_price']),
      imageUrl: data['image_url']?.toString() ?? '',
      createdAt: _parseToDateTime(data['created_at']),
      updatedAt: _parseToDateTime(data['updated_at']),
    );
  }

  // تبدیل به Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'unit': unit,
      'carton_count': cartonCount,
      'base_price': basePrice,
      'price_1_4': price1to4,
      'price_5up': price5up,
      'customer_price': customerPrice,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // محاسبه درصد تخفیف
  int getDiscountPercentage() {
    if (customerPrice <= 0) return 0;
    return ((customerPrice - basePrice) / customerPrice * 100).round();
  }

  // انتخاب قیمت بر اساس تعداد
  int getPriceByQuantity(int quantity) {
    if (quantity >= 5) {
      return price5up;
    } else if (quantity >= 1) {
      return price1to4;
    }
    return basePrice;
  }

  // محاسبه قیمت کل بر اساس تعداد
  int getTotalPrice(int quantity) {
    return getPriceByQuantity(quantity) * quantity;
  }

  // بررسی اینکه آیا محصول موجود است
  bool get isAvailable => basePrice > 0 && title.isNotEmpty;

  // فرمت قیمت با جداکننده
  String getFormattedPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // اعتبارسنجی
  ValidationResult validate() {
    List<String> errors = [];
    
    if (id.isEmpty) errors.add('شناسه محصول الزامی است');
    if (title.isEmpty) errors.add('عنوان محصول الزامی است');
    if (category.isEmpty) errors.add('دسته‌بندی الزامی است');
    if (unit.isEmpty) errors.add('واحد الزامی است');
    if (basePrice <= 0) errors.add('قیمت پایه باید بزرگتر از صفر باشد');
    if (customerPrice <= 0) errors.add('قیمت مشتری باید بزرگتر از صفر باشد');
    if (cartonCount <= 0) errors.add('تعداد در کارتن باید بزرگتر از صفر باشد');
    if (price1to4 <= 0) errors.add('قیمت 1-4 باید بزرگتر از صفر باشد');
    if (price5up <= 0) errors.add('قیمت 5+ باید بزرگتر از صفر باشد');
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  // copyWith برای ایجاد کپی با تغییرات
  ProductModel copyWith({
    String? id,
    String? title,
    String? category,
    String? unit,
    int? cartonCount,
    int? basePrice,
    int? price1to4,
    int? price5up,
    int? customerPrice,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      cartonCount: cartonCount ?? this.cartonCount,
      basePrice: basePrice ?? this.basePrice,
      price1to4: price1to4 ?? this.price1to4,
      price5up: price5up ?? this.price5up,
      customerPrice: customerPrice ?? this.customerPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, title: $title, category: $category, basePrice: $basePrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // متدهای کمکی static
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseToDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

// کلاس کمکی برای validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errors: $errors)';
  }
}

// نمونه استفاده:
/*
void main() {
  final Map<String, dynamic> productData = {
    'id': '78000',
    'title': 'تن ماهی 180 گرمی ساده تن لند',
    'category': 'تن لند',
    'unit': 'عدد',
    'carton_count': 24,
    'base_price': 789000,
    'price_1_4': 821822,
    'price_5up': 795312,
    'customer_price': 998500,
    'image_url': '',
  };

  final product = ProductModel.fromMap(productData);
  
  print('عنوان: ${product.title}');
  print('قیمت برای 3 عدد: ${product.getPriceByQuantity(3)}');
  print('درصد تخفیف: ${product.getDiscountPercentage()}%');
  print('قیمت فرمت شده: ${product.getFormattedPrice(product.basePrice)} تومان');
  print('موجود: ${product.isAvailable}');
  
  final validation = product.validate();
  print('معتبر: ${validation.isValid}');
  if (!validation.isValid) {
    print('خطاها: ${validation.errors}');
  }
}
*/
