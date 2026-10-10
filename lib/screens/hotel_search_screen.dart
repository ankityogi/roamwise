import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../providers/hotel_provider.dart';
import '../providers/location_provider.dart';
import '../models/hotel_model.dart';
import 'hotel_detail_screen.dart';
import 'my_bookings_screen.dart';

class HotelSearchScreen extends ConsumerStatefulWidget {
  const HotelSearchScreen({super.key});

  @override
  ConsumerState<HotelSearchScreen> createState() => _HotelSearchScreenState();
}

class _HotelSearchScreenState extends ConsumerState<HotelSearchScreen> {
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final city = ref.read(locationProvider).currentCity ?? 'Surat';
      final cleanCity = city.contains(',') ? city.split(',').first.trim() : city;
      _cityController.text = cleanCity;
      ref.read(hotelProvider.notifier).fetchHotels(cleanCity);
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context, HotelState hotelState) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: hotelState.checkInDate,
        end: hotelState.checkOutDate,
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(hotelProvider.notifier).updateDates(picked.start, picked.end);
    }
  }

  void _showGuestsDialog(BuildContext context, HotelState hotelState) {
    int count = hotelState.guestsCount;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              title: const Text('Number of Guests', style: TextStyle(color: Colors.white)),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Guests', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.accent),
                        onPressed: count > 1
                            ? () {
                                setDialogState(() => count--);
                              }
                            : null,
                      ),
                      Text(
                        '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                        onPressed: count < 10
                            ? () {
                                setDialogState(() => count++);
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(hotelProvider.notifier).updateGuests(count);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final hotelState = ref.watch(hotelProvider);
    final nights = hotelState.checkOutDate.difference(hotelState.checkInDate).inDays;
    final validNights = nights > 0 ? nights : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Stays & Hotels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: AppColors.accent),
            tooltip: 'My Bookings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header Card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
            ),
            child: Column(
              children: [
                // Destination search input
                TextField(
                  controller: _cityController,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      ref.read(hotelProvider.notifier).fetchHotels(value.trim());
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Destination (e.g. Surat, Mumbai, Goa)...',
                    prefixIcon: const Icon(Icons.location_city, color: AppColors.accent),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: AppColors.accent),
                      onPressed: () {
                        if (_cityController.text.trim().isNotEmpty) {
                          ref.read(hotelProvider.notifier).fetchHotels(_cityController.text.trim());
                        }
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Date selector and Guests selector
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: InkWell(
                        onTap: () => _selectDateRange(context, hotelState),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Dates', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                    Text(
                                      '${_formatDate(hotelState.checkInDate)} - ${_formatDate(hotelState.checkOutDate)} ($validNights n)',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: () => _showGuestsDialog(context, hotelState),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline, size: 18, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Guests', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                  Text(
                                    '${hotelState.guestsCount} Guests',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Hotel List
          Expanded(
            child: hotelState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : hotelState.hotels.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.hotel_outlined, size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            const Text(
                              'No hotels found for this search.',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => ref.read(hotelProvider.notifier).fetchHotels('Surat'),
                              child: const Text('Reset Search'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: hotelState.hotels.length,
                        itemBuilder: (context, index) {
                          final hotel = hotelState.hotels[index];
                          return _buildHotelCard(context, hotel, validNights);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCard(BuildContext context, HotelModel hotel, int nights) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel Image & Rating Overlay
          Stack(
            children: [
              Image.network(
                hotel.image,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 170,
                    color: AppColors.cardBorder,
                    child: const Center(
                      child: Icon(Icons.hotel, size: 48, color: AppColors.textSecondary),
                    ),
                  );
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        hotel.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${hotel.reviewsCount})',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Hotel Details & Pricing
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hotel.address.isNotEmpty ? hotel.address : hotel.distance,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Amenities badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: hotel.amenities.take(3).map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        amenity,
                        style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.cardBorder, height: 1),
                const SizedBox(height: 12),

                // Price & CTA button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${hotel.pricePerNight.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '/ night + taxes',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HotelDetailScreen(hotel: hotel),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('View Rooms & Book', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
