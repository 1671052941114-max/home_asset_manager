import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';

class AssetQrScreen extends StatefulWidget {
  const AssetQrScreen({
    super.key,
    required this.assetId,
    required this.assetName,
  });

  final int assetId;
  final String assetName;

  @override
  State<AssetQrScreen> createState() => _AssetQrScreenState();
}

class _AssetQrScreenState extends State<AssetQrScreen> {
  final GlobalKey _qrKey = GlobalKey();

  bool _isSaving = false;
  bool _isSharing = false;
  bool _isPrinting = false;

  String get qrData => 'HAM-ASSET-${widget.assetId}';

  Future<Uint8List?> _captureQrImage() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        return null;
      }

      final image = await boundary.toImage(
        pixelRatio: 3,
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (error) {
      debugPrint('AssetQrScreen._captureQrImage: $error');
      return null;
    }
  }

  Future<void> _saveQrToGallery() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final bytes = await _captureQrImage();

      if (bytes == null) {
        _showMessage('ไม่สามารถสร้างไฟล์ QR Code ได้');
        return;
      }

      var hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }

      if (!hasAccess) {
        _showMessage(
          'ไม่ได้รับอนุญาตให้บันทึก QR Code ลงใน Gallery',
        );
        return;
      }

      final directory = await getTemporaryDirectory();

      final file = File(
        '${directory.path}/HAM-ASSET-${widget.assetId}.png',
      );

      await file.writeAsBytes(bytes);

      await Gal.putImage(
        file.path,
        album: 'Home Asset Manager',
      );

      _showMessage('บันทึก QR Code ลงใน Gallery แล้ว');
    } catch (error) {
      debugPrint('AssetQrScreen._saveQrToGallery: $error');
      _showMessage('ไม่สามารถบันทึก QR Code ได้');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _shareQr() async {
    if (_isSharing) {
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final bytes = await _captureQrImage();

      if (bytes == null) {
        _showMessage('ไม่สามารถสร้างไฟล์ QR Code ได้');
        return;
      }

      final directory = await getTemporaryDirectory();

      final file = File(
        '${directory.path}/HAM-ASSET-${widget.assetId}.png',
      );

      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          text:
              'QR Code ทรัพย์สิน: ${widget.assetName}\n'
              'รหัสทรัพย์สิน #${widget.assetId}',
          files: [
            XFile(file.path),
          ],
        ),
      );
    } catch (error) {
      debugPrint('AssetQrScreen._shareQr: $error');
      _showMessage('ไม่สามารถแชร์ QR Code ได้');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _printQr() async {
    if (_isPrinting) {
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      final bytes = await _captureQrImage();

      if (bytes == null) {
        _showMessage('ไม่สามารถสร้างไฟล์ QR Code ได้');
        return;
      }

      await Printing.layoutPdf(
        onLayout: (_) async {
          return _buildPrintDocument(bytes);
        },
      );
    } catch (error) {
      debugPrint('AssetQrScreen._printQr: $error');
      _showMessage('ไม่สามารถเปิดหน้าพิมพ์ QR Code ได้');
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  Future<Uint8List> _buildPrintDocument(
    Uint8List qrBytes,
  ) async {
    final document = pw.Document();

    final qrImage = pw.MemoryImage(qrBytes);

    document.addPage(
      pw.Page(
        build: (context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  widget.assetName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'รหัสทรัพย์สิน #${widget.assetId}',
                  style: const pw.TextStyle(
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Container(
                  width: 300,
                  height: 300,
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.white,
                  child: pw.Image(
                    qrImage,
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  qrData,
                  style: const pw.TextStyle(
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Home Asset Manager',
                  style: const pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return document.save();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code ทรัพย์สิน'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          32,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.assetName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'รหัสทรัพย์สิน #${widget.assetId}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'QR Code',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ใช้ QR Code นี้เพื่อระบุทรัพย์สินรายการนี้',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 24),

                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 240,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      qrData,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _buildActionButton(
            icon: Icons.download_outlined,
            label: _isSaving
                ? 'กำลังบันทึก...'
                : 'บันทึก QR ลง Gallery',
            onPressed:
                _isSaving ? null : _saveQrToGallery,
            filled: true,
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_outlined,
                  label: _isSharing ? 'กำลังแชร์...' : 'แชร์',
                  onPressed:
                      _isSharing ? null : _shareQr,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.print_outlined,
                  label: _isPrinting
                      ? 'กำลังเตรียม...'
                      : 'พิมพ์',
                  onPressed:
                      _isPrinting ? null : _printQr,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'สามารถบันทึก แชร์ หรือพิมพ์ QR Code '
            'เพื่อนำไปติดกับทรัพย์สินได้',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}