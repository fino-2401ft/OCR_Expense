import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../parser/receipt_parser.dart';
import '../../review/presentation/review_screen.dart';
import '../services/image_crop_service.dart';
import '../services/ocr_service.dart';
import 'widgets/crop_overlay_painter.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _initializing = true;
  String? _error;
  bool _busy = false;
  FlashMode _flash = FlashMode.off;

  final _ocr = OcrService();
  final _cropper = ImageCropService();
  final _parser = ReceiptParser();
  final _normalizedCrop = ImageCropService.defaultNormalizedCrop();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _ocr.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _controller;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No camera found on this device.';
          _initializing = false;
        });
        return;
      }
      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.setFlashMode(_flash);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } on CameraException catch (e) {
      setState(() {
        _error =
            'Camera permission denied or unavailable (${e.code}). Open system settings to allow camera access.';
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to start camera: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _toggleFlash() async {
    final cam = _controller;
    if (cam == null) return;
    final next = switch (_flash) {
      FlashMode.off => FlashMode.torch,
      FlashMode.torch => FlashMode.auto,
      _ => FlashMode.off,
    };
    try {
      await cam.setFlashMode(next);
      setState(() => _flash = next);
    } catch (_) {
      // Some devices do not support all flash modes.
    }
  }

  Future<void> _onTapFocus(TapDownDetails details, BoxConstraints constraints) async {
    final cam = _controller;
    if (cam == null || !cam.value.isInitialized) return;
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    try {
      await cam.setFocusPoint(offset);
      await cam.setExposurePoint(offset);
    } catch (_) {}
  }

  Future<void> _capture() async {
    final cam = _controller;
    if (cam == null || !cam.value.isInitialized || _busy) return;

    setState(() => _busy = true);
    try {
      final shot = await cam.takePicture();
      final source = File(shot.path);
      final isFront =
          cam.description.lensDirection == CameraLensDirection.front;
      final cropped = await _cropper.cropToOverlay(
        source: source,
        normalizedCrop: _normalizedCrop,
        isFrontCamera: isFront,
      );

      final text = await _ocr.recognize(cropped);
      final parsed = _parser.parse(text);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewScreen(
            imageFile: cropped,
            parsed: parsed,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  IconData get _flashIcon => switch (_flash) {
        FlashMode.torch => Icons.flash_on,
        FlashMode.auto => Icons.flash_auto,
        _ => Icons.flash_off,
      };

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _initCamera, child: const Text('Retry')),
          ],
        ),
      );
    }

    final cam = _controller!;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crop = Rect.fromLTWH(
                constraints.maxWidth * _normalizedCrop.left,
                constraints.maxHeight * _normalizedCrop.top,
                constraints.maxWidth * _normalizedCrop.width,
                constraints.maxHeight * _normalizedCrop.height,
              );
              return GestureDetector(
                onTapDown: (d) => _onTapFocus(d, constraints),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: cam.value.previewSize?.height ?? constraints.maxWidth,
                        height: cam.value.previewSize?.width ?? constraints.maxHeight,
                        child: CameraPreview(cam),
                      ),
                    ),
                    CustomPaint(painter: CropOverlayPainter(cropRect: crop)),
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Align receipt inside the frame · tap to focus',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              shadows: const [
                                Shadow(blurRadius: 6, color: Colors.black54),
                              ],
                            ),
                      ),
                    ),
                    if (_busy)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 12),
                              Text(
                                'Reading receipt…',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  onPressed: _busy ? null : _toggleFlash,
                  icon: Icon(_flashIcon),
                  tooltip: 'Flash',
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _capture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
