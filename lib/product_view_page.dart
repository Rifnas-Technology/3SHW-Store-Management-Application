import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'services/gsheet_service.dart';
import 'utils/product_utils.dart';

class ProductViewPage extends StatefulWidget {
  final bool isEmbedded;
  const ProductViewPage({super.key, this.isEmbedded = false});

  @override
  State<ProductViewPage> createState() => _ProductViewPageState();
}

class _ProductViewPageState extends State<ProductViewPage> {
  final TextEditingController _idController = TextEditingController();
  Map<String, String>? _productData;
  bool _isSearching = false;
  bool _isScanning = false;

  Future<void> _searchProduct(String id) async {
    if (id.isEmpty) return;

    setState(() {
      _isSearching = true;
      _productData = null;
    });

    final data = await GSheetService.getProductById(id);

    setState(() {
      _productData = data;
      _isSearching = false;
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found!'), backgroundColor: Colors.orange),
        );
      }
    });
  }

  void _onScan(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      setState(() {
        _isScanning = false;
        _idController.text = code;
      });
      _searchProduct(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Product ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: _searchProduct,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _searchProduct(_idController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1C),
                  foregroundColor: const Color(0xFFFDD23E),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Icon(Icons.arrow_forward),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => setState(() => _isScanning = !_isScanning),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning ? Colors.red : const Color(0xFFFDD23E),
                  foregroundColor: _isScanning ? Colors.white : const Color(0xFF1C1C1C),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Icon(_isScanning ? Icons.close : Icons.qr_code_scanner),
              ),
            ],
          ),
        ),

        if (_isScanning)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDD23E), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: _onScan,
                ),
                // Scanner Overlay Frame
                _buildScannerOverlay(),
                // Instruction Text Overlay
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Align QR code within frame',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (_isSearching)
          const Center(child: CircularProgressIndicator(color: Color(0xFF1C1C1C))),

        if (_productData != null)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 8,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory, color: Color(0xFFFDD23E), size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              _productData!['name'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 40),
                      _buildInfoRow('Product ID', _productData!['id'] ?? '-'),
                      _buildInfoRow('Selling Price', 'RS. ${ProductUtils.formatCurrency(_productData!['sellingPrice'] ?? '0')}', isBold: true),
                      const Divider(height: 40),
                      const Text('Cost Details', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildInfoRow('Cost (Digit)', ProductUtils.formatCurrency(_productData!['costDigit'] ?? '0')),
                      _buildInfoRow('Cost (Encoded)', _productData!['costEncoded'] ?? '-', color: Colors.deepPurple),
                    ],
                  ),
                ),
              ),
            ),
          ),
        
        if (_productData == null && !_isSearching)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Scan or enter an ID to see product details', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SEARCH PRODUCT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18)),
        backgroundColor: const Color(0xFF1C1C1C),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.close : Icons.qr_code_scanner),
            onPressed: () => setState(() => _isScanning = !_isScanning),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        // Darkened background with transparent square hole
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Corner markers
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
            ),
          ),
        ),
        // Animated Scan Line
        const ScanLineAnimation(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? const Color(0xFF1C1C1C),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Scanner Corners
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFDD23E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const cornerLength = 25.0;
    const radius = 10.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius))
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - radius, 0)
        ..arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius))
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - radius)
        ..arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius))
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - radius, size.height)
        ..arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius))
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated Scan Line Widget
class ScanLineAnimation extends StatefulWidget {
  const ScanLineAnimation({super.key});

  @override
  State<ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<ScanLineAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: 50 + (_controller.value * 200), // Animate within the 200px square
          left: (MediaQuery.of(context).size.width - 200) / 2 - 20, // Centered
          child: Container(
            width: 200,
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFDD23E).withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              gradient: const LinearGradient(
                colors: [Colors.transparent, Color(0xFFFDD23E), Colors.transparent],
              ),
            ),
          ),
        );
      },
    );
  }
}
