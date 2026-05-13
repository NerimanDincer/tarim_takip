import 'package:flutter/material.dart';
import 'models/farm_field_model.dart';
import 'services/api_service.dart';
import 'screens/add_field_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/irrigation_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/irrigation_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/financial_report_screen.dart';

void main() {
  runApp(const TarimTakipApp());
}

class TarimTakipApp extends StatelessWidget {
  const TarimTakipApp({super.key});

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tarım Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            );
          }
          if (snapshot.data == true) {
            return const AnaSayfa();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

// --- DİNAMİK ANA SAYFA BAŞLANGICI ---
class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});
  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = _loadDashboardData();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    try {
      final profile = await _apiService.getUserProfile();
      final tarlalar = await _apiService.getFarmFields();
      List<Map<String, dynamic>> havaDurumlari = [];

      if (tarlalar.isEmpty) {
        String regionName = profile['region'] ?? 'Akdeniz';
        String weatherCity = "Antalya";
        if (regionName.contains("Ege"))
          weatherCity = "İzmir";
        else if (regionName.contains("İç Anadolu"))
          weatherCity = "Ankara";
        else if (regionName.contains("Marmara"))
          weatherCity = "İstanbul";

        final weather = await _apiService.getWeather(weatherCity);
        havaDurumlari.add({
          'weather': weather,
          'cardTitle': "Genel Hava Durumu",
          'city': weatherCity,
        });
      } else {
        for (var tarla in tarlalar) {
          try {
            final weather = await _apiService.getWeather(tarla.city);
            havaDurumlari.add({
              'weather': weather,
              'cardTitle': tarla.name,
              'city': tarla.city,
            });
          } catch (e) {
            // Hata atla
          }
        }
      }
      return {'profile': profile, 'weatherList': havaDurumlari};
    } catch (e) {
      throw Exception("Veriler yüklenirken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tarım Takip')),
            body: Center(child: Text("Hata: ${snapshot.error}")),
          );
        }

        final data = snapshot.data!;
        final profile = data['profile'];
        final List<dynamic> weatherList = data['weatherList'];

        final String fullName = profile['fullName'] ?? 'Değerli Çiftçi';
        final String email = profile['email'] ?? '';
        final String initial = fullName.isNotEmpty
            ? fullName[0].toUpperCase()
            : 'Ç';

        return Scaffold(
          backgroundColor: Colors.green[50],
          appBar: AppBar(
            backgroundColor: Colors.green,
            title: const Text(
              'Tarım Takip Paneli',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.green),
                  accountName: Text(
                    "Hoşgeldin, $fullName!",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.green),
                  title: const Text('Profilim'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note, color: Colors.green),
                  title: const Text('Notlarım & Takvim'),
                  onTap: () => Navigator.pop(context),
                ),

                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Çıkış Yap',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Çıkış Yap"),
                          content: const Text(
                            "Hesabınızdan çıkış yapmak istediğinize emin misiniz?",
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          actions: [
                            TextButton(
                              child: const Text(
                                "İptal",
                                style: TextStyle(color: Colors.grey),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: const Text(
                                "Evet, Çık",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  "Hoşgeldin $fullName! 🚜",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text("Bugün ne yapmak istersin?"),
                const SizedBox(height: 20),

                // --- KAYDIRILABİLİR (PAGEVIEW) HAVA DURUMU KARTLARI ---
                SizedBox(
                  height: 160,
                  child: PageView.builder(
                    itemCount: weatherList.length,
                    itemBuilder: (context, index) {
                      final currentCard = weatherList[index];
                      final weather = currentCard['weather'];
                      final cardTitle = currentCard['cardTitle'];
                      final city = currentCard['city'];

                      final temp =
                          weather['temperature']?.toStringAsFixed(1) ?? '--';
                      final desc = weather['description'] ?? 'Bilinmiyor';

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[200]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          "$cardTitle ($city)",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "$temp°C",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      desc.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.wb_cloudy,
                              color: Colors.white,
                              size: 70,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    weatherList.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                // --- KART BİTİŞİ ---
                const SizedBox(height: 15),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.1,
                    children: [
                      _menuKutu(
                        context,
                        Icons.grass,
                        "Tarlalarım",
                        Colors.green,
                      ),
                      _menuKutu(
                        context,
                        Icons.add_circle,
                        "Ürün Ekle",
                        Colors.orange,
                      ),
                      _menuKutu(
                        context,
                        Icons.water_drop,
                        "Sulama Takibi",
                        Colors.blue,
                      ),
                      _menuKutu(
                        context,
                        Icons.science,
                        "Gübreleme",
                        Colors.purple,
                      ),
                      _menuKutu(
                        context,
                        Icons.calendar_month,
                        "Takvim & Notlar",
                        Colors.red,
                      ),
                      _menuKutu(
                        context,
                        Icons.pie_chart_rounded, // Yepyeni grafik ikonumuz
                        "Finans ve Rapor", // Yeni başlığımız
                        Colors.blueGrey, // Daha kurumsal bir renk
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuKutu(
    BuildContext context,
    IconData icon,
    String baslik,
    Color renk,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          if (baslik == "Tarlalarım") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TarlalarimSayfasi(),
              ),
            ).then((_) {
              // Tarlalarım sayfasından geri dönünce ana sayfayı yenile!
              setState(() {
                _dashboardData = _loadDashboardData();
              });
            });
          } else if (baslik == "Sulama Takibi") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IrrigationListScreen(),
              ),
            );
          } else if (baslik == "Ürün Ekle") {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Ürün Ekle sayfası yakında eklenecek! 🚜"),
              ),
            );
          } else if (baslik == "Finans ve Rapor") {
            // SnackBar'ı sildik, yerine gerçek sayfaya geçişi koyduk!
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FinancialReportScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$baslik sayfası yakında eklenecek! 🚜")),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: renk),
            const SizedBox(height: 10),
            Text(
              baslik,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class TarlalarimSayfasi extends StatefulWidget {
  const TarlalarimSayfasi({super.key});
  @override
  State<TarlalarimSayfasi> createState() => _TarlalarimSayfasiState();
}

class _TarlalarimSayfasiState extends State<TarlalarimSayfasi> {
  final ApiService _apiService = ApiService();
  late Future<List<FarmField>> _futureFields;

  @override
  void initState() {
    super.initState();
    _futureFields = _apiService.getFarmFields();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // Tema bütünlüğü için yeşil yaptık
      appBar: AppBar(
        title: const Text('Tarlalarım Listesi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<FarmField>>(
        future: _futureFields,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grass, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text(
                      "Henüz hiç tarla eklememişsiniz.",
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Sağ alttaki butona tıklayarak ilk tarlanızı sisteme kaydedebilirsiniz! 🌱",
                      style: TextStyle(fontSize: 14, color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                var tarla = snapshot.data![index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: const Icon(Icons.grass, color: Colors.green),
                    ),
                    title: Text(
                      tarla.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${tarla.city} / ${tarla.county} - ${tarla.plantName}",
                    ),
                    trailing: Text("${tarla.area} Dönüm"),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // AWAIT İLE SAYFANIN KAPANMASINI BEKLİYORUZ (YENİLENMEME SORUNU ÇÖZÜLDÜ!)
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFieldScreen()),
          );

          // Geri dönüldüğünde listeyi hemen güncelle!
          setState(() {
            _futureFields = _apiService.getFarmFields();
          });
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
