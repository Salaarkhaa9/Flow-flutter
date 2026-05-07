import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient (Partial)
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFB066FE),
                  Colors.black,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Color(0xFFB066FE),
                        child: Icon(Icons.person,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'WELCOME SALAR!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              Spacer(),
                              Icon(Icons.search, size: 20),
                              SizedBox(width: 15),
                              Icon(Icons.notifications, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'April, 01, 2026',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const Text(
                    '5th Avenue, New York, NYC',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Current Shipment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // Shipment Card
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/shipment_detail'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('549SD00X87',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  Text('Fruits & Vegetables',
                                      style: TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                              Container(
                                width: 50,
                                height: 1,
                                color: Colors.white24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.radio_button_checked,
                                      color: Colors.white, size: 16),
                                  Container(
                                      width: 2,
                                      height: 40,
                                      color: Colors.white24),
                                  const Icon(Icons.location_on,
                                      color: Colors.white, size: 16),
                                ],
                              ),
                              const SizedBox(width: 15),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Dallas ,TX',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text('April 1, 2026',
                                        style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                    SizedBox(height: 25),
                                    Text('Atlanta ,GE',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text('April 2, 2026',
                                        style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Go to Map',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Quick Actions
                  Row(
                    children: [
                      _buildQuickAction(Icons.local_gas_station, 'Fuel up'),
                      const SizedBox(width: 15),
                      _buildQuickAction(Icons.history, 'Maintenance History'),
                      const SizedBox(width: 15),
                      _buildQuickAction(
                          Icons.account_balance_wallet, 'Earnings'),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Map Placeholder — offline friendly gradient
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A2A3A),
                          Color(0xFF0D1B2A),
                        ],
                      ),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Stack(
                      children: [
                        // Fake road lines
                        Positioned(
                          top: 70,
                          left: 20,
                          right: 20,
                          child: Container(height: 2, color: Colors.white10),
                        ),
                        Positioned(
                          top: 100,
                          left: 40,
                          right: 40,
                          child: Container(height: 2, color: Colors.white10),
                        ),
                        Positioned(
                          top: 130,
                          left: 10,
                          right: 60,
                          child: Container(height: 2, color: Colors.white10),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_outlined,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 50),
                              const SizedBox(height: 8),
                              Text(
                                'Dallas, TX → Atlanta, GA',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.navigation,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Navigate',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),

      // Custom Bottom Navigation
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFB066FE), Color(0xFF6A1B9A)],
            ),
          ),
          child: const Center(
            child: Text('AI',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      color: Colors.black,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 'Home', true),
            _buildNavItem(Icons.assignment, 'Orders', false),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(Icons.view_in_ar, 'Load board', false),
            _buildNavItem(Icons.bar_chart, 'Statistics', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: isActive ? AppTheme.primaryPurple : Colors.white54,
            size: 24),
        Text(label,
            style: TextStyle(
                color: isActive ? AppTheme.primaryPurple : Colors.white54,
                fontSize: 10)),
      ],
    );
  }
}
