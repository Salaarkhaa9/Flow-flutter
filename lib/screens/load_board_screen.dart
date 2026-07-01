import 'package:flutter/material.dart';
import '../models/load.dart';
import '../services/load_service.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class LoadBoardScreen extends StatefulWidget {
  const LoadBoardScreen({super.key});

  @override
  State<LoadBoardScreen> createState() => _LoadBoardScreenState();
}

class _LoadBoardScreenState extends State<LoadBoardScreen> {
  late Future<List<Load>> _loadsFuture;
  final LoadService _loadService = LoadService();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool _checkingProfile = true;
  bool _profileComplete = false;
  bool _hasId = false;
  bool _hasCdl = false;

  @override
  void initState() {
    super.initState();
    _checkProfileCompleteness();
    _loadsFuture = _loadService.getAvailableLoads();
  }

  Future<void> _checkProfileCompleteness() async {
    final auth = AuthService();
    final user = auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _checkingProfile = false;
          _profileComplete = false;
        });
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final emailKey = user.email;
    final hasId = prefs.getBool('${emailKey}_id_uploaded') ?? false;
    final hasCdl = prefs.getBool('${emailKey}_cdl_uploaded') ?? false;
    final vehicle = auth.getVehicleProfile(user.id);
    final hasVehicle = vehicle != null;

    if (mounted) {
      setState(() {
        _hasId = hasId;
        _hasCdl = hasCdl;
        _profileComplete = hasId && hasCdl && hasVehicle;
        _checkingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0a2226)),
        ),
      );
    }

    Widget mainBody = Stack(
      children: [
        // Background Gradient
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0a2226),
                Color(0xFFFAFAFA),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              // Top Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a2226),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Load Board',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search origin, destination...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFilterPill('All'),
                    _buildFilterPill('Best Pay'),
                    _buildFilterPill('Nearby'),
                    _buildFilterPill('Flatbed'),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '🔥 EXPIRING SOON',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF71717A),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Load List
              Expanded(
                child: FutureBuilder<List<Load>>(
                  future: _loadsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final loads = snapshot.data ?? [];

                    var filteredLoads = loads.where((l) {
                      if (_searchQuery.isEmpty) return true;
                      return l.origin.toLowerCase().contains(_searchQuery) ||
                          l.destination.toLowerCase().contains(_searchQuery) ||
                          l.commodity.toLowerCase().contains(_searchQuery) ||
                          l.loadNumber.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (_selectedFilter == 'Best Pay') {
                      filteredLoads.sort((a, b) {
                        double rateA = double.tryParse(
                                a.rate.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                            0;
                        double rateB = double.tryParse(
                                b.rate.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                            0;
                        return rateB.compareTo(rateA);
                      });
                    } else if (_selectedFilter == 'Flatbed') {
                      filteredLoads = filteredLoads.where((l) {
                        return l.status.toLowerCase().contains('flatbed') ||
                            l.requirements.any(
                                (r) => r.toLowerCase().contains('flatbed'));
                      }).toList();
                    } else if (_selectedFilter == 'Nearby') {
                      filteredLoads = filteredLoads
                          .where((l) => l.distance.toLowerCase().contains('km'))
                          .toList();
                    }

                    if (filteredLoads.isEmpty) {
                      return const Center(
                        child: Text(
                          'No matches',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, bottom: 100),
                      itemCount: filteredLoads.length,
                      itemBuilder: (context, index) {
                        return _buildLoadCard(filteredLoads[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!_profileComplete) {
      mainBody = Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: mainBody,
          ),
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 4,
                shadowColor: const Color(0xFF0a2226).withOpacity(0.10),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a2226).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF0a2226),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Profile Incomplete',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0a2226),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please complete your profile verification to unlock access to the load board.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.black54,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final auth = AuthService();
                            final user = auth.currentUser;
                            if (user != null) {
                              if (!_hasId) {
                                Navigator.pushReplacementNamed(
                                    context, '/id_upload',
                                    arguments: user.email);
                              } else if (!_hasCdl) {
                                Navigator.pushReplacementNamed(
                                    context, '/cdl_upload',
                                    arguments: user.email);
                              } else {
                                Navigator.pushReplacementNamed(
                                    context, '/vehicle_registration',
                                    arguments: false);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFd6ff00),
                            foregroundColor: const Color(0xFF0a2226),
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: Text(
                            'Complete Profile',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/home', (route) => false);
                        },
                        child: Text(
                          'Go Back',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF71717A),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBody: true,
      body: mainBody,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/order_history');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/stats');
          }
        },
      ),
    );
  }

  Widget _buildFilterPill(String title) {
    final isSelected = _selectedFilter == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0a2226) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E4E7)),
          boxShadow: [
            if (!isSelected)
              BoxShadow(color: const Color(0xFF0a2226).withOpacity(0.03), blurRadius: 5),
          ],
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : const Color(0xFF71717A),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadCard(Load load) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0a2226).withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(load.loadNumber,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0a2226))),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.bolt,
                            color: Colors.orange.shade400, size: 14),
                        Text('1h left',
                            style: GoogleFonts.inter(
                                color: Colors.orange.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(load.rate,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF0a2226))),
                  Text('↑ ${load.rateUnit}',
                      style: GoogleFonts.inter(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  Text(load.distance,
                      style: GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 10)),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),

          // Route
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(load.origin,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0a2226))),
                    Text(load.originState,
                        style:
                            GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 10)),
                    const SizedBox(height: 4),
                    Text('${load.originDate} • ${load.originTime}',
                        style:
                            GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 10)),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.teal),
                      Container(
                          width: 40, height: 2, color: Colors.grey.shade300),
                      const Icon(Icons.circle, size: 8, color: Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.local_shipping,
                      color: Colors.green, size: 16),
                  Text(load.distance,
                      style: GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 10)),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(load.destination,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0a2226))),
                    Text(load.destinationState,
                        style:
                            GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 10)),
                    const SizedBox(height: 4),
                    Text('${load.destinationDate} • ${load.destinationTime}',
                        style:
                            GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoPill(load.status, Colors.teal.shade50, Colors.teal),
              ...load.requirements.map((req) =>
                  _buildInfoPill(req, Colors.blue.shade50, Colors.blue)),
              _buildInfoPill(load.weight, Colors.grey.shade100, Colors.black87),
              _buildInfoPill(
                  load.commodity, Colors.orange.shade50, Colors.orange),
            ],
          ),
          const SizedBox(height: 15),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 10),

          // Broker & Actions
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                    color: const Color(0xFF0a2226), borderRadius: BorderRadius.circular(8)),
                child: Center(
                    child: Text('CH',
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cargohub Brokers',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF0a2226))),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 12),
                        Text(' 4.9 • 312 loads',
                            style: GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.phone, color: Colors.green, size: 18),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/load_details',
                    arguments: load),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0a2226),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
                child: Text('Load Details',
                    style:
                        GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoPill(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: TextStyle(
              color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
