import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/asset_provider.dart';
import '../assets/asset_detail_screen.dart';

class AssetQrScannerScreen extends StatefulWidget {
  const AssetQrScannerScreen({super.key});

  @override
  State<AssetQrScannerScreen> createState() =>
      _AssetQrScannerScreenState();
}

class _AssetQrScannerScreenState
    extends State<AssetQrScannerScreen> {
  final MobileScannerController _controller =
      MobileScannerController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) {
      return;
    }

    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;

    if (value == null || value.isEmpty) {
      return;
    }

    const prefix = 'HAM-ASSET-';

    if (!value.startsWith(prefix)) {
      _showMessage(
        'QR Code นี้ไม่ใช่ของทรัพย์สินในระบบ',
      );
      return;
    }

    final idText = value.substring(prefix.length);
    final assetId = int.tryParse(idText);

    if (assetId == null || assetId <= 0) {
      _showMessage('รหัสทรัพย์สินไม่ถูกต้อง');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await _controller.stop();

    if (!mounted) {
      return;
    }

    final provider = context.read<AssetProvider>();
    final asset = await provider.getAssetById(assetId);

    if (!mounted) {
      return;
    }

    if (asset == null) {
      setState(() {
        _isProcessing = false;
      });

      await _controller.start();

      if (!mounted) {
        return;
      }

      _showMessage(
        'ไม่พบทรัพย์สินรหัส #$assetId',
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssetDetailScreen(
          assetId: assetId,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
    });

    await _controller.start();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR ทรัพย์สิน'),
        actions: [
          IconButton(
            tooltip: 'เปิด/ปิดไฟฉาย',
            onPressed: () {
              _controller.toggleTorch();
            },
            icon: const Icon(
              Icons.flashlight_on_outlined,
            ),
          ),
          IconButton(
            tooltip: 'สลับกล้อง',
            onPressed: () {
              _controller.switchCamera();
            },
            icon: const Icon(
              Icons.cameraswitch_outlined,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Card(
              color: Colors.black.withValues(
                alpha: 0.72,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'นำ QR Code ของทรัพย์สินมาไว้ในกรอบ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isProcessing
                          ? 'กำลังค้นหาทรัพย์สิน...'
                          : 'ระบบจะเปิดรายละเอียดให้อัตโนมัติ',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}