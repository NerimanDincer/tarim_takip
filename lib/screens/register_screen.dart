import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(); // YENİ: Telefon

  bool _isPasswordHidden = true;
  bool _isLoading = false;

  List<dynamic> _gercekBolgeler = []; // API'den gelecek bölgeler
  bool _isLoadingRegions = true;
  int? _selectedRegionId; // YENİ: Bölge ID'si

  @override
  void initState() {
    super.initState();
    _loadRegions(); // Sayfa açılırken bölgeleri çek
  }

  Future<void> _loadRegions() async {
    try {
      var bolgeler = await _apiService.getRegions();
      setState(() {
        _gercekBolgeler = bolgeler;
        _isLoadingRegions = false;
      });
    } catch (e) {
      setState(() => _isLoadingRegions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text(
          "Yeni Hesap Oluştur",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoadingRegions
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_add_alt_1,
                        size: 80,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Aramıza Katıl",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 1. AD SOYAD
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration(
                          "Ad Soyad",
                          Icons.person,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Lütfen adınızı girin'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // 2. E-POSTA
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          "E-posta",
                          Icons.email,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Lütfen e-posta girin';
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value))
                            return 'Geçerli bir e-posta formatı girin';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // 3. TELEFON (YENİ)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration(
                          "Telefon Numarası",
                          Icons.phone,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Lütfen telefonunuzu girin'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // 4. BÖLGE SEÇİMİ (GERÇEK VERİTABANI BAĞLANTILI)
                      DropdownButtonFormField<int>(
                        decoration: _buildInputDecoration(
                          "Bulunduğunuz Bölge",
                          Icons.map,
                        ),
                        value: _selectedRegionId,
                        items: _gercekBolgeler.map((bolge) {
                          return DropdownMenuItem<int>(
                            value: bolge['id'],
                            child: Text(bolge['name']),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedRegionId = val),
                        validator: (value) =>
                            value == null ? 'Lütfen bölgenizi seçin' : null,
                      ),
                      const SizedBox(height: 20),

                      // 5. ŞİFRE
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordHidden,
                        decoration: InputDecoration(
                          labelText: "Şifre",
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.green,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                              () => _isPasswordHidden = !_isPasswordHidden,
                            ),
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
                          if (value == null || value.isEmpty)
                            return 'Şifre boş bırakılamaz';
                          if (value.length < 8)
                            return 'En az 8 karakter olmalıdır';
                          if (!value.contains(RegExp(r'[A-Z]')))
                            return 'En az 1 büyük harf içermelidir';
                          if (!value.contains(RegExp(r'[0-9]')))
                            return 'En az 1 rakam içermelidir';
                          if (!value.contains(
                            RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
                          ))
                            return 'En az 1 özel sembol içermelidir';
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // KAYIT BUTONU
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    FocusScope.of(context).unfocus();
                                    setState(() => _isLoading = true);

                                    String?
                                    errorMessage = await _apiService.register(
                                      _nameController.text.trim(),
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                      _phoneController.text
                                          .trim(), // Telefonu gönderiyoruz
                                      _selectedRegionId!, // Region ID'sini gönderiyoruz
                                    );

                                    setState(() => _isLoading = false);

                                    if (errorMessage == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Kayıt Başarılı! Şimdi giriş yapabilirsiniz. 🌱",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMessage),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 4),
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
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "KAYIT OL",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
    );
  }
}
