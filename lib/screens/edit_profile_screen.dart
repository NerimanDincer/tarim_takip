import 'package:flutter/material.dart';

class ProfilDuzenlemeSayfasi extends StatefulWidget {
  const ProfilDuzenlemeSayfasi({super.key});

  @override
  State<ProfilDuzenlemeSayfasi> createState() => _ProfilDuzenlemeSayfasiState();
}

class _ProfilDuzenlemeSayfasiState extends State<ProfilDuzenlemeSayfasi> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController(
    text: "Neriman",
  );
  final TextEditingController _phoneController = TextEditingController(
    text: "5551234567",
  );
  final TextEditingController _bioController = TextEditingController(
    text: "Akdeniz Üniversitesi - Sistem Yöneticisi",
  );
  // E-posta controller'ı ekledik
  final TextEditingController _emailController = TextEditingController(
    text: "neri@tarimtakip.com",
  );

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
                  Navigator.pop(context); // Menüyü kapat
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
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Text(
                      "N",
                      style: TextStyle(
                        fontSize: 50,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _resimSecmeMenusuGoster, // Tıklanınca menü açılır!
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
                readOnly: true, // İŞTE MAYIN TARLASINI BURADAN KAPATTIK!
                style: const TextStyle(
                  color: Colors.grey,
                ), // Rengini soluk yaptık ki değiştirilemeyeceği anlaşılsın
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
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInput("Telefon Numarası", Icons.phone),
                validator: (value) => (value == null || value.length < 10)
                    ? 'Geçerli bir numara girin'
                    : null,
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

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      FocusScope.of(context).unfocus();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profil bilgileriniz güncellendi! ✅"),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
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
