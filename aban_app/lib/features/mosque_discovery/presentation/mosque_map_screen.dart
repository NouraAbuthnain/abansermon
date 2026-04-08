import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_back_button.dart';

class MosqueMapScreen extends StatefulWidget {
  const MosqueMapScreen({super.key});

  @override
  State<MosqueMapScreen> createState() => _MosqueMapScreenState();
}

class _MosqueMapScreenState extends State<MosqueMapScreen> {
  // Center of Riyadh
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(24.7136, 46.6753),
    zoom: 12.0,
  );

  GoogleMapController? _controller;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    // Generate dummy markers
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('mosque_1'),
          position: const LatLng(24.7136, 46.6753),
          infoWindow:
              const InfoWindow(title: 'Al-Rajhi Mosque', snippet: 'Live Now'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () => _showMosqueDetailsBottomSheet(
              context, true, 'Al-Rajhi Mosque', '1.2 km'),
        ),
        Marker(
          markerId: const MarkerId('mosque_2'),
          position: const LatLng(24.7400, 46.6800),
          infoWindow: const InfoWindow(
              title: 'King Khalid Grand Mosque', snippet: 'Offline'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onTap: () => _showMosqueDetailsBottomSheet(
              context, false, 'King Khalid Grand Mosque', '2.5 km'),
        ),
      };
    });
  }

  void _showMosqueDetailsBottomSheet(
      BuildContext context, bool isLive, String name, String distance) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 8,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.doveGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLive
                                      ? AppColors.accentGreen
                                      : AppColors.doveGray,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLive) ...[
                                      const Icon(Icons.wifi_tethering,
                                          size: 12, color: AppColors.pureWhite),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      isLive ? 'Live Now' : 'Offline',
                                      style: TextStyle(
                                        color: isLive
                                            ? AppColors.pureWhite
                                            : AppColors.slate,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.location_on,
                                  size: 16, color: AppColors.slate),
                              const SizedBox(width: 8),
                              Text(distance,
                                  style: const TextStyle(
                                      color: AppColors.slate, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                AppButton(
                  label: isLive ? 'Join Live Translation' : 'No Active Khutbah',
                  onPressed: isLive
                      ? () {
                          Navigator.pop(context);
                          context.push('/live/mock_session_${name.hashCode}');
                        }
                      : null,
                  variant: AppButtonVariant.primary,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  variant: AppButtonVariant.tertiary,
                  isFullWidth: false,
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // If on web, show a styled placeholder because Google Maps JS SDK requires an API Key
          if (kIsWeb)
            Container(
              color: AppColors.cloud,
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 64, color: AppColors.slate),
                  const SizedBox(height: 16),
                  Text(
                    'Interactive Map (Mobile Only)\nAvailable on iOS/Android or with an API Key.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.slate,
                        ),
                  ),
                ],
              ),
            )
          else
            GoogleMap(
              initialCameraPosition: _initialPosition,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
              onMapCreated: (controller) => _controller = controller,
            ),

          // Custom Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                const AppBackButton(),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppStyles.cardShadow,
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: AppColors.slate),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text("Search area...",
                              style: TextStyle(
                                  color: AppColors.slate, fontSize: 14)),
                        ),
                        Icon(Icons.mic, color: AppColors.primaryTeal),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Location Button
          if (!kIsWeb)
            Positioned(
              bottom: 32,
              right: 16,
              child: InkWell(
                onTap: () {
                  _controller?.animateCamera(
                      CameraUpdate.newCameraPosition(_initialPosition));
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    shape: BoxShape.circle,
                    boxShadow: AppStyles.cardShadow,
                  ),
                  child:
                      const Icon(Icons.my_location, color: AppColors.primaryTeal),
                ),
              ),
            )
        ],
      ),
    );
  }
}
