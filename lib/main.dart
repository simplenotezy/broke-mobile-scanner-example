import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TicketScannerScreen(),
    );
  }
}

class TicketScannerScreen extends StatefulWidget {
  const TicketScannerScreen({super.key});

  @override
  State<TicketScannerScreen> createState() => _TicketScannerScreenState();
}

class _TicketScannerScreenState extends State<TicketScannerScreen>
    with WidgetsBindingObserver {
  late MobileScannerController controller;
  StreamSubscription<BarcodeCapture>? _barcodeSubscription;

  Rect? scanWindow;
  final Size qrSize = const Size(200, 200);
  final Size barSize = const Size(300, 100);

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   // If the controller is not ready, do not try to start or stop it.
  //   // Permission dialogs can trigger lifecycle changes before the controller is ready.
  //   if (!controller.value.isInitialized) {
  //     return;
  //   }

  //   switch (state) {
  //     case AppLifecycleState.detached:
  //     case AppLifecycleState.hidden:
  //     case AppLifecycleState.paused:
  //       return;
  //     case AppLifecycleState.resumed:
  //       _startController();
  //     case AppLifecycleState.inactive:
  //       // Stop the scanner when the app is paused.
  //       // Also stop the barcode events subscription.
  //       unawaited(_barcodeSubscription?.cancel());
  //       _barcodeSubscription = null;
  //       unawaited(controller.stop());
  //   }
  // }

  _startController() async {
    controller = MobileScannerController(
      // formats: const [BarcodeFormat.code128, BarcodeFormat.qrCode],
      autoStart: false,
    );

    _barcodeSubscription = controller.barcodes.listen(_handleBarcodeCapture);

    // Finally, start the scanner itself.
    unawaited(controller.start());
  }

  @override
  void initState() {
    super.initState();

    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

    _startController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setScanWindow(barSize);
    });
  }

  void _handleBarcodeCapture(BarcodeCapture barcodeCapture) {
    final scannedBarcodes = barcodeCapture.barcodes;

    if (scannedBarcodes.isNotEmpty) {
      _handleBarcode(scannedBarcodes.first);
    } else {
      print('No barcode found.');
    }
  }

  void _handleBarcode(Barcode barcode) {
    final value = barcode.displayValue;

    // Your custom action here, e.g., showing a bottom action sheet
    if (value == null) {
      print('No barcode value found.');
      return;
    }

    print('Scanned barcode: $value - ${barcode.format.name}');
  }

  _setScanWindow(Size size) {
    final center = MediaQuery.sizeOf(context).center(Offset.zero);
    scanWindow = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );

    unawaited(controller.updateScanWindow(scanWindow!));

    setState(() {});
  }

  @override
  Future<void> dispose() async {
    super.dispose();

    await controller.dispose();
    _barcodeSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final center = MediaQuery.sizeOf(context).center(Offset.zero);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            fit: BoxFit.cover,
            controller: controller,
            // scanWindowUpdateThreshold: 1000,
            scanWindow: scanWindow ??
                Rect.fromCenter(
                  center: center,
                  width: barSize.width,
                  height: barSize.height,
                ),
            errorBuilder: (context, error, child) {
              return ScannerErrorWidget(error: error);
            },
            overlayBuilder: (context, constraints) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(),
                ),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              if (!value.isInitialized ||
                  !value.isRunning ||
                  value.error != null ||
                  scanWindow == null) {
                return const SizedBox();
              }

              return ScannerOverlay(initialScanWindow: scanWindow!);
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              foregroundColor: Colors.white,
              title: Text('Scan'),
              // transparent app bar
              backgroundColor: Colors.transparent,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ToggleFlashlightButton(controller: controller),
                    SwitchCameraButton(controller: controller),
                    IconButton.filled(
                      icon: Icon(
                        scanWindow?.size == qrSize
                            ? Icons.subtitles
                            : Icons.qr_code,
                      ),
                      color: Colors.white,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          Colors.grey.withOpacity(0.5),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        fixedSize: WidgetStateProperty.all(
                          const Size(50, 50),
                        ),
                      ),
                      onPressed: () async {
                        if (scanWindow?.size == qrSize) {
                          _setScanWindow(barSize);
                        } else {
                          _setScanWindow(qrSize);
                        }
                        setState(() {});
                      },
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

class ScannerOverlay extends StatefulWidget {
  final Rect initialScanWindow;
  final double borderRadius;

