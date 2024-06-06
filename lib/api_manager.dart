
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ApiManager extends ChangeNotifier {
  late Future<Meal> futureMeal;

  Future<Meal> fetchMeal() async {
    final response = await http.get(
        Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'));
    if (response.statusCode == 200) {
      return Meal.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load Meal');
    }
  }
}


class Meal {
  final String idMeal;
  final String strMeal;
  final String strMealThumb;
  final String strInstructions;

  const Meal({
    required this.idMeal,
    required this.strMeal,
    required this.strMealThumb,
    required this.strInstructions,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('meals') && json['meals'] is List) {
      final meal = json['meals'][0];
      if (meal is Map<String, dynamic> && meal.containsKey('idMeal') && meal.containsKey('strMeal')) {
        return Meal(
          idMeal: meal['idMeal'] as String,
          strMeal: meal['strMeal'] as String,
          strMealThumb: meal['strMealThumb'] as String,
          strInstructions: meal['strInstructions'] as String,
        );
      }
    }
    throw const FormatException('Failed to load meal.');
  }
}