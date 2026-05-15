import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import 'package:the_time_chart/widgets/error_handler.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        String? chatId;
        if (code.startsWith('https://thetimechart.com/join?c=')) {
          final uri = Uri.parse(code);
          chatId = uri.queryParameters['c'];
        } else if (code.length > 20 && !code.contains(' ')) {
          // Simple heuristic for chat IDs if it's just the ID
          chatId = code;
        }

        if (chatId != null) {
          setState(() => _isProcessing = true);
          _controller.stop();
          _joinChat(chatId);
          break;
        }
      }
    }
  }

  Future<void> _joinChat(String chatId) async {
    try {
      final provider = context.read<ChatProvider>();
      final myId = provider.currentUserId;

      if (myId == null) throw 'User not authenticated';

      final result = await provider.addMembers(chatId, [myId]);

      if (result.success) {
        if (mounted) {
          ErrorHandler.showSuccessSnackbar('Successfully joined!');
          Navigator.pop(context);
        }
      } else {
        _showError(result.error ?? 'Failed to join chat');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ErrorHandler.showErrorSnackbar(message);
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              final isFlashOn = state.torchState == TorchState.on;
              return IconButton(
                onPressed: () => _controller.toggleTorch(),
                icon: Icon(
                  isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: Colors.white,
                ),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              final isFront = _controller.facing == CameraFacing.front;
              return IconButton(
                onPressed: () => _controller.switchCamera(),
                icon: Icon(
                  isFront
                      ? Icons.camera_front_rounded
                      : Icons.camera_rear_rounded,
                  color: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Scanner Overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white60, width: 1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  _buildCorner(0, 0),
                  _buildCorner(0, 1),
                  _buildCorner(1, 0),
                  _buildCorner(1, 1),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: const Text(
              'Align the QR code within the frame to join',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(double top, double left) {
    const double size = 30;
    const double thickness = 4;
    return Positioned(
      top: top == 0 ? -2 : null,
      bottom: top == 1 ? -2 : null,
      left: left == 0 ? -2 : null,
      right: left == 1 ? -2 : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border(
            top: top == 0
                ? const BorderSide(color: Colors.white, width: thickness)
                : BorderSide.none,
            bottom: top == 1
                ? const BorderSide(color: Colors.white, width: thickness)
                : BorderSide.none,
            left: left == 0
                ? const BorderSide(color: Colors.white, width: thickness)
                : BorderSide.none,
            right: left == 1
                ? const BorderSide(color: Colors.white, width: thickness)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(top == 0 && left == 0 ? 12 : 0),
            topRight: Radius.circular(top == 0 && left == 1 ? 12 : 0),
            bottomLeft: Radius.circular(top == 1 && left == 0 ? 12 : 0),
            bottomRight: Radius.circular(top == 1 && left == 1 ? 12 : 0),
          ),
        ),
      ),
    );
  }
}
