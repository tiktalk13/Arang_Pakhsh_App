// models/product_model.dart
class Product {
  final String id;
  final String title;
  final String category;
  final String unit;
  final int cartonCount;
  final double basePrice;
  final double price1To4;
  final double price5Up;
  final double customerPrice;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.category,
    required this.unit,
    required this.cartonCount,
    required this.basePrice,
    required this.price1To4,
    required this.price5Up,
    required this.customerPrice,
    this.imageUrl = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor برای ایجاد از JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      cartonCount: json['carton_count'] as int,
      basePrice: (json['base_price'] as num).toDouble(),
      price1To4: (json['price_1_4'] as num).toDouble(),
      price5Up: (json['price_5up'] as num).toDouble(),
      customerPrice: (json['customer_price'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // تبدیل به JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'unit': unit,
      'carton_count': cartonCount,
      'base_price': basePrice,
      'price_1_4': price1To4,
      'price_5up': price5Up,
      'customer_price': customerPrice,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // محاسبه درصد تخفیف
  int getDiscountPercentage() {
    return ((customerPrice - basePrice) / customerPrice * 100).round();
  }

  // انتخاب قیمت بر اساس تعداد
  double getPriceByQuantity(int quantity) {
    if (quantity >= 5) {
      return price5Up;
    } else if (quantity >= 1) {
      return price1To4;
    }
    return basePrice;
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
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  // copyWith برای ایجاد کپی با تغییرات
  Product copyWith({
    String? id,
    String? title,
    String? category,
    String? unit,
    int? cartonCount,
    double? basePrice,
    double? price1To4,
    double? price5Up,
    double? customerPrice,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      cartonCount: cartonCount ?? this.cartonCount,
      basePrice: basePrice ?? this.basePrice,
      price1To4: price1To4 ?? this.price1To4,
      price5Up: price5Up ?? this.price5Up,
      customerPrice: customerPrice ?? this.customerPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, title: $title, category: $category, basePrice: $basePrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// کلاس کمکی برای validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });
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

  final product = Product.fromJson(productData);
  print(product.getPriceByQuantity(3)); // 821822.0
  print(product.getDiscountPercentage()); // محاسبه درصد تخفیف
}
*/