  const ScannerOverlay({
    super.key,
    required this.initialScanWindow,
    this.borderRadius = 12.0,
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Rect?> _scanWindowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scanWindowAnimation = RectTween(
      begin: widget.initialScanWindow,
      end: widget.initialScanWindow,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(covariant ScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialScanWindow != oldWidget.initialScanWindow) {
      _scanWindowAnimation = RectTween(
        begin: _scanWindowAnimation.value,
        end: widget.initialScanWindow,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0.0);
    }
  }

  void updateScanWindow(Rect newScanWindow) {
    setState(() {
      _scanWindowAnimation = RectTween(
        begin: _scanWindowAnimation.value,
        end: newScanWindow,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scanWindowAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScannerOverlayPainter(
            scanWindow: _scanWindowAnimation.value!,
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({
    required this.scanWindow,
    this.borderRadius = 12.0,
  });

  final Rect scanWindow;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Offset.zero & size);

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          scanWindow,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final borderRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) {
    return scanWindow != oldDelegate.scanWindow ||
        borderRadius != oldDelegate.borderRadius;
  }
}

class ScannerErrorWidget extends StatelessWidget {
  const ScannerErrorWidget({super.key, required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    String errorMessage;

    switch (error.errorCode) {
      case MobileScannerErrorCode.controllerUninitialized:
        errorMessage = 'Controller not ready.';
      case MobileScannerErrorCode.permissionDenied:
        errorMessage = 'Permission denied';
      case MobileScannerErrorCode.unsupported:
        errorMessage = 'Scanning is unsupported on this device';
      default:
        errorMessage = 'Generic Error';
        break;
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.error, color: Colors.white),
            ),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              error.errorDetails?.message ?? '',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyzeImageFromGalleryButton extends StatelessWidget {
  const AnalyzeImageFromGalleryButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: Colors.white,
      icon: const Icon(Icons.image),
      iconSize: 32.0,
      onPressed: () async {
        // final ImagePicker picker = ImagePicker();

        // final XFile? image = await picker.pickImage(
        //   source: ImageSource.gallery,
        // );

        // if (image == null) {
        //   return;
        // }

        // final BarcodeCapture? barcodes = await controller.analyzeImage(
        //   image.path,
        // );

        // if (!context.mounted) {
        //   return;
        // }

        // final SnackBar snackbar = barcodes != null
        //     ? const SnackBar(
        //         content: Text('Barcode found!'),
        //         backgroundColor: Colors.green,
        //       )
        //     : const SnackBar(
        //         content: Text('No barcode found!'),
        //         backgroundColor: Colors.red,
        //       );

        // ScaffoldMessenger.of(context).showSnackBar(snackbar);
      },
    );
  }
}

class StartStopMobileScannerButton extends StatelessWidget {
  const StartStopMobileScannerButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return IconButton(
            color: Colors.white,
            icon: const Icon(Icons.play_arrow),
            iconSize: 32.0,
            onPressed: () async {
              await controller.start();
            },
          );
        }

        return IconButton(
          color: Colors.white,
          icon: const Icon(Icons.stop),
          iconSize: 32.0,
          onPressed: () async {
            await controller.stop();
          },
        );
      },
    );
  }
}

class SwitchCameraButton extends StatelessWidget {
  const SwitchCameraButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        final int? availableCameras = state.availableCameras;

        final disabled = !state.isInitialized ||
            !state.isRunning ||
            (availableCameras ?? 0) > 2;

        final Widget icon;

        switch (state.cameraDirection) {
          case CameraFacing.front:
            icon = const Icon(Icons.camera_front);
          case CameraFacing.back:
            icon = const Icon(Icons.camera_rear);
        }

        return IconButton.filled(
          icon: icon,
          color: Colors.white,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              Colors.grey.withOpacity(0.5),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            fixedSize: WidgetStateProperty.all(
              const Size(50, 50),
            ),
          ),
          onPressed: disabled
              ? null
              : () async {
                  await controller.switchCamera();
                },
        );
      },
    );
  }
}

class ToggleFlashlightButton extends StatelessWidget {
  const ToggleFlashlightButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        final disabled = state.torchState == TorchState.unavailable ||
            !state.isInitialized ||
            !state.isRunning;

        IconData icon;

        switch (state.torchState) {
          case TorchState.auto:
            icon = Icons.flash_auto;
          case TorchState.off:
            icon = Icons.flash_off;
          case TorchState.on:
          default:
            icon = Icons.flash_on;
        }

        return IconButton.filled(
          icon: Icon(icon),
          color: Colors.white,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              Colors.grey.withOpacity(0.5),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            fixedSize: WidgetStateProperty.all(
              const Size(50, 50),
            ),
          ),
          onPressed: disabled
              ? null
              : () async {
                  await controller.toggleTorch();
                },
        );
      },
    );
  }
}
