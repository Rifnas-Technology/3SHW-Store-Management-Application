import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'services/gsheet_service.dart';
import 'utils/product_utils.dart';

class LabelPage extends StatefulWidget {
  final bool isEmbedded;
  const LabelPage({super.key, this.isEmbedded = false});

  @override
  State<LabelPage> createState() => LabelPageState();
}

class LabelPageState extends State<LabelPage> {
  List<Map<String, String>> _allProducts = [];
  List<Map<String, String>> _filteredProducts = [];
  bool _isLoading = true;
  bool _isScanning = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final data = await GSheetService.getAllProducts(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _allProducts = data;
        _filteredProducts = data;
        _isLoading = false;
        // Re-apply search filter if there's text
        if (_searchController.text.isNotEmpty) {
          _onSearchChanged();
        }
      });
    }
  }

  /// Public method to trigger a data reload (uses cache by default for speed)     
  void refresh() {
    _loadProducts(forceRefresh: false);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final id = p['id']?.toLowerCase() ?? '';
        final name = p['name']?.toLowerCase() ?? '';
        return id.contains(query) || name.contains(query);
      }).toList();
    });
  }

  void _onScan(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      setState(() {
        _isScanning = false;
        _searchController.text = code;
      });
      _onSearchChanged();
    }
  }



  Future<void> _shareLabelAsPdf(Map<String, String> p) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Center(
            child: _buildPdfLabelItem(p, isBulk: false),
          );
        },
      ),
    );

    try {
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'label_${p['id']}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateBulkPdf() async {
    if (_filteredProducts.isEmpty) return;
    
    setState(() => _isLoading = true);
    final pdf = pw.Document();
    
    // Group into chunks of 28 (4x7)
    for (var i = 0; i < _filteredProducts.length; i += 28) {
      final end = (i + 28 < _filteredProducts.length) ? i + 28 : _filteredProducts.length;
      final pageProducts = _filteredProducts.sublist(i, end);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            final List<pw.Widget> rows = [];
            for (var r = 0; r < 7; r++) {
              final List<pw.Widget> rowItems = [];
              for (var c = 0; c < 4; c++) {
                final index = r * 4 + c;
                if (index < pageProducts.length) {
                  rowItems.add(
                    pw.SizedBox(
                      width: 205, // (842 - 20) / 4
                      height: 82,  // (595 - 20) / 7
                      child: _buildPdfLabelItem(pageProducts[index], isBulk: true),
                    ),
                  );
                } else {
                  rowItems.add(pw.SizedBox(width: 205, height: 82));
                }
              }
              rows.add(pw.Row(children: rowItems));
            }
            return pw.Column(children: rows);
          },
        ),
      );
    }

    try {
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'all_labels_sheet.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating bulk PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  pw.Widget _buildPdfLabelItem(Map<String, String> p, {required bool isBulk}) {
    // Proportions calibrated to match the reference image
    final double padding = isBulk ? 6 : 30;
    final double qrSize = isBulk ? 58 : 220;
    final double titleSize = isBulk ? 12 : 48;
    final double subtitleSize = isBulk ? 10 : 36;
    final double priceSize = isBulk ? 11 : 40;
    final double costSize = isBulk ? 10 : 36;
    final double borderWidth = isBulk ? 1.0 : 3.0;
    final double borderRadius = isBulk ? 8 : 20;

    return pw.Container(
      margin: isBulk ? const pw.EdgeInsets.all(2) : pw.EdgeInsets.zero,
      padding: pw.EdgeInsets.all(padding),
      width: isBulk ? 205 : 750,
      height: isBulk ? 82 : 400,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.black, width: borderWidth),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(borderRadius)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // QR code - square on the left
          pw.Container(
            width: qrSize,
            height: qrSize,
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: p['id'] ?? '',
              drawText: false,
            ),
          ),
          pw.SizedBox(width: isBulk ? 10 : 40),
          // Product details column on the right
          pw.Expanded(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  p['name'] ?? 'Unknown',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: titleSize, color: PdfColors.black),
                ),
                pw.Text(
                  'ID: ${p['id'] ?? '-'}',
                  style: pw.TextStyle(fontSize: subtitleSize, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: isBulk ? 2 : 10),
                pw.Text(
                  'SP: RS. ${ProductUtils.formatCurrency(p['sellingPrice'] ?? '0')}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: priceSize, color: PdfColors.green700),
                ),
                pw.Text(
                  'CC: ${p['costEncoded'] ?? '-'}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: costSize, color: PdfColors.blue800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        // Search & Scan Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Product ID or Name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => setState(() => _isScanning = !_isScanning),
                style: IconButton.styleFrom(
                  backgroundColor: _isScanning ? Colors.red : const Color(0xFFFDD23E),
                  foregroundColor: _isScanning ? Colors.white : const Color(0xFF1C1C1C),
                ),
                icon: Icon(_isScanning ? Icons.close : Icons.qr_code_scanner),
              ),
            ],
          ),
        ),

        if (_isScanning)
          Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDD23E), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                MobileScanner(onDetect: _onScan),
                // Premium Scanner Overlay
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

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1C1C1C)))
              : _filteredProducts.isEmpty
                  ? const Center(child: Text('No products matching your search.'))
                  : RefreshIndicator(
                      onRefresh: () => _loadProducts(forceRefresh: true),
                      color: const Color(0xFF1C1C1C),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildLabelCard(index, product);
                        },
                      ),
                    ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('PRODUCT LABELS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18)),
        backgroundColor: const Color(0xFF1C1C1C),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            tooltip: 'Download All Sheet',
            icon: const Icon(Icons.picture_as_pdf), 
            onPressed: _generateBulkPdf,
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildLabelCard(int index, Map<String, String> p) {
    return Column(
      children: [
        Card(
          elevation: 4,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    QrImageView(
                      data: p['id'] ?? '',
                      version: QrVersions.auto,
                      size: 80.0,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('ID: ${p['id'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(
                            'Selling Price: RS. ${ProductUtils.formatCurrency(p['sellingPrice'] ?? '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          Text(
                            'Cost (Encoded): ${p['costEncoded'] ?? '-'}',
                            style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => _shareLabelAsPdf(p),
                icon: const Icon(Icons.picture_as_pdf, size: 20),
                label: const Text('Share PDF'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        // Darkened background with transparent square hole
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.4),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(decoration: const BoxDecoration(color: Colors.transparent)),
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
            child: CustomPaint(painter: ScannerOverlayPainter()),
          ),
        ),
        // Animated Scan Line
        const ScanLineAnimation(),
      ],
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
          top: 50 + (_controller.value * 200),
          left: (MediaQuery.of(context).size.width - 200) / 2 - 20,
          child: Container(
            width: 200,
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFDD23E).withValues(alpha: 0.5),
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
