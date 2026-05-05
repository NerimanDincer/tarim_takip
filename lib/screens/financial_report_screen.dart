import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../services/api_service.dart';
import 'add_transaction_screen.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final ApiService _apiService = ApiService();

  // Artık sadece tek bir kuryemiz var! Raporu kendimiz hesaplayacağız.
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() {
    _transactionsFuture = _fetchAllTransactions();
  }

  // --- TERTEMİZ VERİLERİ TOPLAYAN BEYİN ---
  Future<List<Map<String, dynamic>>> _fetchAllTransactions() async {
    final tarlalar = await _apiService.getFarmFields();
    if (tarlalar.isEmpty) return [];

    List<Map<String, dynamic>> allTransactions = [];

    for (var tarla in tarlalar) {
      // 1. Giderler
      final expenses = await _apiService.getExpenses(tarla.id);
      for (var e in expenses) {
        allTransactions.add({
          'id': e['id'] ?? e['Id'] ?? 0,
          'isExpense': true,
          'title': e['costType'] ?? 'Gider',
          'amount': e['amount']?.toString() ?? '0',
          'date': e['date'] ?? '',
          'note': e['note'] ?? 'Belirtilmemiş',
          'tarlaAdi': tarla.name,
        });
      }

      // 2. Gelirler
      final sales = await _apiService.getSales(tarla.id);
      for (var s in sales) {
        allTransactions.add({
          'id': s['id'] ?? s['Id'] ?? 0,
          'isExpense': false,
          'title': '${tarla.name} Satışı',
          'amount': s['totalPrice']?.toString() ?? '0',
          'date': s['date'] ?? '',
          'note': '${s['amountKg']} KG satıldı.',
          'tarlaAdi': tarla.name,
        });
      }
    }

    // 3. Tarihe göre sırala
    allTransactions.sort((a, b) {
      if (a['date'].isEmpty) return 1;
      if (b['date'].isEmpty) return -1;
      DateTime dateA = DateTime.parse(a['date']);
      DateTime dateB = DateTime.parse(b['date']);
      return dateB.compareTo(dateA);
    });

    return allTransactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Finans ve Rapor"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Raporu İndir',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "PDF Sezon Sonu Raporu oluşturma çok yakında! 📄",
                  ),
                  backgroundColor: Colors.blueGrey,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          ).then((value) {
            setState(() {
              _loadAllData(); // Şartsız, koşulsuz anında yenile!
            });
          });
        },
        backgroundColor: Colors.blueGrey,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("İşlem Ekle", style: TextStyle(color: Colors.white)),
      ),
      // --- İŞTE YENİ TEKİL FUTURE BUILDER'IMIZ ---
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Hata oluştu: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final list = snapshot.data!;

          // --- BÜTÇEYİ LİSTEDEN CANLI OLARAK HESAPLIYORUZ (Sıfır Hata!) ---
          double totalIncome = 0;
          double totalExpense = 0;

          for (var item in list) {
            double amount = double.tryParse(item['amount'].toString()) ?? 0;
            if (item['isExpense'] == true) {
              totalExpense += amount;
            } else {
              totalIncome += amount;
            }
          }
          double netProfit = totalIncome - totalExpense;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 100.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Genel Finansal Durum",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  "(Grafikleri görmek için yana kaydırın)",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 250,
                  child: PageView(
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          sections: _buildChartSections(
                            totalIncome,
                            totalExpense,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: _buildBarChart(
                          totalIncome,
                          totalExpense,
                          netProfit,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                _buildInfoCard(
                  Icons.arrow_upward,
                  "Toplam Gelir",
                  totalIncome,
                  Colors.green,
                ),
                const SizedBox(height: 15),
                _buildInfoCard(
                  Icons.arrow_downward,
                  "Toplam Gider",
                  totalExpense,
                  Colors.red,
                ),
                const SizedBox(height: 15),
                _buildInfoCard(
                  Icons.account_balance_wallet,
                  "Net Kâr",
                  netProfit,
                  netProfit >= 0 ? Colors.blue : Colors.orange,
                ),

                const SizedBox(height: 30),

                // LİSTEYİ DOĞRUDAN ÇİZİYORUZ
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  child: Text(
                    "Son İşlemler",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isExpense = item['isExpense'] == true;

                    String formattedDate = "Tarih Yok";
                    if (item['date'] != null &&
                        item['date'].toString().isNotEmpty) {
                      DateTime d = DateTime.parse(item['date']);
                      formattedDate = DateFormat('dd.MM.yyyy').format(d);
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isExpense
                              ? Colors.red[100]
                              : Colors.green[100],
                          child: Icon(
                            isExpense ? Icons.money_off : Icons.attach_money,
                            color: isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(
                          item['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          "Tarla: ${item['tarlaAdi']}\nTarih: $formattedDate",
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.blueGrey,
                          ),
                          onPressed: () => _showTransactionDetails(
                            context,
                            item,
                            formattedDate,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    Map<String, dynamic> item,
    String formattedDate,
  ) {
    final isExpense = item['isExpense'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
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
                    Icon(
                      isExpense
                          ? Icons.money_off
                          : Icons.account_balance_wallet,
                      color: Colors.blueGrey,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "İşlem Detayı",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30, thickness: 1),
                _buildDetailRow(
                  Icons.calendar_today,
                  "İşlem Tarihi:",
                  formattedDate,
                ),
                const SizedBox(height: 15),
                _buildDetailRow(
                  Icons.monetization_on,
                  isExpense ? "Masraf Tutarı:" : "Gelir Tutarı:",
                  "${item['amount']} ₺",
                ),
                const SizedBox(height: 15),
                _buildDetailRow(Icons.grass, "İlgili Tarla:", item['tarlaAdi']),
                const SizedBox(height: 15),
                _buildDetailRow(Icons.notes, "Ek Not:", item['note']),

                const SizedBox(height: 30),
                // BUTONLAR
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
                        onPressed: () => _confirmDelete(context, item),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> item) {
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
          "Bu finansal kaydı silmek istediğinize emin misiniz? Bu işlem bütçe grafiklerinizi güncelleyecektir.",
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

              int recordId = int.tryParse(item['id'].toString()) ?? 0;
              if (recordId == 0) return;

              try {
                String? error;
                if (item['isExpense'] == true) {
                  error = await _apiService.deleteExpense(recordId);
                } else {
                  error = await _apiService.deleteSale(recordId);
                }

                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Kayıt başarıyla çöp kutusuna taşındı! 🗑️",
                      ),
                      backgroundColor: Colors.blueGrey,
                    ),
                  );
                  setState(() {
                    _loadAllData();
                  }); // GİR-ÇIK YAPMADAN ANINDA YENİLER!
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

  // --- GRAFİKLER VE KARTLAR ---
  Widget _buildBarChart(double income, double expense, double profit) {
    double maxY = [income, expense, profit.abs()].reduce(max) * 1.2;
    if (maxY == 0) maxY = 100;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text(
                      'Gelir',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  case 1:
                    return const Text(
                      'Gider',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  case 2:
                    return const Text(
                      'Kâr',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: income,
                color: Colors.green,
                width: 30,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: expense,
                color: Colors.redAccent,
                width: 30,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: profit,
                color: profit >= 0 ? Colors.blue : Colors.orange,
                width: 30,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(double income, double expense) {
    return [
      PieChartSectionData(
        color: Colors.green,
        value: income,
        title: 'Gelir\n%${_calculatePercentage(income, income + expense)}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.redAccent,
        value: expense,
        title: 'Gider\n%${_calculatePercentage(expense, income + expense)}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  String _calculatePercentage(double value, double total) {
    if (total == 0) return "0";
    return ((value / total) * 100).toStringAsFixed(1);
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    double amount,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        trailing: Text(
          "${amount.toStringAsFixed(2)} ₺",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.pie_chart_outline, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            "Henüz hiç gelir veya gider girmediniz.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 10),
          Text(
            "Finansal durumunuzu görmek için \nişlem eklemeye başlayın! 🌾",
            style: TextStyle(fontSize: 14, color: Colors.blueGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
