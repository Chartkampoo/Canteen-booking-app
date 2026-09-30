import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MenuOfTheDayCard extends StatefulWidget {
  const MenuOfTheDayCard({super.key});

  @override
  State<MenuOfTheDayCard> createState() => _MenuOfTheDayCardState();
}

class _MenuOfTheDayCardState extends State<MenuOfTheDayCard> {
  final _apiService = ApiService();
  late Future<MealOfTheDay> _mealFuture;

  @override
  void initState() {
    super.initState();
    _mealFuture = _apiService.fetchRandomMeal();
  }

  void _refresh() {
    setState(() {
      _mealFuture = _apiService.fetchRandomMeal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MealOfTheDay>(
      future: _mealFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('โหลดเมนูแนะนำไม่สำเร็จ: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }

        final meal = snapshot.data!;
        return Card(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              if (meal.thumbnailUrl.isNotEmpty)
                Image.network(meal.thumbnailUrl,
                    width: 90, height: 90, fit: BoxFit.cover),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('เมนูแนะนำวันนี้',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(meal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('หมวด: ${meal.category}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
            ],
          ),
        );
      },
    );
  }
}
