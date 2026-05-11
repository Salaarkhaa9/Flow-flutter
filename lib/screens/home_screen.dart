import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/shipment_service.dart';
import '../models/shipment.dart';
import '../models/vehicle_profile.dart';
import '../widgets/custom_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final ShipmentService _shipmentService = ShipmentService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Shipment> _shipments = [];
  VehicleProfile? _vehicleProfile;
  bool _loading = true;
  bool _showCongrats = false;
  late AnimationController _confettiController;
  late AnimationController _cardController;
  late Animation<double> _confettiOpacity;
  late Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _confettiOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeOut),
    );
    _cardScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
    _loadHomeData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    setState(() => _loading = true);
    final list = await _shipmentService.getCurrentUserShipments();
    final user = _auth.currentUser;
    final vehicleProfile =
        user == null ? null : _auth.getVehicleProfile(user.mcNumber);
    if (!mounted) return;
    setState(() {
      _shipments = list;
      _vehicleProfile = vehicleProfile;
      _loading = false;
    });
  }

  Future<void> _navigateToVehicleRegistration() async {
    final result = await Navigator.pushNamed(context, '/vehicle_registration');
    if (result == true && mounted) {
      await _loadHomeData();
      _showCongratulations();
    }
  }

  void _showCongratulations() {
    setState(() => _showCongrats = true);
    _confettiController.forward(from: 0.0);
    _cardController.forward(from: 0.0);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showCongrats = false);
      }
    });
  }

  Future<void> _openLoadBoard() async {
    if (_vehicleProfile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete vehicle registration before booking a load.'),
          backgroundColor: Colors.orange,
        ),
      );
      _navigateToVehicleRegistration();
      return;
    }

    if (_shipments.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You cannot book more than one load at a time.')),
      );
      return;
    }
    await Navigator.pushNamed(context, '/load_board');
    await _loadHomeData();
  }

  Future<void> _cancelShipment(Shipment s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Shipment?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to cancel load ${s.loadId}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Shipment'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel Shipment'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _shipmentService.deleteShipment(s.id);
      await _loadHomeData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment cancelled. You can now book a new load.'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    }
  }

  void _onNavTap(int index) {
    if (index == 2) {
      _openLoadBoard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = _auth.currentUser?.username ?? 'Driver';
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final currentDate =
        '${months[now.month - 1]}, ${now.day.toString().padLeft(2, '0')}, ${now.year}';

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Container(
            height: 350,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFCE9FFC), Color(0xFFF8F9FA)],
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadHomeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color(0xFF1E1128),
                            child: Text(
                              username.isNotEmpty ? username[0].toUpperCase() : 'D',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1128),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'WELCOME ${username.toUpperCase()}!',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.search, size: 20, color: Colors.white70),
                                const SizedBox(width: 15),
                                const Icon(Icons.notifications, size: 20, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Text(
                      currentDate,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '5th Avenue, New York, NYC',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Current Shipment',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Colors.black),
                      )),
                    if (!_loading && _shipments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text('No shipment available',
                                style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _openLoadBoard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Browse Loads'),
                            )
                          ],
                        ),
                      ),
                    if (!_loading && _shipments.isNotEmpty)
                      _buildShipmentCard(_shipments.first),
                    const SizedBox(height: 20),
                    if (!_loading && _vehicleProfile == null)
                      _buildProfileProgressCard(),
                    if (!_loading && _vehicleProfile != null)
                      Column(
                        children: [
                            Row(
                            children: [
                              Expanded(
                                  child: _buildActionCard(
                                      Icons.local_gas_station, 'Fuel log',
                                      onTap: () => Navigator.pushNamed(
                                          context, '/fuel_log'))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildActionCard(
                                      Icons.history, 'Maintenance\nHistory')),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildActionCard(
                                      Icons.payments, 'Earnings')),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildVehicleInfoCard(),
                        ],
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          if (_showCongrats)
            IgnorePointer(
              child: FadeTransition(
                opacity: _confettiOpacity,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: ScaleTransition(
                      scale: _cardScale,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8E5AF7).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.celebration,
                                size: 60,
                                color: Color(0xFF8E5AF7),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Congratulations!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1128),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Profile 100% Complete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8E5AF7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You can now book loads and start earning!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildProfileProgressCard() {
    return GestureDetector(
      onTap: _navigateToVehicleRegistration,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFE8E1FF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_outlined,
                      color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Your Profile',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Register your vehicle to start booking loads.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                 Text(
                  '50% Profile Completed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                 Spacer(),
                 Text(
                  '50%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.5,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildProgressStep('Account Setup', true),
                const SizedBox(width: 8),
                _buildProgressStep('Vehicle Reg.', false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(String label, bool completed) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: completed ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: completed
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: completed ? Colors.green : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    final profile = _vehicleProfile!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE8E1FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E5AF7).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_outlined,
                    color: Color(0xFF7A3FF2)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'This driver is cleared to book loads.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _navigateToVehicleRegistration,
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildVehicleSummaryChip('Equipment', profile.equipmentType,
                  accent: true),
              _buildVehicleSummaryChip('Plate', profile.licensePlate),
              _buildVehicleSummaryChip('State', profile.state),
              _buildVehicleSummaryChip('VIN', profile.vinNumber),
              _buildVehicleSummaryChip('Year', profile.year),
              _buildVehicleSummaryChip(
                  'Make / Model', '${profile.make} ${profile.model}'),
              _buildVehicleSummaryChip('Trailer',
                  '${profile.trailerLength} ft x ${profile.trailerWidth} ft'),
              _buildVehicleSummaryChip(
                  'Max Weight', '${profile.maxWeight} lbs'),
              _buildVehicleSummaryChip(
                  'Fleet ID',
                  profile.internalFleetId.isEmpty
                      ? 'Not set'
                      : profile.internalFleetId),
              _buildVehicleSummaryChip('Registration Doc',
                  profile.registrationDocumentLabel.isNotEmpty
                      ? profile.registrationDocumentLabel
                      : 'Not uploaded'),
              _buildVehicleSummaryChip('Insurance Doc',
                  profile.insuranceDocumentLabel.isNotEmpty
                      ? profile.insuranceDocumentLabel
                      : 'Not uploaded'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSummaryChip(String label, String value,
      {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent
            ? const Color(0xFF8E5AF7).withOpacity(0.12)
            : const Color(0xFFF7F6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: accent
                ? const Color(0xFF8E5AF7).withOpacity(0.2)
                : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accent ? const Color(0xFF7A3FF2) : Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentCard(Shipment s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.loadId.isNotEmpty ? s.loadId : '-',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18)),
          const SizedBox(height: 2),
          Text(s.commodity.isNotEmpty ? s.commodity : '-',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1, thickness: 1),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.radio_button_checked,
                      color: Colors.white, size: 18),
                  Container(width: 2, height: 35, color: Colors.white24),
                  const Icon(Icons.radio_button_unchecked,
                      color: Colors.white, size: 18),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.origin.isNotEmpty ? s.origin : '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15)),
                    Text(s.originDate.isNotEmpty ? s.originDate : '-',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 16),
                    Text(s.destination.isNotEmpty ? s.destination : '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15)),
                    Text(s.destinationDate.isNotEmpty ? s.destinationDate : '-',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                            context, '/shipment_detail',
                            arguments: s)
                        .then((_) => _loadHomeData()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Go to Map',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _cancelShipment(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final user = _auth.currentUser;
    final String username = user?.username ?? 'Driver';
    final String initial =
        username.isNotEmpty ? username[0].toUpperCase() : 'D';

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFC07BFE), Color(0xFF8A30FA)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A30FA),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user?.email ?? 'driver@flow.com',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.black87),
            title: const Text('Manage Profile',
                style: TextStyle(color: Colors.black87)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping, color: Colors.black87),
            title: const Text('Vehicle Management',
                style: TextStyle(color: Colors.black87)),
            onTap: () {
              Navigator.pop(context);
              _navigateToVehicleRegistration();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              _auth.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
