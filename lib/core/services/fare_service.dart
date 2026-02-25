import 'dart:convert';
import 'package:flutter/services.dart';

class FareService {
  static List<dynamic>? _taripaData;
  static List<String> availableTiers = [];

  static Future<void> init() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/mati_master_taripa.json',
      );
      _taripaData = json.decode(response);

      if (_taripaData != null && _taripaData!.isNotEmpty) {
        for (var section in _taripaData!) {
          var matrix = section['fare_matrix'];
          if (matrix != null && matrix.isNotEmpty) {
            Map<String, dynamic> rates = matrix[0]['rates'];
            availableTiers = rates.keys.toList();
            break;
          }
        }
      }
    } catch (e) {
      _taripaData = null;
    }
  }

  static double? calculateTripFare(
    String? pickup,
    String? drop,
    String selectedTier, {
    bool isDiscounted = false,
  }) {
    if (_taripaData == null ||
        pickup == null ||
        drop == null ||
        pickup == drop ||
        selectedTier.isEmpty) {
      return null;
    }

    for (var terminalGroup in _taripaData!) {
      String terminalName = (terminalGroup['terminal'] ?? "")
          .toString()
          .toLowerCase();
      List<dynamic> fareMatrix = terminalGroup['fare_matrix'] ?? [];

      bool pickupIsTerminal =
          terminalName.contains(pickup.toLowerCase()) ||
          terminalName.contains("city proper");
      bool dropIsTerminal =
          terminalName.contains(drop.toLowerCase()) ||
          terminalName.contains("city proper");

      if (pickupIsTerminal || dropIsTerminal) {
        String searchLocation = pickupIsTerminal
            ? drop.toLowerCase()
            : pickup.toLowerCase();

        for (var route in fareMatrix) {
          String? destination = (route['destination'] ?? route['to'])
              ?.toString()
              .toLowerCase();
          String? fromLocation = route['from']?.toString().toLowerCase();

          bool matchFound = false;

          if (destination != null) {
            List<String> destinations = destination
                .split(',')
                .map((e) => e.trim())
                .toList();
            if (destinations.any(
              (d) =>
                  d == searchLocation ||
                  searchLocation.contains(d) ||
                  d.contains(searchLocation),
            )) {
              matchFound = true;
            }
          }

          if (!matchFound && fromLocation != null) {
            if (fromLocation.contains(searchLocation)) {
              matchFound = true;
            }
          }

          if (matchFound) {
            return _getRateForTier(route['rates'], selectedTier, isDiscounted);
          }
        }
      }
    }

    return _calculateFallbackFare(selectedTier, isDiscounted);
  }

  static double _getRateForTier(
    Map<String, dynamic> rates,
    String tier,
    bool isDiscounted,
  ) {
    double baseFare = (rates[tier] ?? rates.values.first).toDouble();
    double finalFare = isDiscounted ? (baseFare * 0.8) : baseFare;
    return _roundToNearestFive(finalFare);
  }

  static double _calculateFallbackFare(String tier, bool isDiscounted) {
    double minFare = 15.0;
    if (tier == "50.00-69.99") minFare = 20.0;
    if (tier == "70.00-89.99") minFare = 22.0;
    if (tier == "90.00-99.99") minFare = 25.0;

    double finalFare = isDiscounted ? (minFare * 0.8) : minFare;
    return _roundToNearestFive(finalFare);
  }

  static double _roundToNearestFive(double fare) {
    if (fare % 5 == 0) return fare;
    return fare + (5 - (fare % 5));
  }
}
