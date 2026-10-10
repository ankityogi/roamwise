import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../models/hotel_model.dart';
import '../providers/hotel_provider.dart';
import 'hotel_booking_screen.dart';

class HotelDetailScreen extends ConsumerStatefulWidget {
  final HotelModel hotel;

  const HotelDetailScreen({super.key, required this.hotel});

  @override
  ConsumerState<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends ConsumerState<HotelDetailScreen> {
  late RoomTypeModel _selectedRoom;

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.hotel.roomTypes.first;
  }

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('pool')) return Icons.pool;
    if (lower.contains('breakfast')) return Icons.free_breakfast;
    if (lower.contains('spa')) return Icons.spa;
    if (lower.contains('fitness') || lower.contains('gym')) return Icons.fitness_center;
    if (lower.contains('shuttle') || lower.contains('transfer')) return Icons.airport_shuttle;
    if (lower.contains('room service')) return Icons.room_service;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('restaurant') || lower.contains('dining')) return Icons.restaurant;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final hotelState = ref.watch(hotelProvider);
    final nights = hotelState.checkOutDate.difference(hotelState.checkInDate).inDays;
    final validNights = nights > 0 ? nights : 1;
    final subtotal = _selectedRoom.pricePerNight * validNights;

    return Scaffold(
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Cover Image
                Stack(
                  children: [
                    Image.network(
                      widget.hotel.image,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 280,
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.hotel, size: 64, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                              child: IconButton(
                                icon: const Icon(Icons.share_outlined, color: Colors.white),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Hotel link copied to clipboard!'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Main Info Section
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.hotel.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.accent),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  widget.hotel.rating.toStringAsFixed(1),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.hotel.address.isNotEmpty ? widget.hotel.address : widget.hotel.city,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        'About This Stay',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.hotel.description,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Property Amenities
                      const Text(
                        'Property Amenities',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: widget.hotel.amenities.map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getAmenityIcon(amenity), size: 16, color: AppColors.accent),
                                const SizedBox(width: 8),
                                Text(
                                  amenity,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // Available Room Types
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Room Type',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$validNights Night${validNights > 1 ? "s" : ""}',
                            style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Column(
                        children: widget.hotel.roomTypes.map((room) {
                          final isSelected = _selectedRoom.id == room.id;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedRoom = room;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.accent : AppColors.cardBorder,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        room.name,
                                        style: TextStyle(
                                          color: isSelected ? AppColors.accent : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Radio<String>(
                                        value: room.id,
                                        groupValue: _selectedRoom.id,
                                        activeColor: AppColors.accent,
                                        onChanged: (_) {
                                          setState(() {
                                            _selectedRoom = room;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.bed_outlined, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(room.bed, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text('Max ${room.maxGuests} Guests', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: room.features.map((f) {
                                      return Text(
                                        '• $f',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '₹${room.pricePerNight.toInt()} / night',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Checkout Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, -4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total for $validNights night${validNights > 1 ? "s" : ""}:',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        Text(
                          '₹${subtotal.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HotelBookingScreen(
                              hotel: widget.hotel,
                              selectedRoom: _selectedRoom,
                              checkInDate: hotelState.checkInDate,
                              checkOutDate: hotelState.checkOutDate,
                              numberOfNights: validNights,
                              guestsCount: hotelState.guestsCount,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: const Text('Reserve Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
