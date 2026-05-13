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
        title: const Text("Tarlalarım Listesi DENEMEEEEEE"),
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
            return _buildEmptyState();
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
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.green,
                      size: 28,
                    ),
                    onPressed: () => _detayPenceresiGoster(
                      context,
                      tarla,
                    ), // Butona basınca detaylar açılacak!
                  ),
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

  // BOŞ EKRAN TASARIMI
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.grass, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "Henüz hiç tarla eklememişsiniz veya tümünü sildiniz.",
              style: TextStyle(fontSize: 18, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              "Sağ alttaki butona tıklayarak yeni tarlanızı sisteme kaydedebilirsiniz! 🌱",
              style: TextStyle(fontSize: 14, color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- SULAMA VE FİNANSTAKİ GİBİ ALTTAN AÇILAN DETAY PENCERESİ ---
  void _detayPenceresiGoster(BuildContext context, FarmField tarla) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.landscape, color: Colors.green, size: 30),
                    SizedBox(width: 10),
                    Text(
                      "Tarla Detayı",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),

                _detaySatiri(Icons.label_outline, "Tarla Adı:", tarla.name),
                const SizedBox(height: 15),
                _detaySatiri(
                  Icons.straighten,
                  "Büyüklük:",
                  "${tarla.area} Dönüm",
                ),
                const SizedBox(height: 15),
                _detaySatiri(
                  Icons.local_florist,
                  "Ekili Ürün:",
                  tarla.plantName,
                ),
                const SizedBox(height: 15),
                _detaySatiri(
                  Icons.location_on,
                  "Konum:",
                  "${tarla.city} / ${tarla.county}",
                ),

                const SizedBox(height: 30),
                // --- SİL, DÜZENLE VE KAPAT BUTONLARI YAN YANA ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text(
                          "Sil",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _confirmDelete(context, tarla.id),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text(
                          "Düzenle",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Tarla düzenleme formu eklenecek! ✏️",
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detaySatiri(IconData ikon, String baslik, String deger) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ikon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 10),
        Text(baslik, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            deger,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
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
              Navigator.pop(ctx);
              Navigator.pop(context); // Detay penceresini de kapat

              try {
                String? error = await _apiService.deleteFarmField(farmFieldId);

                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Tarla başarıyla arşive kaldırıldı! 🗑️"),
                      backgroundColor: Colors.green,
                    ),
                  );
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
