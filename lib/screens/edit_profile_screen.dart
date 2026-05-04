import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String currentEmail; // E-postayı da aldık
  final String currentBio;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentPhone,
    required this.currentEmail,
    required this.currentBio,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _emailController = TextEditingController(text: widget.currentEmail);
    _bioController = TextEditingController(text: widget.currentBio);
  }

  // Alttan açılan Resim Seçme Menüsü
  void _resimSecmeMenusuGoster() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Profil Fotoğrafı Seç",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.green),
                title: const Text('Kamerayı Aç'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kamera açılıyor... 📸")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Galeri açılıyor... 🖼️")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Mevcut Fotoğrafı Sil',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // İsmin ilk harfini alıyoruz avatar için
    final String initial = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : 'Ç';

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("Profili Düzenle"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profil Resmi Değiştirme Alanı
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 50,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _resimSecmeMenusuGoster,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 1. E-posta (KİLİTLİ / SADECE OKUNABİLİR)
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: const TextStyle(color: Colors.grey),
                decoration: _buildInput("E-posta (Değiştirilemez)", Icons.lock),
              ),
              const SizedBox(height: 20),

              // 2. Ad Soyad
              TextFormField(
                controller: _nameController,
                decoration: _buildInput("Ad Soyad", Icons.person),
                validator: (value) =>
                    value!.isEmpty ? 'Adınızı boş bırakamazsınız' : null,
              ),
              const SizedBox(height: 20),

              // 3. Telefon
              // 3. TELEFON (KORUMA GÖREVLİLERİ EKLENDİ!)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                // KORUMA GÖREVLİLERİ (InputFormatters) SADECE RAKAM VE MAKSİMUM 11 HANE!
                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly, // Harf yazılmasını kesin olarak engeller!
                  LengthLimitingTextInputFormatter(
                    11,
                  ), // 11 haneden fazla girilemez!
                ],
                decoration: _buildInput("Telefon Numarası", Icons.phone),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Telefon boş bırakılamaz';
                  if (value.length < 10)
                    return 'Geçerli bir telefon numarası girin (En az 10 hane)';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 4. Biyografi
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: _buildInput(
                  "Hakkımda / Biyografi",
                  Icons.info_outline,
                ),
              ),
              const SizedBox(height: 40),

              // Kaydet Butonu (API BAĞLANTILI)
              // KAYDET BUTONU
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

                            // GERÇEK API GÜNCELLEMESİ (BİYOGRAFİ DE GİDİYOR!)
                            String? error = await _apiService.updateProfile(
                              _nameController.text.trim(),
                              _phoneController.text.trim(),
                              _bioController.text.trim(), // Biyografi eklendi!
                            );

                            setState(() => _isLoading = false);

                            if (error == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Profil bilgileriniz güncellendi! ✅",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green, // Rengi temanla uyumlu yeşil yaptık
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "GÜNCELLEMELERİ KAYDET",
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
    );
  }

  InputDecoration _buildInput(String label, IconData icon) {
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
