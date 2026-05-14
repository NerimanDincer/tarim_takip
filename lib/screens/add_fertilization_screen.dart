import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/farm_field_model.dart';

class AddFertilizationScreen extends StatefulWidget {
  const AddFertilizationScreen({super.key});

  @override
  State<AddFertilizationScreen> createState() => _AddFertilizationScreenState();
}

class _AddFertilizationScreenState extends State<AddFertilizationScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  int? _selectedFarmFieldId;
  List<FarmField> _farmFields = [];
  bool _isLoadingFields = true;
  bool _isSaving = false;

  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final TextEditingController _detayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final fields = await _apiService.getFarmFields();
      setState(() {
        _farmFields = fields;
        if (fields.isNotEmpty) _selectedFarmFieldId = fields.first.id;
        _isLoadingFields = false;
      });
    } catch (e) {
      setState(() => _isLoadingFields = false);
    }
  }

  Future<void> _tarihSec(BuildContext context) async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.purple, // Takvim Rengi
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (secilen != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(secilen);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        title: const Text('Yeni Gübreleme Ekle'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingFields
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarla Seçimi
                    DropdownButtonFormField<int>(
                      value: _selectedFarmFieldId,
                      decoration: InputDecoration(
                        labelText: 'İşlem Yapılacak Tarla',
                        prefixIcon: const Icon(
                          Icons.landscape,
                          color: Colors.purple,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _farmFields.map((field) {
                        return DropdownMenuItem(
                          value: field.id,
                          child: Text(field.name),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedFarmFieldId = val),
                      validator: (value) =>
                          value == null ? 'Lütfen bir tarla seçin' : null,
                    ),
                    const SizedBox(height: 20),

                    // Tarih Seçimi
                    InkWell(
                      onTap: () => _tarihSec(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Uygulama Tarihi',
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            color: Colors.purple,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        child: Text(
                          DateFormat(
                            'dd.MM.yyyy',
                          ).format(DateTime.parse(_selectedDate)),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gübre Detayı
                    TextFormField(
                      controller: _detayController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Kullanılan Gübre ve Miktarı',
                        hintText: 'Örn: 50 Kg Üre Gübresi atıldı',
                        prefixIcon: const Icon(
                          Icons.science,
                          color: Colors.purple,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Lütfen detay giriniz' : null,
                    ),
                    const SizedBox(height: 40),

                    // Kaydet Butonu
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate() &&
                                    _selectedFarmFieldId != null) {
                                  setState(() => _isSaving = true);
                                  bool basarili = await _apiService
                                      .createFertilization(
                                        _selectedFarmFieldId!,
                                        _selectedDate,
                                        _detayController.text,
                                      );
                                  setState(() => _isSaving = false);

                                  if (basarili) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Gübreleme kaydedildi! 🌱',
                                        ),
                                        backgroundColor: Colors.purple,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Kayıt başarısız oldu.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Kaydet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
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
}
