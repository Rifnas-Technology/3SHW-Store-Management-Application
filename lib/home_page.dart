import 'package:flutter/material.dart';
import 'add_product_page.dart';
import 'product_view_page.dart';
import 'label_page.dart';
import 'services/gsheet_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<LabelPageState> _labelPageKey = GlobalKey<LabelPageState>();
  Future<int>? _productCount;

  @override
  void initState() {
    super.initState();
    _refreshProductCount();
  }

  void _refreshProductCount() {
    setState(() {
      _productCount = GSheetService.getAllProducts().then((list) => list.length);
    });
  }

  final List<String> _titles = [
    'DASHBOARD',
    'SEARCH PRODUCT',
    'PRODUCT LABELS',
    'ADD PRODUCT',
  ];

  final List<IconData> _titleIcons = [
    Icons.grid_view_rounded,
    Icons.manage_search_rounded,
    Icons.style_rounded,
    Icons.add_shopping_cart_rounded,
  ];

  void _onItemTapped(int index) {
    if (index == 4) {
      // Logout logic for the 5th item
      _showLogoutDialog();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // Refresh dashboard stats when switching home
    if (index == 0) {
      _refreshProductCount();
    }
    
    // Automatically refresh LabelPage when switching to its tab (now index 2)
    if (index == 2) {
      _labelPageKey.currentState?.refresh();
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('LOGOUT', style: TextStyle(color: Color(0xFFFDD23E), fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDD23E),
              foregroundColor: const Color(0xFF1C1C1C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        foregroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDD23E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _titleIcons[_selectedIndex],
                color: const Color(0xFFFDD23E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _titles[_selectedIndex], 
              style: const TextStyle(
                fontWeight: FontWeight.w900, 
                letterSpacing: 2, 
                fontSize: 16,
                color: Colors.white,
              )
            ),
          ],
        ),
        elevation: 4,
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          const ProductViewPage(isEmbedded: true),
          LabelPage(key: _labelPageKey, isEmbedded: true),
          const AddProductPage(isEmbedded: true),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3), 
              blurRadius: 20, 
              offset: const Offset(0, 5)
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex >= 4 ? 0 : _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: const Color(0xFF1C1C1C),
            selectedItemColor: const Color(0xFFFDD23E),
            unselectedItemColor: Colors.grey.withValues(alpha: 0.6),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded),
                activeIcon: Icon(Icons.grid_view_rounded),
                label: 'HOME',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.manage_search_rounded),
                activeIcon: Icon(Icons.manage_search_rounded),
                label: 'SEARCH',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.style_rounded),
                activeIcon: Icon(Icons.style_rounded),
                label: 'LABELS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_shopping_cart_rounded),
                activeIcon: Icon(Icons.add_shopping_cart_rounded),
                label: 'ADD',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.power_settings_new_rounded),
                label: 'LOGOUT',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              
              // Total Products Card - Premium Redesign
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: FutureBuilder<int>(
                  future: _productCount,
                  builder: (context, snapshot) {
                    final String count = snapshot.hasData ? snapshot.data.toString() : '...';
                    return Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2A2A2A), Color(0xFF1C1C1C)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFDD23E).withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFFDD23E).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Background Decorative Icon
                          Positioned(
                            bottom: -20,
                            right: -20,
                            child: Icon(
                              Icons.inventory_2_rounded,
                              size: 150,
                              color: const Color(0xFFFDD23E).withValues(alpha: 0.05),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDD23E).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.analytics_outlined,
                                        color: Color(0xFFFDD23E),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'STORAGE CAPACITY',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      count,
                                      style: const TextStyle(
                                        color: Color(0xFFFDD23E),
                                        fontSize: 64,
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        'ITEMS',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 4,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFDD23E), Colors.transparent],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Minimal Info Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: _buildStatCard('Manage inventory items', Icons.inventory_2_outlined),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFDD23E)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
