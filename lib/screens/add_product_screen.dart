import 'package:flutter/material.dart';

class UrunEkleSayfasi extends StatefulWidget {
  const UrunEkleSayfasi({super.key});

  @override
  State<UrunEkleSayfasi> createState() => _UrunEkleSayfasiState();
}

class _UrunEkleSayfasiState extends State<UrunEkleSayfasi> {
  final _formKey = GlobalKey<FormState>();

  // Dedektiflerimiz
  String? _secilenTarla;
  String? _secilenKategori;
  final TextEditingController _urunAdController = TextEditingController();
  final TextEditingController _beklenenTonajController =
      TextEditingController();

  // Sahte Veriler (Dropdown'lar için)
  final List<String> _tarlalarim = [
    "Antalya - Domates Tarlası",
    "Burdur - Ceviz Bahçesi",
    "Mersin - Limonluk",
  ];
  final List<String> _kategoriler = ["Sebze", "Meyve", "Tahıl", "Bakliyat"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50], // Hasat temasına uygun açık turuncu
      appBar: AppBar(
        title: const Text("Yeni Ürün Ekle"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.agriculture, size: 80, color: Colors.orange),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "Tarlana Bereket Kat",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 1. Hangi Tarlaya Ekilecek?
              DropdownButtonFormField<String>(
                decoration: _buildInput(
                  "Hangi Tarlaya Ekilecek?",
                  Icons.grass,
                  Colors.orange,
                ),
                value: _secilenTarla,
                items: _tarlalarim.map((tarla) {
                  return DropdownMenuItem(value: tarla, child: Text(tarla));
                }).toList(),
                onChanged: (yeniTarla) =>
                    setState(() => _secilenTarla = yeniTarla),
                validator: (value) =>
                    value == null ? 'Lütfen bir tarla seçin' : null,
              ),
              const SizedBox(height: 20),

              // 2. Ürün Kategorisi
              DropdownButtonFormField<String>(
                decoration: _buildInput(
                  "Ürün Kategorisi",
                  Icons.category,
                  Colors.orange,
                ),
                value: _secilenKategori,
                items: _kategoriler.map((kategori) {
                  return DropdownMenuItem(
                    value: kategori,
                    child: Text(kategori),
                  );
                }).toList(),
                onChanged: (yeniKategori) =>
                    setState(() => _secilenKategori = yeniKategori),
                validator: (value) =>
                    value == null ? 'Lütfen bir kategori seçin' : null,
              ),
              const SizedBox(height: 20),

              // 3. Ürün Adı (Örn: Sırık Domates)
              TextFormField(
                controller: _urunAdController,
                decoration: _buildInput(
                  "Ürün Adı (Örn: Sırık Domates)",
                  Icons.local_florist,
                  Colors.orange,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Lütfen ürün adını girin' : null,
              ),
              const SizedBox(height: 20),

              // 4. Beklenen Tonaj
              TextFormField(
                controller: _beklenenTonajController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Beklenen Hasat (Ton)",
                  prefixIcon: const Icon(Icons.scale, color: Colors.orange),
                  suffixText: "Ton",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Lütfen tahmini tonajı girin';
                  if (int.tryParse(value) == null)
                    return 'Sadece rakam giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // 5. Kaydet Butonu
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      FocusScope.of(context).unfocus(); // Klavyeyi kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Ürün başarıyla tarlaya eklendi! 🌱"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      Future.delayed(const Duration(seconds: 1), () {
                        Navigator.pop(context); // Ana sayfaya geri fırlat
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "ÜRÜNÜ EKLE",
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

  // Ortak Tasarım Metodu
  InputDecoration _buildInput(String label, IconData icon, Color renk) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: renk),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: renk, width: 2),
      ),
    );
  }
}
