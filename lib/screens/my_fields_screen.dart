import 'package:flutter/material.dart';
import 'add_field_screen.dart';
import '../services/api_service.dart';
import '../models/farm_field_model.dart';

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
    // Sayfa açılır açılmaz gerçek tarlaları API'den çekiyoruz
    _futureFields = _apiService.getFarmFields();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // Kahverengi gitti, Yeşil geldi!
      appBar: AppBar(
        title: const Text("Tarlalarım Listesi"),
        backgroundColor: Colors.green, // Kahverengi gitti, Yeşil geldi!
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
            // HİÇ TARLA YOKSA GÖRÜNECEK ŞIK UYARI!
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
          }

          final tarlalar = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: tarlalar.length,
            itemBuilder: (context, index) {
              final tarla = tarlalar[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.landscape, color: Colors.green),
                  ),
                  title: Text(
                    tarla.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.straighten,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text("${tarla.area} Dönüm"),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.local_florist,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(tarla.plantName),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${tarla.city} / ${tarla.county}",
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.green,
                    size: 16,
                  ),
                  onTap: () {
                    // İleride tarlanın detaylarına veya masraf/satış sayfalarına gitmek için bilet keseceğimiz yer
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // AWAIT kelimesi hayat kurtarır! Sayfanın kapanmasını ve işlemin bitmesini kesin olarak bekler.
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFieldScreen()),
          );

          // Sayfa kapandıktan HEMEN SONRA bu kod çalışır ve listeyi günceller!
          setState(() {
            _futureFields = _apiService.getFarmFields();
          });
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Yeni Tarla Ekle",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
