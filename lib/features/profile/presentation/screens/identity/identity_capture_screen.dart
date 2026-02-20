import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/profile/controllers/identity_verification_controller.dart';

class IdentityCaptureScreen extends StatefulWidget {
  const IdentityCaptureScreen({super.key});

  @override
  State<IdentityCaptureScreen> createState() => _IdentityCaptureScreenState();
}

class _IdentityCaptureScreenState extends State<IdentityCaptureScreen> {
  static const _navy = Color(0xFF081B4A);

  CameraController? _camera;
  XFile? _capturedFile;

  bool _openingCamera = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();

    // Option A (recommended): open camera automatically when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<bool> _ensureCameraPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _openCamera() async {
    if (_openingCamera) return;
    if (_camera != null && _camera!.value.isInitialized) return;

    setState(() => _openingCamera = true);

    final ok = await _ensureCameraPermission();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required.')),
        );
      }
      setState(() => _openingCamera = false);
      return;
    }

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera found on this device.')),
          );
        }
        setState(() => _openingCamera = false);
        return;
      }

      // Use back camera if available, else first
      final back = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      final selected = back.isNotEmpty ? back.first : cameras.first;

      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      // If user left the screen while initializing
      if (!mounted) return;

      setState(() {
        _camera = controller;
        _openingCamera = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open camera: $e')));
      }
      setState(() => _openingCamera = false);
    }
  }

  Future<void> _capture() async {
    // If already captured, allow retake by clearing captured file
    final flow = context.read<IdentityVerificationController>();

    if (_capturedFile != null) {
      setState(() => _capturedFile = null);
      flow.setCaptured(false);
      await _openCamera();
      return;
    }

    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) {
      await _openCamera();
      return;
    }

    try {
      final file = await cam.takePicture();

      // stop preview is optional; we just show captured image
      setState(() => _capturedFile = file);
      flow.setCaptured(true);

      // Processing overlay then success
      setState(() => _processing = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() => _processing = false);

      context.go(AppRoutes.identitySuccess);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<IdentityVerificationController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Verify your identity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Align your ID\nwithin the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ensure good lighting and avoid glare',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 18),

                  // Frame (tap to open camera)
                  InkWell(
                    onTap: _openCamera,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF9CA3AF),
                          width: 1,
                        ),
                        color: Colors.black,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _buildFrameContent(flow),
                      ),
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: (_openingCamera || _processing)
                          ? null
                          : _capture,
                      child: Text(
                        _capturedFile == null ? 'Capture' : 'Retake',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Processing overlay (no separate screen)
            if (_processing) ...[
              const ModalBarrier(dismissible: false, color: Colors.white),
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFrameContent(IdentityVerificationController flow) {
    // If captured, show captured image preview
    if (_capturedFile != null) {
      return Image.file(File(_capturedFile!.path), fit: BoxFit.cover);
    }

    // Show live camera preview if initialized
    final cam = _camera;
    if (cam != null && cam.value.isInitialized) {
      return CameraPreview(cam);
    }

    // Default placeholder (tap to open camera)
    return Center(
      child: _openingCamera
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              'Tap to open camera',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
