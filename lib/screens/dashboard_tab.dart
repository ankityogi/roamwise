import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../providers/navigation_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/explore_provider.dart';
import 'hotel_search_screen.dart';
import 'my_bookings_screen.dart';
import 'vision_scanner_screen.dart';
import 'offline_guide_screen.dart';
import 'itinerary_route_map_screen.dart';
import 'transport_screen.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  void _showEmergencyDialog(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final String cityString = locationState.currentCity ?? 'Surat, India';
    
    String country = 'India';
    if (cityString.contains(',')) {
      country = cityString.split(',').last.trim();
    } else {
      country = cityString.trim();
    }

    String emergencyNumber = '112';
    String policeNumber = '100';
    String ambulanceNumber = '108';
    String fireNumber = '101';

    final lowerCountry = country.toLowerCase();
    if (lowerCountry == 'united states' || lowerCountry == 'usa' || lowerCountry == 'canada') {
      emergencyNumber = '911';
      policeNumber = '911';
      ambulanceNumber = '911';
      fireNumber = '911';
    } else if (lowerCountry == 'united kingdom' || lowerCountry == 'uk' || lowerCountry == 'ireland') {
      emergencyNumber = '999';
      policeNumber = '999';
      ambulanceNumber = '999';
      fireNumber = '999';
    } else if (lowerCountry == 'australia') {
      emergencyNumber = '000';
      policeNumber = '000';
      ambulanceNumber = '000';
      fireNumber = '000';
    } else if (lowerCountry == 'japan') {
      emergencyNumber = '110 / 119';
      policeNumber = '110';
      ambulanceNumber = '119';
      fireNumber = '119';
    } else if (lowerCountry == 'france' || lowerCountry == 'germany' || lowerCountry == 'spain' || lowerCountry == 'italy' || lowerCountry == 'europe') {
      emergencyNumber = '112';
      policeNumber = '112';
      ambulanceNumber = '112';
      fireNumber = '112';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Emergency Services',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You are currently in $cityString. Standard emergency number is $emergencyNumber.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildEmergencyContactRow(Icons.local_police, 'Police', policeNumber),
              const Divider(color: AppColors.cardBorder, height: 16),
              _buildEmergencyContactRow(Icons.medical_services, 'Medical / Ambulance', ambulanceNumber),
              const Divider(color: AppColors.cardBorder, height: 16),
              _buildEmergencyContactRow(Icons.local_fire_department, 'Fire', fireNumber),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showSOSCallingOverlay(context, ref);
              },
              icon: const Icon(Icons.emergency_share, size: 18),
              label: const Text('Simulate SOS Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSOSCallingOverlay(BuildContext context, WidgetRef ref) {
    final locationState = ref.read(locationProvider);
    final position = locationState.currentPosition;
    final double lat = position?.latitude ?? 48.8566;
    final double lng = position?.longitude ?? 2.3522;
    final String city = locationState.currentCity ?? 'Paris, France';

    final authState = ref.read(authProvider);
    final contacts = authState.user?.emergencyContacts ?? [];

    String contactsMessage = 'Broadcasting distress coordinates to local dispatch...';
    if (contacts.isNotEmpty) {
      final namesList = contacts.map((c) => c.name).join(' & ');
      contactsMessage = 'SOS message dispatched to emergency contacts: $namesList';
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0808),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.3),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withValues(alpha: 0.2 / value),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withValues(alpha: 0.4 / value),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.emergency, size: 48, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                const Text(
                  'SOS EMERGENCY BROADCAST',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    contactsMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Transmitting coordinates:\n${lat.toStringAsFixed(6)}° N, ${lng.toStringAsFixed(6)}° E ($city)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.call_end, size: 24),
                        label: const Text('CANCEL SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyContactRow(IconData icon, String label, String number) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
          child: Icon(icon, color: Colors.redAccent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                number,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.phone, color: AppColors.accent, size: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch trips from tripProvider to display actual user itinerary details
    final tripState = ref.watch(tripProvider);
    final trips = tripState.trips;

    // Use the most recently generated trip as the active itinerary card
    final activeTrip = trips.isNotEmpty ? trips.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, Adventurer!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        activeTrip != null
                            ? activeTrip.destination
                            : (ref.watch(locationProvider).currentCity ?? 'Surat, India'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: const Text('A', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Destination Search Bar redirecting to Explore tab
          TextField(
            readOnly: true,
            onTap: () {
              ref.read(activeTabProvider.notifier).state = 1; // Route to Explore
            },
            decoration: InputDecoration(
              hintText: 'Where to next?',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: const Icon(Icons.tune, color: AppColors.accent),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Action Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Tools',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.receipt_long, size: 14, color: AppColors.accent),
                    SizedBox(width: 4),
                    Text(
                      'My Bookings',
                      style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              _buildQuickToolItem(
                context,
                icon: Icons.hotel_rounded,
                label: 'Hotels',
                color: const Color(0xFF00F0FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HotelSearchScreen()),
                  );
                },
              ),
              _buildQuickToolItem(
                context,
                icon: Icons.document_scanner,
                label: 'AI Lens',
                color: const Color(0xFFFF9F0A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VisionScannerScreen()),
                  );
                },
              ),
              _buildQuickToolItem(
                context,
                icon: Icons.offline_bolt_rounded,
                label: 'Offline Guide',
                color: const Color(0xFF00E676),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OfflineGuideScreen()),
                  );
                },
              ),
              _buildQuickToolItem(
                context,
                icon: Icons.flight_takeoff_rounded,
                label: 'Transit',
                color: const Color(0xFFBD00FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransportScreen()),
                  );
                },
              ),
              _buildQuickToolItem(
                context,
                icon: Icons.emergency,
                label: 'Emergency',
                color: Colors.redAccent,
                onTap: () => _showEmergencyDialog(context, ref),
              ),
              _buildQuickToolItem(
                context,
                icon: Icons.g_translate,
                label: 'Translate',
                color: AppColors.accent,
                onTap: () {
                  ref.read(activeTabProvider.notifier).state = 2; // AI Chat/Translator tab
                },
              ),
              _buildQuickToolItem(
                context,
                icon: Icons.favorite,
                label: 'Saved',
                color: AppColors.primary,
                onTap: () => _showSavedBookmarksPanel(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hotel Booking Feature Promotion Banner
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HotelSearchScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.surface,
                    AppColors.primary.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.bed_rounded, color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book Boutique Stays & Resorts',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Instant reservation • Curated luxury hotels',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Active Trip Tracker
          Text(
            'Active Itinerary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              ref.read(activeTabProvider.notifier).state = 3; // Route to Planner
            },
            child: Card(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface,
                      AppColors.surface.withBlue(45),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: activeTrip != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${activeTrip.daysCount} days total',
                                style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            activeTrip.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                activeTrip.dates,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: const LinearProgressIndicator(
                              value: 0.25, // Mock progress indicating itinerary start
                              backgroundColor: AppColors.background,
                              color: AppColors.primary,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItineraryRouteMapScreen(trip: activeTrip),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.route, size: 16, color: AppColors.accent),
                                  SizedBox(width: 8),
                                  Text(
                                    'Explore Day Route on Map',
                                    style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, size: 12, color: AppColors.accent),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.add_road, color: AppColors.accent, size: 36),
                          const SizedBox(height: 12),
                          const Text(
                            'No active itineraries yet ',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Plan your next trip and build custom day-by-day schedules in seconds using AI.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(activeTabProvider.notifier).state = 3; // Route to Planner
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Generate Trip with AI', style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Horizontal Recommendations Carousel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Recommendations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(activeTabProvider.notifier).state = 1; // Route to Explore
                },
                child: const Text('See All', style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildRecommendationCard(
                  context,
                  title: 'Eiffel Tower',
                  location: 'Paris, France',
                  rating: 4.8,
                  category: 'Sightseeing',
                  icon: Icons.tour,
                ),
                _buildRecommendationCard(
                  context,
                  title: 'Fushimi Inari',
                  location: 'Kyoto, Japan',
                  rating: 4.9,
                  category: 'Culture',
                  icon: Icons.temple_hindu,
                ),
                _buildRecommendationCard(
                  context,
                  title: 'Colosseum',
                  location: 'Rome, Italy',
                  rating: 4.7,
                  category: 'History',
                  icon: Icons.account_balance,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickToolItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context, {
    required String title,
    required String location,
    required double rating,
    required String category,
    required IconData icon,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.accent, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavedBookmarksPanel(BuildContext context, WidgetRef ref) {
    ref.read(bookmarkProvider.notifier).fetchBookmarks();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final bookmarkState = ref.watch(bookmarkProvider);
            final bookmarks = bookmarkState.bookmarks;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text(
                              'Saved Bookmarks',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (bookmarkState.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: AppColors.accent),
                        ),
                      )
                    else if (bookmarks.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(Icons.favorite_border, size: 48, color: AppColors.cardBorder),
                              SizedBox(height: 12),
                              Text(
                                'No saved places yet.',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Go to the Explore tab and bookmark\nyour favorite travel destinations.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: bookmarks.length,
                          itemBuilder: (context, index) {
                            final bookmark = bookmarks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(bookmark.category),
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  bookmark.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${bookmark.distance} | ${bookmark.price}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () {
                                        ref.read(bookmarkProvider.notifier).deleteBookmark(bookmark.id);
                                      },
                                    ),
                                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                                  ],
                                ),
                                onTap: () {
                                  ref.read(activeTabProvider.notifier).state = 1;
                                  
                                  final place = PlaceModel(
                                    title: bookmark.title,
                                    category: bookmark.category,
                                    rating: bookmark.rating,
                                    price: bookmark.price,
                                    distance: bookmark.distance,
                                    latitude: bookmark.latitude,
                                    longitude: bookmark.longitude,
                                  );
                                  
                                  ref.read(exploreProvider.notifier).setCustomPlaces([place]);
                                  
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Hotels':
        return Icons.hotel;
      case 'Dining':
        return Icons.restaurant;
      case 'Sights':
        return Icons.photo_camera;
      case 'Transit':
        return Icons.directions_bus;
      default:
        return Icons.place;
    }
  }
}
