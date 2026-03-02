import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/constant/app_colors.dart';
import 'driver_details_view.dart';

class QrScannerView extends StatefulWidget {
  final Function(String) onQrCodeDetected;
  const QrScannerView({super.key, required this.onQrCodeDetected});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView>
    with WidgetsBindingObserver {
  MobileScannerController? controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  void _initializeController() {
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      autoStart: true,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null || !controller!.value.isInitialized) return;

    if (state == AppLifecycleState.resumed) {
      controller!.start();
    } else {
      controller!.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    controller = null;
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_hasNavigated) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        try {
          final Map<String, dynamic> data = jsonDecode(barcode.rawValue!);

          if (data.containsKey('name') || data.containsKey('plate')) {
            _hasNavigated = true;
            widget.onQrCodeDetected(barcode.rawValue!);

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DriverDetailsView(driverData: data),
                ),
              );
            }
            break;
          }
        } catch (e) {
          continue;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.darkNavy,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "SCAN DRIVER QR",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: AppColors.darkNavy,
          ),
        ),
      ),
      body: Stack(
        children: [
          if (controller != null)
            MobileScanner(
              controller: controller!,
              onDetect: _handleDetection,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error.errorCode ==
                                MobileScannerErrorCode
                                    .controllerAlreadyInitialized
                            ? "Camera is warming up..."
                            : "Camera Error: ${error.errorCode}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          controller?.stop().then((_) => controller?.start());
                        },
                        child: const Text("Reset Camera"),
                      ),
                    ],
                  ),
                );
              },
            ),
          _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryYellow, width: 4),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}
