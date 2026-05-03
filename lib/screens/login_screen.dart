import 'package:flutter/material.dart';
// DİKKAT: AnaSayfa'nın nerede olduğunu Dart'a söylüyoruz. (Senin projenin adına göre tarim_takip kısmını düzelt)
import 'package:tarim_takip/main.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Kapı Bekçimizi (FormKey) tanımladık
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService(); // Servisimizi çağırdık
  bool _isPasswordHidden = true;
  bool _rememberMe = false;
  bool _isLoading = false; // Yüklenme durumu için

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // 2. Tüm giriş kutularını Form bekçisinin içine aldık
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco, size: 100, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  "Tarım Takip'e Hoşgeldin",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Devam etmek için giriş yap",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),

                // 3. TextField yerine TextFormField kullanıyoruz ki kurallar koyabilelim
                // 3. E-posta Kutusu (Akıllı Regex Korumalı)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "E-posta",
                    prefixIcon: const Icon(Icons.email, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen e-posta adresinizi girin';
                    }
                    // İŞTE GERÇEK UYGULAMALARIN KULLANDIĞI REGEX SİHRİ!
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Lütfen geçerli bir e-posta formatı girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 4. Şifre Kutusu (Katı Kurallı)
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordHidden,
                  decoration: InputDecoration(
                    labelText: "Şifre",
                    prefixIcon: const Icon(Icons.lock, color: Colors.green),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordHidden = !_isPasswordHidden;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifrenizi girin';
                    }
                    if (value.length < 8) {
                      return 'Şifre en az 8 karakter olmalıdır';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Şifre en az 1 büyük harf içermelidir';
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return 'Şifre en az 1 küçük harf içermelidir';
                    }
                    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                      return 'Şifre en az 1 özel sembol içermelidir (!@#\$&*)';
                    }
                    return null;
                  },
                ),
                // Şifre Kutusunun hemen altına bu Row'u ekle
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                    ),
                    const Text(
                      "Beni Hatırla",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const Spacer(), // Arayı açar, sağa yaslar
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Şifremi Unuttum",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Butonla arasına biraz boşluk

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              FocusScope.of(
                                context,
                              ).unfocus(); // Klavyeyi kapat

                              setState(() {
                                _isLoading =
                                    true; // Yükleniyor animasyonunu başlat
                              });

                              // GERÇEK API ÇAĞRISI BURADA!
                              // GERÇEK API ÇAĞRISI BURADA!
                              // Artık true/false değil, varsa hata mesajını alıyoruz
                              String? errorMessage = await _apiService.login(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              );

                              // İşlem bitince animasyonu durdur
                              setState(() {
                                _isLoading = false;
                              });

                              // Eğer errorMessage null ise (yani hata yoksa) içeri gir!
                              if (errorMessage == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Giriş Başarılı! Tarlaya Yönlendiriliyorsunuz... 🚜",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AnaSayfa(),
                                  ),
                                );
                              } else {
                                // Hata varsa gerçek sebebi ekrana basıyoruz!
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      errorMessage,
                                    ), // Akıllı hata mesajımız
                                    backgroundColor: Colors.red,
                                    duration: const Duration(
                                      seconds: 4,
                                    ), // Okumak için biraz süre verdik
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    // Yükleniyorsa dönen daire, yüklenmiyorsa yazı göster
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "GİRİŞ YAP",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // login_screen.dart içindeki TextButton kısmı:
                TextButton(
                  onPressed: () {
                    // Kayıt ol sayfasına gidiyoruz!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Hesabın yok mu? Hemen Kayıt Ol",
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
