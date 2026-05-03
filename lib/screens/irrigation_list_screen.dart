import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'irrigation_screen.dart'; // Hatayı düzelttiğimiz dosyanın importu
import '../services/api_service.dart';

class IrrigationListScreen extends StatefulWidget {
  const IrrigationListScreen({super.key});

  @override
  State<IrrigationListScreen> createState() => _IrrigationListScreenState();
}

class _IrrigationListScreenState extends State<IrrigationListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _futureSulamalar;

  // 1. BU FONKSİYONU ESKİSİYLE DEĞİŞTİR:
  Future<List<dynamic>> _loadSulamalar() async {
    final tarlalar = await _apiService.getFarmFields();
    if (tarlalar.isEmpty) return [];

    List<dynamic> tumSulamalar = [];

    // Çiftçinin tüm tarlalarını tek tek dön ve sulamalarını topla!
    for (var tarla in tarlalar) {
      try {
        var sulamalar = await _apiService.getIrrigations(tarla.id);

        // C# API'den tarla adı gelmiyor, biz kendimiz ekliyoruz ki ekranda yazabilelim
        for (var kayit in sulamalar) {
          kayit['tarlaAdi'] = tarla.name;
          tumSulamalar.add(kayit);
        }
      } catch (e) {
        // Hata olan tarlayı atla, diğerlerine devam et
      }
    }

    // Tarihe göre en yeniden en eskiye sırala
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
    _futureSulamalar =
        _loadSulamalar(); // Sabit metod yerine yeni metodumuz çalışıyor
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
              final kayit = tumSulamalar[index]; // Önceden sulamalar yazıyordu

              final miktar = kayit["litersUsed"]?.toString() ?? "0";
              final not = kayit["description"] ?? "Not eklenmemiş";
              final tarlaIsmi =
                  kayit["tarlaAdi"] ??
                  "Bilinmeyen Tarla"; // Tarla ismini çektik

              // Tarihi düzgün bir formata çevirelim
              final hamTarih = kayit["date"] ?? "";
              String guzelTarih = "Tarih Yok";
              if (hamTarih.isNotEmpty) {
                DateTime parsedDate = DateTime.parse(hamTarih);
                guzelTarih = DateFormat(
                  'dd.MM.yyyy - HH:mm',
                ).format(parsedDate);
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
                    _detayPenceresiGoster(context, guzelTarih, miktar, not);
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
            // Yeni kayıt eklenip sayfaya geri dönüldüğünde listeyi güncelle!
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
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
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
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Kapat",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detaySatiri(IconData ikon, String baslik, String deger) {
    return Row(
      children: [
        Icon(ikon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 10),
        Text(baslik, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
        const Spacer(),
        Expanded(
          child: Text(
            deger,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis, // Uzun notlarda taşmayı engeller
          ),
        ),
      ],
    );
  }
}
