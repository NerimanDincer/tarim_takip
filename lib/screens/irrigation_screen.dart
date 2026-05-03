import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/farm_field_model.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  int? _secilenTarlaId; // Artık isim değil, ID tutuyoruz
  List<FarmField> _tarlalarim = []; // Gerçek tarlalar buraya gelecek
  bool _isLoadingFields = true; // Tarlalar yüklenirken dönecek çark
  bool _isSaving = false; // Kaydet butonuna basılınca dönecek çark

  final TextEditingController _miktarController = TextEditingController();
  final TextEditingController _notController = TextEditingController();
  DateTime _secilenTarih = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFields(); // Sayfa açılır açılmaz kullanıcının gerçek tarlalarını çek!
  }

  Future<void> _loadFields() async {
    try {
      var fields = await _apiService.getFarmFields();
      setState(() {
        _tarlalarim = fields;
        _isLoadingFields = false;
      });
    } catch (e) {
      setState(() => _isLoadingFields = false);
    }
  }

  Future<void> _tarihSec(BuildContext context) async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: _secilenTarih,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (secilen != null && secilen != _secilenTarih) {
      setState(() {
        _secilenTarih = secilen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Sulama Kaydı Ekle"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingFields
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          // EĞER LİSTE BOŞSA BU ŞIK UYARI ÇIKACAK:
          : _tarlalarim.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grass, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text(
                      "Henüz kayıtlı bir tarlanız bulunmuyor.",
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Çiftçiyi direkt Tarla Ekleme sayfasına yolluyoruz
                        Navigator.pushReplacementNamed(context, '/add_field');
                        // Not: Eğer route tanımlamadıysan: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AddFieldScreen()));
                      },
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text("Önce Bir Tarla Ekle"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          // TARLA VARSA NORMAL FORM GÖRÜNECEK:
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.water_drop,
                        size: 80,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        "Bitkilerine Can Suyu Ver",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 1. GERÇEK Tarla Seçimi (Dropdown)
                    DropdownButtonFormField<int>(
                      decoration: _buildInput(
                        "Hangi Tarla?",
                        Icons.grass,
                        Colors.blue,
                      ),
                      value: _secilenTarlaId,
                      items: _tarlalarim.map((tarla) {
                        return DropdownMenuItem<int>(
                          value: tarla.id,
                          child: Text(tarla.name),
                        );
                      }).toList(),
                      onChanged: (yeniTarlaId) {
                        setState(() {
                          _secilenTarlaId = yeniTarlaId;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Lütfen sulanan tarlayı seçin' : null,
                    ),
                    const SizedBox(height: 20),

                    // 2. Sulama Miktarı (Litre)
                    TextFormField(
                      controller: _miktarController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInput(
                        "Su Miktarı (Litre)",
                        Icons.waves,
                        Colors.blue,
                      ).copyWith(suffixText: "Litre"),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Lütfen su miktarını girin';
                        if (double.tryParse(value) == null)
                          return 'Sadece rakam girin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 3. Tarih Seçimi
                    InkWell(
                      onTap: () => _tarihSec(context),
                      child: InputDecorator(
                        decoration: _buildInput(
                          "Sulama Tarihi",
                          Icons.calendar_month,
                          Colors.blue,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(_secilenTarih),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Çiftçi Notları
                    TextFormField(
                      controller: _notController,
                      maxLines: 3,
                      decoration: _buildInput(
                        "Notlar (Opsiyonel)",
                        Icons.edit_note,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 5. Kaydet Butonu
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

                                  // API'ye Gönder
                                  bool
                                  isSuccess = await _apiService.createIrrigation(
                                    _secilenTarlaId!,
                                    double.parse(_miktarController.text),
                                    _secilenTarih
                                        .toIso8601String(), // C# API'nin sevdiği tarih formatı
                                    _notController.text,
                                  );

                                  setState(() => _isSaving = false);

                                  if (isSuccess) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Sulama kaydı başarıyla eklendi! 💧",
                                        ),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                    Navigator.pop(context); // Listeye geri dön
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Kayıt eklenirken bir hata oluştu!",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "KAYDI OLUŞTUR",
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
