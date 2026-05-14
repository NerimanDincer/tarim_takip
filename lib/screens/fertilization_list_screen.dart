import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'add_fertilization_screen.dart'; // Ekleme sayfasına gidecek

class FertilizationListScreen extends StatefulWidget {
  const FertilizationListScreen({super.key});

  @override
  State<FertilizationListScreen> createState() =>
      _FertilizationListScreenState();
}

class _FertilizationListScreenState extends State<FertilizationListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _futureGubrelemeler;

  Future<List<dynamic>> _loadGubrelemeler() async {
    final tarlalar = await _apiService.getFarmFields();
    if (tarlalar.isEmpty) return [];

    List<dynamic> tumGubrelemeler = [];

    for (var tarla in tarlalar) {
      try {
        var gubrelemeler = await _apiService.getFertilizations(tarla.id);
        for (var kayit in gubrelemeler) {
          kayit['tarlaAdi'] = tarla.name;
          tumGubrelemeler.add(kayit);
        }
      } catch (e) {
        // Hata olan tarlayı atla
      }
    }

    // Tarihe göre en yeniden eskiye sırala
    tumGubrelemeler.sort((a, b) {
      DateTime dateA = DateTime.parse(a['date']);
      DateTime dateB = DateTime.parse(b['date']);
      return dateB.compareTo(dateA);
    });

    return tumGubrelemeler;
  }

  @override
  void initState() {
    super.initState();
    _futureGubrelemeler = _loadGubrelemeler();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50], // Tema MOR!
      appBar: AppBar(
        title: const Text('Gübreleme Geçmişi'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureGubrelemeler,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Henüz gübreleme kaydı bulunmuyor. 🌱",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final tumGubrelemeler = snapshot.data!;

          return ListView.builder(
            // İŞTE İSTEDİĞİN O FERAH BOŞLUK (bottom: 90)
            padding: const EdgeInsets.only(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              bottom: 90.0,
            ),
            itemCount: tumGubrelemeler.length,
            itemBuilder: (context, index) {
              final kayit = tumGubrelemeler[index];
              final not = kayit["description"] ?? "Detay belirtilmemiş";
              final tarlaIsmi = kayit["tarlaAdi"] ?? "Bilinmeyen Tarla";
              final int recordId =
                  int.tryParse((kayit["id"] ?? kayit["Id"] ?? 0).toString()) ??
                  0;

              final hamTarih = kayit["date"] ?? "";
              String guzelTarih = "Tarih Yok";
              if (hamTarih.isNotEmpty) {
                DateTime parsedDate = DateTime.parse(hamTarih);
                guzelTarih = DateFormat('dd.MM.yyyy').format(parsedDate);
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.eco, color: Colors.white), // Yaprak İkonu
                  ),
                  title: Text(
                    tarlaIsmi,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Kullanılan: $not"),
                      const SizedBox(height: 4),
                      Text(
                        "Tarih: $guzelTarih",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.purple,
                      size: 28,
                    ),
                    onPressed: () => _detayPenceresiGoster(
                      context,
                      guzelTarih,
                      not,
                      tarlaIsmi,
                      recordId,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddFertilizationScreen(),
            ),
          ).then((value) {
            setState(() {
              _futureGubrelemeler = _loadGubrelemeler();
            });
          });
        },
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Yeni Gübreleme",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- ALTTAN AÇILAN DETAY PENCERESİ ---
  void _detayPenceresiGoster(
    BuildContext context,
    String tarih,
    String not,
    String tarlaAdi,
    int recordId,
  ) {
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
                    Icon(Icons.eco, color: Colors.purple, size: 30),
                    SizedBox(width: 10),
                    Text(
                      "Gübreleme Detayı",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                _detaySatiri(Icons.landscape, "Uygulanan Tarla:", tarlaAdi),
                const SizedBox(height: 15),
                _detaySatiri(Icons.calendar_today, "İşlem Tarihi:", tarih),
                const SizedBox(height: 15),
                _detaySatiri(Icons.science, "Gübre Tipi / Detay:", not),
                const SizedBox(height: 30),

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
                        onPressed: () => _confirmDelete(context, recordId),
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

  void _confirmDelete(BuildContext context, int recordId) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
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
          "Bu gübreleme kaydını silmek istediğinize emin misiniz?",
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
              Navigator.pop(context);
              if (recordId == 0) return;
              try {
                String? error = await _apiService.deleteFertilization(recordId);
                if (error == null) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text("Kayıt başarıyla silindi! 🗑️"),
                      backgroundColor: Colors.purple,
                    ),
                  );
                  setState(() {
                    _futureGubrelemeler = _loadGubrelemeler();
                  });
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                scaffoldMessenger.showSnackBar(
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
