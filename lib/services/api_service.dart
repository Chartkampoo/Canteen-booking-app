import 'dart:convert';
import 'package:http/http.dart' as http;

class MealOfTheDay {
  final String name;
  final String thumbnailUrl;
  final String category;

  MealOfTheDay(
      {required this.name, required this.thumbnailUrl, required this.category});

  factory MealOfTheDay.fromJson(Map<String, dynamic> json) {
    return MealOfTheDay(
      name: json['strMeal'] ?? '-',
      thumbnailUrl: json['strMealThumb'] ?? '',
      category: json['strCategory'] ?? '-',
    );
  }
}

class ApiService {
  static const String _randomMealUrl =
      'https://www.themealdb.com/api/json/v1/1/random.php';

  Future<MealOfTheDay> fetchRandomMeal() async {
    final response = await http.get(Uri.parse(_randomMealUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List meals = data['meals'] as List;
      return MealOfTheDay.fromJson(meals.first as Map<String, dynamic>);
    } else {
      throw Exception('โหลดเมนูไม่สำเร็จ (สถานะ ${response.statusCode})');
    }
  }
}
