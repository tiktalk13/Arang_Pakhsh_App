import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product; // برای حالت ویرایش
  
  const AddProductScreen({
    Key? key,
    this.product,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _basePriceController = TextEditingController();
  final TextEditingController _price1to4Controller = TextEditingController();
  final TextEditingController _price5upController = TextEditingController();
  final TextEditingController _customerPriceController = TextEditingController();
  final TextEditingController _cartonCountController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  
  String? _selectedCategory;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool get _isEditMode => widget.product != null;

  final List<String> _categories = [
    'تن لند',
    'کنسرو',
    'رب',
    'روغن',
    'لبنیات',
    'نوشیدنی',
    'متفرقه',
  ];

  final List<String> _units = [
    'عدد',
    'کیلوگرم',
    'گرم',
    'لیتر',
    'میلی‌لیتر',
    'بسته',
    'جعبه',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (_isEditMode) {
      final product = widget.product!;
      _titleController.text = product.title;
      _basePriceController.text = product.basePrice.toString();
      _price1to4Controller.text = product.price1to4.toString();
      _price5upController.text = product.price5up.toString();
      _customerPriceController.text = product.customerPrice.toString();
      _cartonCountController.text = product.cartonCount.toString();
      _unitController.text = product.unit;
      _selectedCategory = product.category;
      _existingImageUrl = product.imageUrl;
    } else {
      // مقادیر پیش‌فرض برای محصول جدید
      _unitController.text = 'عدد';
      _cartonCountController.text = '1';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _basePriceController.dispose();
    _price1to4Controller.dispose();
    _price5upController.dispose();
    _customerPriceController.dispose();
    _cartonCountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('خطا در انتخاب تصویر: ${e.toString()}');
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
      _existingImageUrl = null;
    });
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) {
      return _existingImageUrl; // برگرداندن URL موجود در حالت ویرایش
    }

    try {
      final String fileName = '${const Uuid().v4()}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(
        _selectedImage!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_by': 'arang_app',
            'upload_time': DateTime.now().toIso8601String(),
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('خطا در آپلود تصویر: ${e.toString()}');
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // بررسی انتخاب دسته‌بندی
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _showErrorSnackBar('لطفا دسته‌بندی محصول را انتخاب کنید');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // آپلود تصویر
      final String? imageUrl = await _uploadImage();

      // ایجاد یا بروزرسانی محصول
      final ProductModel productData = ProductModel(
        id: _isEditMode ? widget.product!.id : const Uuid().v4(),
        title: _titleController.text.trim(),
        category: _selectedCategory!,
        unit: _unitController.text.trim(),
        cartonCount: int.parse(_cartonCountController.text),
        basePrice: int.parse(_basePriceController.text),
        price1to4: int.parse(_price1to4Controller.text),
        price5up: int.parse(_price5upController.text),
        customerPrice: int.parse(_customerPriceController.text),
        imageUrl: imageUrl ?? '',
        createdAt: _isEditMode ? widget.product!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // اعتبارسنجی نهایی
      final validation = productData.validate();
      if (!validation.isValid) {
        _showErrorSnackBar('خطاهای اعتبارسنجی:\n${validation.errors.join('\n')}');
        return;
      }

      // ذخیره در Firestore
      if (_isEditMode) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productData.id)
            .update(productData.toMap());
        _showSuccessSnackBar('محصول با موفقیت بروزرسانی شد');
      } else {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productData.id)
            .set(productData.toMap());
        _showSuccessSnackBar('محصول با موفقیت اضافه شد');
      }

      if (!_isEditMode) {
        _clearForm();
      }

      // بازگشت به صفحه قبل در حالت ویرایش
      if (_isEditMode) {
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      _showErrorSnackBar('خطا در ذخیره محصول: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _basePriceController.clear();
    _price1to4Controller.clear();
    _price5upController.clear();
    _customerPriceController.clear();
    _cartonCountController.text = '1';
    _unitController.text = 'عدد';
    setState(() {
      _selectedCategory = null;
      _selectedImage = null;
      _existingImageUrl = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'بستن',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'بستن',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'ویرایش محصول' : 'افزودن محصول جدید'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProduct,
              child: Text(
                _isEditMode ? 'بروزرسانی' : 'ذخیره',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // بخش تصویر
              _buildImageSection(),
              const SizedBox(height: 24),

              // اطلاعات اصلی محصول
              _buildBasicInfoSection(),
              const SizedBox(height: 24),

              // بخش قیمت‌گذاری
              _buildPricingSection(),
              const SizedBox(height: 24),

              // بخش مشخصات فنی
              _buildSpecificationsSection(),
              const SizedBox(height: 32),

              // دکمه‌های عمل
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'تصویر محصول',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.edit),
                      label: const Text('تغییر تصویر'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete),
                      label: const Text('حذف تصویر'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _existingImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 64),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.edit),
                      label: const Text('تغییر تصویر'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete),
                      label: const Text('حذف تصویر'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.dashed),
                ),
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'برای انتخاب تصویر کلیک کنید',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'اطلاعات اصلی',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'نام محصول *',
                hintText: 'نام کامل محصول را وارد کنید',
                prefixIcon: Icon(Icons.inventory_2),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'نام محصول الزامی است';
                }
                if (value.trim().length < 3) {
                  return 'نام محصول باید حداقل 3 کاراکتر باشد';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی *',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'انتخاب دسته‌بندی الزامی است';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'قیمت‌گذاری',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _basePriceController,
                    decoration: const InputDecoration(
                      labelText: 'قیمت پایه *',
                      hintText: '0',
                      suffixText: 'تومان',
                      prefixIcon: Icon(Icons.price_change),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'قیمت پایه الزامی است';
                      }
                      final price = int.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'قیمت باید بزرگتر از صفر باشد';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _customerPriceController,
                    decoration: const InputDecoration(
                      labelText: 'قیمت مشتری *',
                      hintText: '0',
                      suffixText: 'تومان',
                      prefixIcon: Icon(Icons.sell),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'قیمت مشتری الزامی است';
                      }
                      final price = int.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'قیمت باید بزرگتر از صفر باشد';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price1to4Controller,
                    decoration: const InputDecoration(
                      labelText: 'قیمت 1-4 عدد *',
                      hintText: '0',
                      suffixText: 'تومان',
                      prefixIcon: Icon(Icons.looks_one),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'قیمت 1-4 الزامی است';
                      }
                      final price = int.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'قیمت باید بزرگتر از صفر باشد';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _price5upController,
                    decoration: const InputDecoration(
                      labelText: 'قیمت 5+ عدد *',
                      hintText: '0',
                      suffixText: 'تومان',
                      prefixIcon: Icon(Icons.looks_5),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'قیمت 5+ الزامی است';
                      }
                      final price = int.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'قیمت باید بزرگتر از صفر باشد';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.straighten, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'مشخصات فنی',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unitController.text.isNotEmpty ? _unitController.text : null,
                    decoration: const InputDecoration(
                      labelText: 'واحد اندازه‌گیری *',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _unitController.text = value;
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'انتخاب واحد الزامی است';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cartonCountController,
                    decoration: const InputDecoration(
                      labelText: 'تعداد در کارتن *',
                      hintText: '1',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'تعداد در کارتن الزامی است';
                      }
                      final count = int.tryParse(value);
                      if (count == null || count <= 0) {
                        return 'تعداد باید بزرگتر از صفر باشد';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isLoading) ...[
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('در حال ذخیره...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saveProduct,
              icon: Icon(_isEditMode ? Icons.update : Icons.save),
              label: Text(
                _isEditMode ? 'بروزرسانی محصول' : 'ذخیره محصول',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          if (!_isEditMode) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _clearForm,
                icon: const Icon(Icons.clear_all),
                label: const Text(
                  'پاک کردن فرم',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
