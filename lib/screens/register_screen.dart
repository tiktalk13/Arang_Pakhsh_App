import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  String _role = 'customer'; // default role
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      AppUser? user = await _authService.registerUser(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
        phoneNumber: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty 
            ? null 
            : _addressController.text.trim(),
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ثبت‌نام با موفقیت انجام شد'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to home or login screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'خطا در ثبت‌نام';
      
      switch (e.code) {
        case 'email-already-in-use':
          message = 'این ایمیل قبلاً استفاده شده است';
          break;
        case 'weak-password':
          message = 'رمز عبور خیلی ضعیف است';
          break;
        case 'invalid-email':
          message = 'ایمیل نامعتبر است';
          break;
        case 'operation-not-allowed':
          message = 'ثبت‌نام غیرفعال است';
          break;
        default:
          message = 'خطا در ثبت‌نام: ${e.message}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطای غیرمنتظره رخ داد'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ثبت‌نام"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Header
              const Text(
                'ایجاد حساب کاربری جدید',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'نام کامل',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'نام کامل خود را وارد کنید';
                  }
                  if (value.length < 3) {
                    return 'نام باید حداقل ۳ کاراکتر باشد';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Email
              TextFormField(
                controller: _emailController,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'ایمیل',
                  prefixIcon: Icon(Icons.email),
                  hintText: 'example@email.com',
                  hintTextDirection: TextDirection.ltr,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ایمیل خود را وارد کنید';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'ایمیل معتبر وارد کنید';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'شماره تلفن (اختیاری)',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '09123456789',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^09\d{9}$').hasMatch(value)) {
                      return 'شماره تلفن معتبر وارد کنید';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'آدرس (اختیاری)',
                  prefixIcon: Icon(Icons.location_on),
                  alignLabelWithHint: true,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'رمز عبور',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'رمز عبور خود را وارد کنید';
                  }
                  if (value.length < 6) {
                    return 'رمز عبور حداقل ۶ کاراکتر باشد';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'تکرار رمز عبور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'تکرار رمز عبور را وارد کنید';
                  }
                  if (value != _passwordController.text) {
                    return 'رمز عبور و تکرار آن یکسان نیستند';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Role Selection
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'نقش کاربر',
                  prefixIcon: Icon(Icons.group),
                ),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('مشتری')),
                  DropdownMenuItem(value: 'sales', child: Text('فروشنده')),
                  DropdownMenuItem(value: 'admin', child: Text('مدیر')),
                ],
                onChanged: (value) {
                  setState(() {
                    _role = value!;
                  });
                },
              ),
              
              const SizedBox(height: 30),
              
              // Register Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'ثبت‌نام',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('قبلاً ثبت‌نام کرده‌اید؟'),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('وارد شوید'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
