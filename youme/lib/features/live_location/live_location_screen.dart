import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/wood_app_bar.dart';
import '../../../core/widgets/wood_button.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/app_constants.dart';

class LiveLocationScreen extends StatefulWidget {
  final String conversationId;
  const LiveLocationScreen({super.key, required this.conversationId});
  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _myPosition;
  Map<String, dynamic>? _partnerLocation;
  bool _isSharingLive = false;
  bool _isLoadingLocation = false;
  Timer? _shareTimer;
  Timer? _watchTimer;
  late AnimationController _pulseCtrl;
  late AnimationController _entryCtrl;
  Set<Marker> _markers = {};
  static const _defaultLat = 48.8566;
  static const _defaultLng = 2.3522;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _loadMyPosition();
    _watchPartnerLocation();
  }

  @override
  void dispose() {
    _shareTimer?.cancel();
    _watchTimer?.cancel();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _mapController?.dispose();
    if (_isSharingLive) _stopSharing();
    super.dispose();
  }

  Future<void> _loadMyPosition() async {
    setState(() => _isLoadingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _myPosition = pos;
        _isLoadingLocation = false;
      });
      _updateMarkers();
    } catch (_) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _watchPartnerLocation() {
    _watchTimer = Timer.periodic(
      AppConstants.liveLocationInterval,
      (_) => _fetchPartnerLocation(),
    );
    _fetchPartnerLocation();
  }

  Future<void> _fetchPartnerLocation() async {
    try {
      final data = await SupabaseService.client
          .from(SupabaseKeys.liveLocations)
          .select()
          .eq('conversation_id', widget.conversationId)
          .neq('user_id', SupabaseService.currentUserId ?? '')
          .maybeSingle();
      if (data != null && mounted) {
        setState(() => _partnerLocation = data);
        _updateMarkers();
      }
    } catch (_) {}
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    if (_myPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: LatLng(_myPosition!.latitude, _myPosition!.longitude),
        infoWindow: const InfoWindow(title: 'Ma position'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }
    if (_partnerLocation != null) {
      final lat = (_partnerLocation!['latitude'] as num).toDouble();
      final lng = (_partnerLocation!['longitude'] as num).toDouble();
      markers.add(Marker(
        markerId: const MarkerId('partner'),
        position: LatLng(lat, lng),
        infoWindow: const InfoWindow(title: 'Partenaire'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      ));
    }
    setState(() => _markers = markers);
  }

  Future<void> _toggleSharing() async {
    if (_isSharingLive) {
      await _stopSharing();
    } else {
      await _startSharing();
    }
  }

  Future<void> _startSharing() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null || _myPosition == null) return;
    setState(() => _isSharingLive = true);
    await _publishLocation();
    _shareTimer = Timer.periodic(AppConstants.liveLocationInterval, (_) async {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _myPosition = pos);
      _updateMarkers();
      await _publishLocation();
    });
  }

  Future<void> _stopSharing() async {
    _shareTimer?.cancel();
    setState(() => _isSharingLive = false);
    try {
      await SupabaseService.client
          .from(SupabaseKeys.liveLocations)
          .delete()
          .eq('user_id', SupabaseService.currentUserId ?? '')
          .eq('conversation_id', widget.conversationId);
    } catch (_) {}
  }

  Future<void> _publishLocation() async {
    if (_myPosition == null) return;
    try {
      await SupabaseService.client.from(SupabaseKeys.liveLocations).upsert({
        'user_id': SupabaseService.currentUserId,
        'conversation_id': widget.conversationId,
        'latitude': _myPosition!.latitude,
        'longitude': _myPosition!.longitude,
        'accuracy': _myPosition!.accuracy,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  LatLng get _center {
    if (_myPosition != null) {
      return LatLng(_myPosition!.latitude, _myPosition!.longitude);
    }
    return const LatLng(_defaultLat, _defaultLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyTop,
      appBar: WoodAppBar(
        title: 'Position en direct',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isSharingLive
                ? AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2 + _pulseCtrl.value * 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withOpacity(0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.success.withOpacity(0.6),
                                    blurRadius: 4)
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Live',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _entryCtrl,
              child: _buildMap(),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (ctrl) => _mapController = ctrl,
          initialCameraPosition: CameraPosition(target: _center, zoom: 15),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
        ),
        // Recenter button
        Positioned(
          bottom: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_center, 15),
              );
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [AppColors.woodLight, AppColors.woodDark],
                ),
                border: Border.all(color: AppColors.goldBorder.withOpacity(0.6), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.my_location, color: AppColors.goldLight, size: 22),
            ),
          ),
        ),
        if (_isLoadingLocation)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.goldPrimary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E1A0A), Color(0xFF1A0A02)],
        ),
      ),
      child: Column(
        children: [
          if (_partnerLocation != null) _buildPartnerInfo(),
          const SizedBox(height: 14),
          WoodButton(
            label: _isSharingLive
                ? 'Arrêter le partage'
                : 'Partager ma position en direct',
            icon: _isSharingLive ? Icons.location_off : Icons.location_on,
            width: double.infinity,
            accentColor: _isSharingLive ? AppColors.error : AppColors.success,
            onPressed: _myPosition == null ? null : _toggleSharing,
          ),
          if (_myPosition == null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadMyPosition,
              icon: const Icon(Icons.refresh, color: AppColors.turquoise),
              label: const Text('Actualiser la position',
                  style: TextStyle(color: AppColors.turquoise)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerInfo() {
    final lastUpdate = _partnerLocation!['updated_at'] as String?;
    DateTime? dt;
    if (lastUpdate != null) dt = DateTime.tryParse(lastUpdate);
    final diff = dt != null ? DateTime.now().difference(dt).inSeconds : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Partenaire partage sa position',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                if (diff != null)
                  Text(
                    'Mis à jour il y a ${diff}s',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              final lat = (_partnerLocation!['latitude'] as num).toDouble();
              final lng = (_partnerLocation!['longitude'] as num).toDouble();
              _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.5)),
              ),
              child: const Text('Voir',
                  style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
