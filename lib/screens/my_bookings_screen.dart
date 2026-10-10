import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import 'booking_success_screen.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchMyBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _confirmCancellation(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: const Text('Cancel Reservation?', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to cancel your stay at ${booking.hotelTitle}? A refund of ₹${booking.pricing.totalAmount.toInt()} will be credited according to policy.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Booking', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await ref.read(bookingProvider.notifier).cancelReservation(booking.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Reservation cancelled successfully.' : 'Failed to cancel reservation.'),
                      backgroundColor: success ? Colors.redAccent : Colors.grey,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);

    final activeBookings = bookingState.bookings.where((b) => b.status == 'confirmed').toList();
    final pastBookings = bookingState.bookings.where((b) => b.status != 'confirmed').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Hotel Bookings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Active (${activeBookings.length})'),
            Tab(text: 'History (${pastBookings.length})'),
          ],
        ),
      ),
      body: bookingState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(activeBookings, isActive: true),
                _buildBookingsList(pastBookings, isActive: false),
              ],
            ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> list, {required bool isActive}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.hotel_class_outlined : Icons.history,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active hotel reservations' : 'No past bookings found',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isActive
                  ? 'Plan your next getaway and explore boutique hotels!'
                  : 'Completed and cancelled stays will appear here.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ref.read(bookingProvider.notifier).fetchMyBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final b = list[index];
          final isConfirmed = b.status == 'confirmed';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel image banner with status tag
                Stack(
                  children: [
                    Image.network(
                      b.hotelImage,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: AppColors.cardBorder,
                        child: const Center(
                          child: Icon(Icons.hotel, color: AppColors.textSecondary, size: 36),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isConfirmed ? AppColors.success : Colors.redAccent,
                          ),
                        ),
                        child: Text(
                          b.status.toUpperCase(),
                          style: TextStyle(
                            color: isConfirmed ? AppColors.success : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          b.bookingReference,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Details Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.hotelTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${b.roomType} • ${b.numberOfNights} Night${b.numberOfNights > 1 ? "s" : ""}',
                        style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${_formatDate(b.checkInDate)} - ${_formatDate(b.checkOutDate)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Guest: ${b.contactDetails.name}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            '₹${b.pricing.totalAmount.toInt()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.cardBorder, height: 1),
                      const SizedBox(height: 12),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                            label: const Text('View Pass'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingSuccessScreen(booking: b),
                                ),
                              );
                            },
                          ),
                          if (isConfirmed) ...[
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: const Text('Cancel Stay'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                              ),
                              onPressed: () => _confirmCancellation(context, b),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
