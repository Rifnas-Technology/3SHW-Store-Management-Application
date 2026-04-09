import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'services/gsheet_service.dart';
import 'utils/product_utils.dart';

class AddProductPage extends StatefulWidget {
  final bool isEmbedded;
  const AddProductPage({super.key, this.isEmbedded = false});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  
  String _productID = '';
  String _encodedPrice = '';
  bool _isLoading = false;

  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _refreshID();
  }

  void _refreshID() {
    setState(() {
      _productID = ProductUtils.generateProductID();
    });
  }

  void _onCostPriceChanged(String value) {
    setState(() {
      _encodedPrice = ProductUtils.encodePrice(value);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    final errorMessage = await GSheetService.saveProduct(
      id: _productID,
      name: _nameController.text,
      qrData: _productID,
      costPrice: _costPriceController.text,
      encodedPrice: _encodedPrice,
      sellingPrice: _sellingPriceController.text,
    );

    if (errorMessage == null) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      
      _nameController.clear();
      _costPriceController.clear();
      _sellingPriceController.clear();
      _refreshID();
      setState(() => _encodedPrice = '');

      // Return to normal state after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isSuccess = false);
      }
    } else {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product ID & QR Preview Section
            Center(
              child: Column(
                children: [
                  QrImageView(
                    data: _productID,
                    version: QrVersions.auto,
                    size: 150.0,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ID: $_productID',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF1C1C1C)),
                        onPressed: _refreshID,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            const Text('Product Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const Divider(),
            const SizedBox(height: 20),

            // Product Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Enter product name' : null,
            ),
            const SizedBox(height: 20),

            // Cost Price & Encoding Preview
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _costPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      onChanged: _onCostPriceChanged,
                      validator: (value) => value == null || value.isEmpty ? 'Enter cost price' : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Center(
                        child: Text(
                          _encodedPrice,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 4),
              child: Text('Encoded Price (Auto-generated)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 20),

            // Selling Price
            TextFormField(
              controller: _sellingPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Selling Price',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Enter selling price' : null,
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: (_isLoading || _isSuccess) ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSuccess ? Colors.green : const Color(0xFF1C1C1C),
                  disabledBackgroundColor: _isSuccess ? Colors.green : const Color(0xFF1C1C1C).withOpacity(0.6),
                  foregroundColor: const Color(0xFFFDD23E),
                  disabledForegroundColor: _isSuccess ? Colors.white : const Color(0xFFFDD23E).withOpacity(0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Color(0xFFFDD23E))
                  : Text(
                      _isSuccess ? 'SUCCESS' : 'SAVE PRODUCT', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ADD PRODUCT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18)),
        backgroundColor: const Color(0xFF1C1C1C),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: content,
    );
  }
}
