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
    _futureFields = _apiService.getFarmFields();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("Tarlalarım Listesi"),
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
                      "Henüz hiç tarla eklememişsiniz veya tümünü sildiniz.",
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Sağ alttaki butona tıklayarak yeni tarlanızı sisteme kaydedebilirsiniz! 🌱",
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
                  // --- İŞTE YENİ DÜZENLE VE SİL BUTONLARIMIZ ---
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                        ),
                        tooltip: "Tarlayı Düzenle",
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Tarla düzenleme formu eklenecek! ✏️",
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: "Tarlayı Arşive Kaldır",
                        onPressed: () =>
                            _confirmDelete(context, tarla.id), // Silme onayı!
                      ),
                    ],
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
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFieldScreen()),
          );
          // İleri geri yapmadan otomatik yenileme
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

  // --- TARLA SİLME ONAY PENCERESİ VE İŞLEMİ ---
  void _confirmDelete(BuildContext context, int farmFieldId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Emin misiniz?"),
          ],
        ),
        content: const Text(
          "Bu tarlayı silmek istediğinize emin misiniz? Tarla silindiğinde finans ve sulama kayıtlarınız da arşivlenir (veri kaybı yaşanmaz).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Uyarıyı kapat

              try {
                String? error = await _apiService.deleteFarmField(farmFieldId);

                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Tarla başarıyla arşive kaldırıldı! 🗑️"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // ŞARTSIZ, KOŞULSUZ LİSTEYİ ANINDA YENİLE!
                  setState(() {
                    _futureFields = _apiService.getFarmFields();
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Bağlantı Hatası: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              "Evet, Sil",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
