import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'irrigation_screen.dart';
import '../services/api_service.dart';

class IrrigationListScreen extends StatefulWidget {
  const IrrigationListScreen({super.key});

  @override
  State<IrrigationListScreen> createState() => _IrrigationListScreenState();
}

class _IrrigationListScreenState extends State<IrrigationListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _futureSulamalar;

  Future<List<dynamic>> _loadSulamalar() async {
    final tarlalar = await _apiService.getFarmFields();
    if (tarlalar.isEmpty) return [];

    List<dynamic> tumSulamalar = [];

    for (var tarla in tarlalar) {
      try {
        var sulamalar = await _apiService.getIrrigations(tarla.id);
        for (var kayit in sulamalar) {
          kayit['tarlaAdi'] = tarla.name;
          tumSulamalar.add(kayit);
        }
      } catch (e) {
        // Hata olan tarlayı atla
      }
    }

    tumSulamalar.sort((a, b) {
      DateTime dateA = DateTime.parse(a['date']);
      DateTime dateB = DateTime.parse(b['date']);
      return dateB.compareTo(dateA);
    });

    return tumSulamalar;
  }

  @override
  void initState() {
    super.initState();
    _futureSulamalar = _loadSulamalar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Sulama Geçmişi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureSulamalar,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Henüz sulama kaydı bulunmuyor."));
          }

          final tumSulamalar = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tumSulamalar.length,
            itemBuilder: (context, index) {
              final kayit = tumSulamalar[index];
              final miktar = kayit["litersUsed"]?.toString() ?? "0";
              final not = kayit["description"] ?? "Not eklenmemiş";
              final tarlaIsmi = kayit["tarlaAdi"] ?? "Bilinmeyen Tarla";

              // SİLMEK İÇİN ID'Yİ GÜVENLİ BİR ŞEKİLDE ALIYORUZ
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
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.water_drop, color: Colors.white),
                  ),
                  title: Text(
                    "$miktar Litre Su Verildi",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Tarih: $guzelTarih"),
                  trailing: const Icon(Icons.info_outline, color: Colors.blue),
                  onTap: () {
                    _detayPenceresiGoster(
                      context,
                      guzelTarih,
                      miktar,
                      not,
                      recordId,
                    );
                  },
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
            MaterialPageRoute(builder: (context) => const IrrigationScreen()),
          ).then((value) {
            // ŞARTSIZ, KOŞULSUZ LİSTEYİ YENİLE!
            setState(() {
              _futureSulamalar = _loadSulamalar();
            });
          });
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Yeni Kayıt",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _detayPenceresiGoster(
    BuildContext context,
    String tarih,
    String miktar,
    String not,
    int recordId, // ID parametresi eklendi
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
                Row(
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blue, size: 30),
                    const SizedBox(width: 10),
                    const Text(
                      "Sulama Detayı",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                _detaySatiri(Icons.calendar_today, "İşlem Tarihi:", tarih),
                const SizedBox(height: 15),
                _detaySatiri(Icons.science, "Su Miktarı:", "$miktar Litre"),
                const SizedBox(height: 15),
                _detaySatiri(Icons.edit_note, "Ek Not:", not),
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
                        onPressed: () =>
                            _confirmDelete(context, recordId), // Silme onayı!
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
                                "Düzenleme formu bir sonraki adımda eklenecek! ✏️",
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

  // SİLME ONAYI VE GERÇEKLEŞTİRME
  void _confirmDelete(BuildContext context, int recordId) {
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
          "Bu sulama kaydını silmek istediğinize emin misiniz?",
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
                String? error = await _apiService.deleteIrrigation(recordId);

                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Kayıt başarıyla silindi! 🗑️"),
                      backgroundColor: Colors.blueGrey,
                    ),
                  );
                  // İŞTE İLERİ-GERİ YAPMADAN ANINDA YENİLEYEN KOD:
                  setState(() {
                    _futureSulamalar = _loadSulamalar();
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
}
