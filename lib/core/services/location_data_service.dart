import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class LocationDataService {
  static Future<List<String>> fetchAllLocations() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/mati_master_taripa.json',
      );
      final List<dynamic> data = json.decode(response);
      final Set<String> locations = {};

      for (var section in data) {
        if (section.containsKey('terminal')) {
          locations.add(
            section['terminal']
                .toString()
                .replaceAll('FARE RATE MATRIX (TARIPA)', '')
                .trim(),
          );
        }

        final List<dynamic> matrix = section['fare_matrix'] ?? [];
        for (var route in matrix) {
          if (route.containsKey('from')) {
            locations.add(route['from'].toString().trim());
          }
          if (route.containsKey('to')) {
            List<String> toParts = route['to'].toString().split(',');
            for (var part in toParts) {
              if (part.trim().isNotEmpty) {
                locations.add(part.trim());
              }
            }
          }
          if (route.containsKey('destination')) {
            locations.add(route['destination'].toString().trim());
          }
        }
      }
      return locations.where((s) => s.isNotEmpty).toList()..sort();
    } catch (e) {
      debugPrint("Error loading locations: $e");
      return [];
    }
  }
}
