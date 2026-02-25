import 'package:flutter/material.dart';
import 'location_input_field.dart';
import 'location_search_sheet.dart';
import 'fare_display.dart';
import 'empty_route_placeholder.dart';
import '../../core/services/fare_service.dart';
import '../../core/services/location_data_service.dart';
import '../../core/database/local_database.dart';
import '../../core/constant/app_colors.dart';

class LocationSelector extends StatefulWidget {
  final String email;
  final Function(double) onFareCalculated;

  const LocationSelector({
    super.key,
    required this.email,
    required this.onFareCalculated,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  String? _pickup;
  String? _drop;
  List<String> _allLocations = [];
  String _selectedGasTier = "50.00-69.99";

  final List<String> _gasTiers = [
    "40.00-49.99",
    "50.00-69.99",
    "70.00-89.99",
    "90.00-99.99",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final locations = await LocationDataService.fetchAllLocations();
    setState(() => _allLocations = locations);
  }

  void _resetTrip() => setState(() {
    _pickup = null;
    _drop = null;
  });

  @override
  Widget build(BuildContext context) {
    final double? fare = (_pickup != null && _drop != null)
        ? FareService.calculateTripFare(_pickup, _drop, _selectedGasTier)
        : null;

    final bool hasSelection = _pickup != null || _drop != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          const Text(
            'Gasoline Price Range (PHP)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 4),
          _buildGasTierSelector(),
          const SizedBox(height: 10),
          _buildHeaderRow(hasSelection),
          const SizedBox(height: 8),
          _buildInputFields(),
          const SizedBox(height: 20),
          _buildFareOrPlaceholder(fare),
        ],
      ),
    );
  }

  Widget _buildGasTierSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _gasTiers.map((tier) {
          final isSelected = _selectedGasTier == tier;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              visualDensity: VisualDensity.compact,
              elevation: 0,
              pressElevation: 0,
              shape: const StadiumBorder(side: BorderSide.none),
              label: Text(
                tier,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.darkNavy,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryBlue,
              backgroundColor: Colors.grey.shade100,
              onSelected: (val) => setState(() => _selectedGasTier = tier),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeaderRow(bool hasSelection) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Plan your trip',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.darkNavy,
          ),
        ),
        if (hasSelection)
          TextButton(
            onPressed: _resetTrip,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 25),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Clear',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Row(
      children: [
        Expanded(
          child: LocationInputField(
            label: 'Pick-up',
            value: _pickup,
            icon: Icons.circle,
            iconColor: AppColors.primaryBlue,
            onTap: () => _showPicker(true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LocationInputField(
            label: 'Drop-off',
            value: _drop,
            icon: Icons.location_on,
            iconColor: const Color(0xFFF44336),
            onTap: () => _showPicker(false),
          ),
        ),
      ],
    );
  }

  Widget _buildFareOrPlaceholder(double? fare) {
    if (fare != null && fare > 0) {
      return FareDisplay(
        fare: fare,
        buttonLabel: 'Ride',
        onArrived: () async {
          await LocalDatabase().saveTrip(
            email: widget.email,
            pickup: _pickup ?? "Unknown",
            dropOff: _drop ?? "Unknown",
            fare: fare,
            gasTier: _selectedGasTier,
          );

          widget.onFareCalculated(fare);
          _resetTrip();
        },
      );
    }
    return const EmptyRoutePlaceholder();
  }

  void _showPicker(bool isPickup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSearchSheet(
        title: isPickup ? 'Select Pickup Point' : 'Select Destination',
        barangays: _allLocations,
        onSelected: (val) {
          setState(() {
            if (isPickup)
              _pickup = val;
            else
              _drop = val;
          });
        },
      ),
    );
  }
}
