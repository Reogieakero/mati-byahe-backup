import 'package:flutter/material.dart';
import 'location_input_field.dart';
import 'location_search_sheet.dart';
import 'fare_display.dart';
import 'empty_route_placeholder.dart';
import '../../core/services/fare_service.dart';
import '../../core/services/location_data_service.dart';
import '../../core/constant/app_colors.dart';
import '../home_controller.dart';
import '../../core/widgets/sileo_notification.dart';

class LocationSelector extends StatefulWidget {
  final String email;
  final String role;
  final Function(double) onFareCalculated;
  final Function(Map<String, dynamic>)? onTripStarted;

  const LocationSelector({
    super.key,
    required this.email,
    required this.role,
    required this.onFareCalculated,
    this.onTripStarted,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  final HomeController _controller = HomeController();
  final TextEditingController _plateController = TextEditingController();
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

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final locations = await LocationDataService.fetchAllLocations();
    if (mounted) {
      setState(() {
        _allLocations = locations;
      });
    }
  }

  void _resetTrip() {
    setState(() {
      _pickup = null;
      _drop = null;
      _plateController.clear();
    });
  }

  Future<void> _showPlateNumberDialog(double fare) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: AppColors.primaryBlue.withOpacity(0.05),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.directions_car_filled_outlined,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: "DRIVER DETAILS: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: AppColors.darkNavy,
                            letterSpacing: 0.5,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  "Please enter the driver's plate number to proceed with the ride.",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                                color: AppColors.darkNavy.withOpacity(0.7),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildPlateInput(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _plateController.clear();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        "BACK",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {
                        if (_plateController.text.trim().isEmpty) {
                          SileoNotification.show(
                            context,
                            'Plate number is required',
                            type: SileoNoticeType.warning,
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _executeStartTrip(fare);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "CONFIRM RIDE",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executeStartTrip(double fare) async {
    await _controller.startTrip(
      context: context,
      email: widget.email,
      fare: fare,
      pickup: _pickup!,
      dropOff: _drop!,
      gasTier: _selectedGasTier,
      driverPlate: _plateController.text,
      onSuccess: (val) async {
        if (widget.onTripStarted != null) {
          widget.onTripStarted!({
            'fare': fare,
            'pickup': _pickup,
            'drop_off': _drop,
            'gas_tier': _selectedGasTier,
            'plate_number': _plateController.text,
            'start_time': DateTime.now().toIso8601String(),
          });
        }
        _resetTrip();
      },
    );
  }

  Widget _buildPlateInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.pin_outlined,
            size: 18,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _plateController,
              autofocus: true,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                isDense: true,
                hintText: "ENTER PLATE NUMBER",
                hintStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double? fare = (_pickup != null && _drop != null)
        ? FareService.calculateTripFare(_pickup!, _drop!, _selectedGasTier)
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
    final bool isPassenger = widget.role.toLowerCase() == 'passenger';

    if (fare != null && fare > 0) {
      return FareDisplay(
        fare: fare,
        buttonLabel: isPassenger ? 'Ride' : 'Clear',
        onArrived: () {
          if (isPassenger) {
            _showPlateNumberDialog(fare);
          } else {
            _resetTrip();
          }
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
