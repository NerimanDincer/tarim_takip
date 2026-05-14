import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/farm_field_model.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isExpense = true;
  bool _isLoading = false;

  List<FarmField> _fields = [];
  FarmField? _selectedField;

  // --- YENİ: TAKVİM İÇİN TARİH DEĞİŞKENİ ---
  DateTime _selectedDate = DateTime.now();

  String _selectedCostType = 'Gübre';
  final List<String> _costTypes = [
    'Gübre',
    'Tohum',
    'Fidan',
    'İlaç',
    'Yakıt',
    'İşçilik',
    'Diğer',
  ];
  final TextEditingController _expenseAmountController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final TextEditingController _kgController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final fields = await _apiService.getFarmFields();
      setState(() {
        _fields = fields;
        if (_fields.isNotEmpty) _selectedField = _fields.first;
      });
    } catch (e) {}
  }

  // --- YENİ: TAKVİM AÇMA FONKSİYONU ---
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), // En eski 2020 yılına gidilebilir
      lastDate: DateTime.now(), // Gelecek tarihe işlem girilemesin
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueGrey,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Yeni İşlem Ekle"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: _fields.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isExpense
                                  ? Colors.red
                                  : Colors.grey[300],
                              foregroundColor: _isExpense
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onPressed: () => setState(() => _isExpense = true),
                            child: const Text("Masraf/Gider Ekle"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_isExpense
                                  ? Colors.green
                                  : Colors.grey[300],
                              foregroundColor: !_isExpense
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onPressed: () => setState(() => _isExpense = false),
                            child: const Text("Satış/Gelir Ekle"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- TARLA SEÇİMİ ---
                    DropdownButtonFormField<FarmField>(
                      value: _selectedField,
                      decoration: const InputDecoration(
                        labelText: "Hangi Tarla İçin?",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.grass, color: Colors.blueGrey),
                      ),
                      items: _fields
                          .map(
                            (field) => DropdownMenuItem(
                              value: field,
                              child: Text(field.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedField = val),
                    ),
                    const SizedBox(height: 20),

                    // --- YENİ: TARİH SEÇİM BUTONU ---
                    InkWell(
                      onTap: () => _pickDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'İşlem Tarihi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.calendar_month,
                            color: Colors.blueGrey,
                          ),
                        ),
                        child: Text(
                          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_isExpense) _buildExpenseForm() else _buildSaleForm(),
                    const SizedBox(height: 40),

                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "KAYDET",
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

  Widget _buildExpenseForm() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCostType,
          decoration: const InputDecoration(
            labelText: "Masraf Türü",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category, color: Colors.red),
          ),
          items: _costTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (val) => setState(() => _selectedCostType = val!),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _expenseAmountController,
          keyboardType:
              TextInputType.number, // Telefonda sadece rakam klavyesini açar
          validator: (value) {
            if (value == null || value.isEmpty) return 'Tutar giriniz';
            // Eğer kullanıcı inatla harf girerse çökmesin, bu uyarıyı versin:
            if (double.tryParse(value) == null)
              return 'Lütfen sadece geçerli bir sayı girin!';
            return null;
          },
          decoration: const InputDecoration(
            labelText: "Tutar (₺)",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.money_off, color: Colors.red),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: "Açıklama / Not",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleForm() {
    return Column(
      children: [
        TextFormField(
          controller: _kgController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Satılan Miktar (KG)",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.scale, color: Colors.green),
          ),
          validator: (val) => val!.isEmpty ? 'KG giriniz' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Kilo Fiyatı (₺)",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money, color: Colors.green),
          ),
          validator: (val) => val!.isEmpty ? 'Fiyat giriniz' : null,
        ),
      ],
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate() || _selectedField == null) return;
    setState(() => _isLoading = true);

    String? error;
    // YENİ: C#'ın tam istediği Saat/Zaman formatı (UTC)
    // Seçilen gün, ay, yıla; şu anki saati ve dakikayı ekliyoruz!
    DateTime now = DateTime.now();
    DateTime finalDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    String formattedDate = finalDate.toUtc().toIso8601String();

    if (_isExpense) {
      error = await _apiService.addExpense(
        _selectedField!.id,
        _selectedCostType,
        double.parse(_expenseAmountController.text.replaceAll(',', '.')),
        _noteController.text,
        formattedDate, // Tarihi ekledik!
      );
    } else {
      error = await _apiService.addSale(
        _selectedField!.id,
        double.parse(_kgController.text.replaceAll(',', '.')),
        double.parse(_priceController.text.replaceAll(',', '.')),
        formattedDate, // Tarihi ekledik!
      );
    }

    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("İşlem başarıyla eklendi! ✅"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }
}
