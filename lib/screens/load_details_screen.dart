import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/load.dart';
import '../services/auth_service.dart';
import '../services/load_service.dart';
import '../services/shipment_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadDetailsScreen extends StatefulWidget {
  final Load load;

  const LoadDetailsScreen({
    super.key,
    required this.load,
  });

  @override
  State<LoadDetailsScreen> createState() => _LoadDetailsScreenState();
}

class _LoadDetailsScreenState extends State<LoadDetailsScreen> {
  late Load _load;
  bool _isLoading = false;
  final AuthService _auth = AuthService();
  final LoadService _loadService = LoadService();
  final ShipmentService _shipmentService = ShipmentService();
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;
  bool _mapLoading = true;

  static const _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const _osrmBase = 'https://router.project-osrm.org/route/v1/driving';

  @override
  void initState() {
    super.initState();
    _load = widget.load;
    _buildRoute();
  }

  Future<LatLng?> _geocode(String place) async {
    final uri = Uri.parse(
        '$_nominatimBase/search?q=${Uri.encodeQueryComponent(place)}&format=json&limit=1');
    final resp = await http.get(uri, headers: {'User-Agent': 'FlowApp/1.0'});
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as List;
      if (data.isNotEmpty) {
        return LatLng(
          double.parse(data[0]['lat']),
          double.parse(data[0]['lon']),
        );
      }
    }
    return null;
  }

  Future<void> _buildRoute() async {
    final originStr = '${_load.origin}, ${_load.originState}';
    final destStr = '${_load.destination}, ${_load.destinationState}';
    LatLng? o = await _geocode(originStr);
    await Future.delayed(const Duration(milliseconds: 600));
    LatLng? d = await _geocode(destStr);
    
    if (o == null) {
      await Future.delayed(const Duration(milliseconds: 600));
      o = await _geocode(_load.origin);
    }
    if (d == null) {
      await Future.delayed(const Duration(milliseconds: 600));
      d = await _geocode(_load.destination);
    }
    
    if (o == null || d == null) {
      if (mounted) setState(() => _mapLoading = false);
      return;
    }
    _originLatLng = o;
    _destinationLatLng = d;
    final uri = Uri.parse(
        '$_osrmBase/${o.longitude},${o.latitude};${d.longitude},${d.latitude}?overview=full&geometries=geojson');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      _routePoints =
          coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
    }
    if (mounted) setState(() => _mapLoading = false);
  }

  Future<void> _bookLoad() async {
    final user = _auth.currentUser;
    final hasVehicleProfile = user != null && _auth.hasVehicleProfile(user.id);

    if (!hasVehicleProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Complete vehicle registration before booking this load.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bookSuccess = await _loadService.bookLoad(_load.id);
      if (bookSuccess) {
        final addSuccess = await _shipmentService.addShipment(
          loadId: _load.loadNumber,
          commodity: _load.commodity,
          origin: _load.origin,
          destination: _load.destination,
          originDate: _load.originDate,
          destinationDate: _load.destinationDate,
          weight: _load.weight,
          rate: _load.rate,
        );

        if (addSuccess) {
          // Fire notification
          await NotificationService().notifyLoadBooked(_load.loadNumber);

          setState(() {
            _isLoading = false;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Load booked successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking load: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Details'),
                  const SizedBox(height: 12),
                  _buildDetailsGrid(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Additional Info'),
                  const SizedBox(height: 12),
                  _buildAdditionalInfoGrid(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: AppTheme.slateDeep,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        'Load Details',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _mapLoading
                ? Container(
                    color: AppTheme.slateLight,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.limeVoltage),
                    ),
                  )
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCameraFit: _routePoints.isNotEmpty
                          ? CameraFit.bounds(
                              bounds: LatLngBounds.fromPoints(_routePoints),
                              padding: const EdgeInsets.all(40),
                            )
                          : null,
                      initialCenter: _originLatLng ?? const LatLng(33.0, -89.0),
                      initialZoom: 6,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.flow_app',
                      ),
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 4.0,
                              color: AppTheme.slateDeep,
                            ),
                          ],
                        ),
                      if (_originLatLng != null && _destinationLatLng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _originLatLng!,
                              width: 32,
                              height: 32,
                              child: _buildMapMarker(Colors.green, Icons.circle, 14),
                            ),
                            Marker(
                              point: _destinationLatLng!,
                              width: 32,
                              height: 32,
                              child: _buildMapMarker(Colors.red, Icons.location_on, 18),
                            ),
                          ],
                        ),
                    ],
                  ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapMarker(Color color, IconData icon, double size) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _bookLoad,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.slateDeep,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppTheme.limeVoltage,
                      strokeWidth: 3,
                    ),
                  )
                : Text(
                    'Book Load • ${_load.rate}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTimelineStep(
            isFirst: true,
            pillText: 'PICK UP',
            pillColor: AppTheme.slateLight,
            pillTextColor: Colors.white,
            companyName: 'Fresh Food Inc.',
            address: '${_load.origin}, ${_load.originState}',
            date: '${_load.originDate} • ${_load.originTime}',
          ),
          _buildTimelineStep(
            isFirst: false,
            pillText: 'DELIVERY',
            pillColor: AppTheme.limeVoltage,
            pillTextColor: AppTheme.slateDeep,
            companyName: 'Smart Food Inc.',
            address: '${_load.destination}, ${_load.destinationState}',
            date: '${_load.destinationDate} • ${_load.destinationTime}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInfoItem(Icons.tag, 'Load ID', _load.loadNumber)),
              Expanded(child: _buildInfoItem(Icons.inventory_2_outlined, 'Commodity', _load.commodity)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppTheme.borderColor, height: 1),
          ),
          Row(
            children: [
              Expanded(child: _buildInfoItem(Icons.view_in_ar_outlined, 'Equipment', '4 Pallets')),
              Expanded(child: _buildInfoItem(Icons.scale_outlined, 'Weight', _load.weight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInfoItem(Icons.route_outlined, 'Distance', _load.distance)),
              Expanded(child: _buildInfoItem(Icons.timer_outlined, 'Est. Time', '25 mins')),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppTheme.borderColor, height: 1),
          ),
          Row(
            children: [
              Expanded(child: _buildInfoItem(Icons.monetization_on_outlined, 'Rate per mile', _load.rateUnit)),
              Expanded(child: _buildInfoItem(Icons.payments_outlined, 'Total Rate', _load.rate, valueColor: AppTheme.slateDeep)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required bool isFirst,
    required String pillText,
    required Color pillColor,
    required Color pillTextColor,
    required String companyName,
    required String address,
    required String date,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pillColor,
                border: Border.all(color: AppTheme.slateDeep, width: 3),
              ),
            ),
            if (isFirst)
              Container(
                width: 2,
                height: 80,
                color: AppTheme.borderColor,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pillText,
                    style: GoogleFonts.inter(
                      color: pillTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  companyName,
                  style: GoogleFonts.outfit(
                    color: AppTheme.slateDeep,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.slateDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (isFirst) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: AppTheme.slateDeep,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMid,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.slateDeep, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: valueColor ?? AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
