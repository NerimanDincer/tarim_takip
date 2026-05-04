import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farm_field_model.dart';

class ApiService {
  // Backend IP adresin
  static const String baseUrl = 'http://192.168.1.101:5256/api';

  // --- TOKEN OKUMA YARDIMCISI (YENİ) ---
  // Telefonun hafızasındaki token'ı okuyan küçük bir yardımcı fonksiyon
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // --- GİRİŞ YAPMA METODU (GELİŞMİŞ HATA YAKALAYICI) ---
  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          return null; // null dönmesi "Hata yok, giriş başarılı" demek!
        }
        return "Giriş yapıldı ama sistemden anahtar (token) alınamadı.";
      } else {
        // C# API'miz 401 döndüyse gerçek sebebi görelim
        return "E-posta veya şifre hatalı! (Hata Kodu: ${response.statusCode})";
      }
    } catch (e) {
      // BURAYI DEĞİŞTİRDİK! Artık kendi uydurduğumuz mesajı değil, hatanın GERÇEK SEBEBİNİ ekrana basacağız.
      print('KRİTİK HATA DETAYI: $e'); // Bunu VS Code terminalinde görmek için
      return "SİSTEM HATASI: $e"; // Bunu da telefonun ekranında (kırmızı uyarıda) görmek için
    }
  }

  // --- KAYIT OLMA METODU
  Future<String?> register(
    String fullName,
    String email,
    String password,
    String phone,
    int regionId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'role':
              'Farmer', // Sistemde varsayılan rolü "Farmer" veya "User" olarak ayarlıyoruz
          'regionId':
              regionId, // Artık string değil, veritabanındaki gerçek ID!
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Başarılı
      } else {
        return "Kayıt başarısız! (Hata Kodu: ${response.statusCode}) - ${response.body}";
      }
    } catch (e) {
      return "Sunucuya bağlanılamadı. İnternetini veya API'yi kontrol et.";
    }
  }

  // --- TARLALARI GETİR (GÜNCELLENDİ) ---
  Future<List<FarmField>> getFarmFields() async {
    final token = await _getToken(); // Anahtarı cebimizden çıkardık

    final response = await http.get(
      Uri.parse('$baseUrl/FarmField'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Backend'e biletimizi gösterdik!
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<FarmField> fields = body
          .map((dynamic item) => FarmField.fromJson(item))
          .toList();
      return fields;
    } else {
      throw Exception('Tarlalar yüklenemedi: ${response.statusCode}');
    }
  }

  // --- SULAMA VERİLERİNİ GETİR (DİNAMİK ID İLE) ---
  Future<List<dynamic>> getIrrigations(int farmFieldId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token bulunamadı');

      // Artık sabit 1 değil, parametre olarak gelen farmFieldId'yi kullanıyoruz!
      final response = await http.get(
        Uri.parse('$baseUrl/farmfield/$farmFieldId/irrigation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Hata Kodu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // --- KULLANICI PROFİLİNİ GETİR ---
  Future<Map<String, dynamic>> getUserProfile() async {
    final token = await _getToken(); // Girişte cebimize koyduğumuz anahtar
    if (token == null) throw Exception('Sisteme giriş yapılmamış (Token yok)');

    final response = await http.get(
      Uri.parse('$baseUrl/User/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Güvenlik kontrolünden geçiyoruz
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Profil bilgileri çekilemedi: ${response.statusCode}');
    }
  }

  // --- HAVA DURUMUNU GETİR ---
  // Not: C# tarafında WeatherController herkese açık olduğu için token eklememize gerek yok
  Future<Map<String, dynamic>> getWeather(String city) async {
    final response = await http.get(Uri.parse('$baseUrl/Weather?city=$city'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Hava durumu çekilemedi: ${response.statusCode}');
    }
  }

  // --- YENİ SULAMA KAYDI EKLE (POST) ---
  Future<bool> createIrrigation(
    int farmFieldId,
    double litersUsed,
    String date,
    String description,
  ) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/farmfield/$farmFieldId/irrigation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'litersUsed': litersUsed,
          'date': date,
          'description': description,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Sulama eklenirken hata: $e');
      return false;
    }
  }

  // --- BÖLGELERİ GETİR ---
  Future<List<dynamic>> getRegions() async {
    final response = await http.get(Uri.parse('$baseUrl/Region'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Bölgeler yüklenemedi: ${response.statusCode}');
    }
  }

  // --- YENİ TARLA KAYDET ---
  Future<bool> createFarmField(
    String name,
    String city,
    String county,
    int regionId,
    String plantName,
    String sowingDate,
    double area,
    String soilInfo,
  ) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/FarmField'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'city': city,
          'county': county,
          'regionId': regionId, // Veritabanı ID istiyor
          'plantName': plantName,
          'sowingDate': sowingDate,
          'area': area,
          'soilInfo': soilInfo,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Tarla eklenirken hata: $e');
      return false;
    }
  }

  // --- PROFİL GÜNCELLEME METODU ---
  // --- PROFİL GÜNCELLEME METODU ---
  Future<String?> updateProfile(
    String fullName,
    String phone,
    String bio,
  ) async {
    // bio eklendi!
    final token = await _getToken();
    if (token == null) return "Sisteme giriş yapılmamış.";

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/User/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': fullName,
          'phone': phone,
          'bio': bio, // İŞTE BU EKSİKTİ! Artık biyografi de gidiyor.
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return null;
      } else {
        return "Güncelleme başarısız! (Hata: ${response.statusCode})";
      }
    } catch (e) {
      return "Sunucuya bağlanılamadı. İnternetini kontrol et.";
    }
  }
}
