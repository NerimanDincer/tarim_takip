import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _userProfile;

  @override
  void initState() {
    super.initState();
    // Sayfa açılırken C# API'den gerçek verileri istiyoruz!
    _userProfile = _apiService.getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text(
          'Profilim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfile,
        builder: (context, snapshot) {
          // 1. Veriler yoldaysa (Yükleniyor)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }
          // 2. Hata çıkarsa
          else if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          // 3. Veri gelmezse
          else if (!snapshot.hasData) {
            return const Center(child: Text("Profil bilgileri bulunamadı."));
          }

          // 4. Veriler başarıyla geldiyse paketleri açıyoruz!
          final profile = snapshot.data!;

          // API'den gelen anahtarları güvene alıyoruz (null gelme ihtimaline karşı ??)
          final String fullName = profile['fullName'] ?? 'Değerli Çiftçi';
          final String email = profile['email'] ?? 'Belirtilmemiş';
          final String phone = profile['phone'] ?? 'Belirtilmemiş';
          final String bio = profile['bio'] ?? '';

          // Not: C# tarafı region'u direkt isim olarak mı döndürüyor (regionName) yoksa obje olarak mı emin olmak için ikisine de baktık
          final String region =
              profile['regionName'] ??
              profile['region'] ??
              'Bölge Belirtilmemiş';

          // Avatar için ismin ilk harfini alıyoruz
          final String initial = fullName.isNotEmpty
              ? fullName[0].toUpperCase()
              : 'Ç';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // --- AVATAR KISMI ---
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.green,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 50,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- İSİM ---
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 30),

                // --- BİLGİ KARTLARI ---
                _buildProfileItem(Icons.email, "E-posta", email),
                const SizedBox(height: 15),
                _buildProfileItem(Icons.phone, "Telefon Numarası", phone),
                const SizedBox(height: 15),
                _buildProfileItem(Icons.map, "Kayıtlı Bölge", region),

                const SizedBox(height: 40),

                // --- DÜZENLE BUTONU ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final bool? guncellendiMi = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            currentName: fullName,
                            currentPhone: phone,
                            currentEmail: email,
                            currentBio:
                                bio, // BİYOGRAFİYİ DE YOLLUYORUZ Kİ KUTU DOLU GELSİN!
                          ),
                        ),
                      );

                      if (guncellendiMi == true) {
                        setState(() {
                          _userProfile = _apiService.getUserProfile();
                        });
                      }
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      "PROFİLİ DÜZENLE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Bilgi kutucuklarını çizen yardımcı tasarım kodumuz
  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 30),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
