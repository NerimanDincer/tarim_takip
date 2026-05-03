import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AddFieldScreen extends StatefulWidget {
  const AddFieldScreen({super.key});

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // MUHTEŞEM BÖLGE-ŞEHİR-İLÇE HARİTASI (İstediğin kadar genişletebilirsin)
  final Map<String, Map<String, List<String>>> _turkiyeVerisi = {
    "Akdeniz Bölgesi": {
      "Antalya": [
        "Kepez",
        "Muratpaşa",
        "Konyaaltı",
        "Kaş",
        "Alanya",
        "Kumluca",
      ],
      "Mersin": ["Tarsus", "Mezitli", "Akdeniz", "Yenişehir"],
      "Adana": ["Seyhan", "Yüreğir", "Çukurova", "Sarıçam"],
    },
    "Ege Bölgesi": {
      "İzmir": ["Bornova", "Karşıyaka", "Buca", "Çeşme", "Urla"],
      "Muğla": ["Bodrum", "Fethiye", "Marmaris", "Milas"],
      "Aydın": ["Menteşe", "Kuşadası", "Didim"],
    },
    "İç Anadolu Bölgesi": {
      "Ankara": ["Çankaya", "Keçiören", "Yenimahalle", "Etimesgut"],
      "Konya": ["Selçuklu", "Meram", "Karatay"],
    },
    // Not: API'deki Bölge isimleriyle ("Akdeniz Bölgesi" gibi) buradakiler aynı olmalı.
  };

  List<dynamic> _gercekBolgeler = [];
  bool _isLoadingRegions = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _soilInfoController = TextEditingController();
  final TextEditingController _plantNameController = TextEditingController();

  String? _secilenBolgeAdi; // Seçilen bölgenin metin hali
  int? _secilenBolgeId;
  String? _secilenSehir;
  String? _secilenIlce;
  DateTime _sowingDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      var bolgeler = await _apiService.getRegions();
      setState(() {
        _gercekBolgeler = bolgeler;
        _isLoadingRegions = false;
      });
    } catch (e) {
      setState(() => _isLoadingRegions = false);
    }
  }

  Future<void> _tarihSec(BuildContext context) async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: _sowingDate,
      firstDate: DateTime(2000), // Geçmişe dönük izin
      lastDate:
          DateTime.now(), // GELECEĞİ SEÇMEYİ ENGELLEDİK! (Madde 2 Çözüldü)
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    if (secilen != null) {
      setState(() => _sowingDate = secilen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("Yeni Tarla Kaydı"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingRegions
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.landscape, size: 80, color: Colors.green),
                    const SizedBox(height: 30),

                    _buildTextField(
                      _nameController,
                      "Tarla Adı (Örn: Dededen Kalma)",
                      Icons.badge,
                    ),
                    const SizedBox(height: 15),

                    // 1. BÖLGE SEÇİMİ
                    DropdownButtonFormField<int>(
                      decoration: _buildInputDecoration(
                        "Bölge Seçimi",
                        Icons.map,
                      ),
                      value: _secilenBolgeId,
                      items: _gercekBolgeler.map((bolge) {
                        return DropdownMenuItem<int>(
                          value: bolge['id'],
                          child: Text(bolge['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _secilenBolgeId = val;
                          // API'den gelen listeden bölgenin adını buluyoruz (örn: "Akdeniz Bölgesi")
                          final bolge = _gercekBolgeler.firstWhere(
                            (b) => b['id'] == val,
                          );
                          _secilenBolgeAdi = bolge['name'];

                          // Alt kısımları sıfırla ki hata vermesin
                          _secilenSehir = null;
                          _secilenIlce = null;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Bölge seçmelisiniz' : null,
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        // 2. ŞEHİR SEÇİMİ (Seçilen Bölgeye Göre Gelir)
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: _buildInputDecoration(
                              "Şehir",
                              Icons.location_city,
                            ),
                            value: _secilenSehir,
                            items:
                                _secilenBolgeAdi == null ||
                                    !_turkiyeVerisi.containsKey(
                                      _secilenBolgeAdi,
                                    )
                                ? [] // Eğer bölge seçilmediyse veya haritamızda yoksa boş liste göster
                                : _turkiyeVerisi[_secilenBolgeAdi]!.keys
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                            onChanged: (val) => setState(() {
                              _secilenSehir = val;
                              _secilenIlce =
                                  null; // Şehir değişince ilçeyi sıfırla
                            }),
                            validator: (value) =>
                                value == null ? 'Seçiniz' : null,
                          ),
                        ),
                        const SizedBox(width: 15),

                        // 3. İLÇE SEÇİMİ (Seçilen Şehre Göre Gelir)
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: _buildInputDecoration(
                              "İlçe",
                              Icons.pin_drop,
                            ),
                            value: _secilenIlce,
                            items:
                                _secilenSehir == null ||
                                    _secilenBolgeAdi == null
                                ? []
                                : _turkiyeVerisi[_secilenBolgeAdi]![_secilenSehir]!
                                      .map(
                                        (i) => DropdownMenuItem(
                                          value: i,
                                          child: Text(i),
                                        ),
                                      )
                                      .toList(),
                            onChanged: (val) =>
                                setState(() => _secilenIlce = val),
                            validator: (value) =>
                                value == null ? 'Seçiniz' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _areaController,
                            "Dönüm",
                            Icons.straighten,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            _soilInfoController,
                            "Toprak Türü",
                            Icons.layers,
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Colors.green),
                    ),

                    _buildTextField(
                      _plantNameController,
                      "Ekilen Ürün (Örn: Domates)",
                      Icons.local_florist,
                    ),
                    const SizedBox(height: 15),

                    InkWell(
                      onTap: () => _tarihSec(context),
                      child: InputDecorator(
                        decoration: _buildInputDecoration(
                          "Ekim Tarihi",
                          Icons.calendar_today,
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_sowingDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // KAYDET BUTONU
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  FocusScope.of(context).unfocus();
                                  setState(() => _isSaving = true);

                                  bool isSuccess = await _apiService
                                      .createFarmField(
                                        _nameController.text.trim(),
                                        _secilenSehir!,
                                        _secilenIlce!,
                                        _secilenBolgeId!,
                                        _plantNameController.text.trim(),
                                        _sowingDate.toIso8601String(),
                                        double.tryParse(_areaController.text) ??
                                            0.0,
                                        _soilInfoController.text.trim(),
                                      );

                                  setState(() => _isSaving = false);

                                  if (isSuccess) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Tarla başarıyla eklendi! 🌱",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Tarla kaydedilirken bir hata oluştu!",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "KAYDET",
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: _buildInputDecoration(label, icon),
      validator: (value) =>
          value == null || value.isEmpty ? 'Boş bırakılamaz' : null,
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
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
