import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/farm_field_model.dart';

class EditFieldScreen extends StatefulWidget {
  final FarmField tarla;
  const EditFieldScreen({super.key, required this.tarla});

  @override
  State<EditFieldScreen> createState() => _EditFieldScreenState();
}

class _EditFieldScreenState extends State<EditFieldScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _countyController;
  late TextEditingController _plantController;
  late TextEditingController _areaController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Kutuların içini eski verilerle dolduruyoruz!
    _nameController = TextEditingController(text: widget.tarla.name);
    _cityController = TextEditingController(text: widget.tarla.city);
    _countyController = TextEditingController(text: widget.tarla.county);
    _plantController = TextEditingController(text: widget.tarla.plantName);
    _areaController = TextEditingController(text: widget.tarla.area.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Tarlayı Düzenle'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_nameController, 'Tarla Adı', Icons.landscape),
              const SizedBox(height: 15),
              _buildTextField(_cityController, 'İl', Icons.location_city),
              const SizedBox(height: 15),
              _buildTextField(_countyController, 'İlçe', Icons.map),
              const SizedBox(height: 15),
              _buildTextField(
                _plantController,
                'Ekili Ürün',
                Icons.local_florist,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _areaController,
                'Büyüklük (Dönüm)',
                Icons.straighten,
                isNumber: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isSaving = true);

                            Map<String, dynamic> updatedData = {
                              "name": _nameController.text,
                              "city": _cityController.text,
                              "county": _countyController.text,
                              "plantName": _plantController.text,
                              "area":
                                  double.tryParse(_areaController.text) ?? 0,
                              "soilInfo":
                                  "Belirtilmedi", // Modelde olmadığı için sabit değer gönderiyoruz
                              "regionId":
                                  1, // Sistem hata vermesin diye varsayılan bölge ID'si
                              "sowingDate": DateTime.now()
                                  .toIso8601String(), // Bugünün tarihi
                            };

                            bool basarili = await _apiService.updateFarmField(
                              widget.tarla.id,
                              updatedData,
                            );
                            setState(() => _isSaving = false);

                            if (basarili) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tarla güncellendi! ✅'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(
                                context,
                                true,
                              ); // True döndürerek sayfanın yenilenmesini tetikleyeceğiz
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Güncelleme başarısız!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'KAYDET',
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value!.isEmpty ? 'Boş bırakılamaz' : null,
    );
  }
}
