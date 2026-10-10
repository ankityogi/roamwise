import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../models/hotel_model.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import 'booking_success_screen.dart';

class HotelBookingScreen extends ConsumerStatefulWidget {
  final HotelModel hotel;
  final RoomTypeModel selectedRoom;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfNights;
  final int guestsCount;

  const HotelBookingScreen({
    super.key,
    required this.hotel,
    required this.selectedRoom,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfNights,
    required this.guestsCount,
  });

  @override
  ConsumerState<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends ConsumerState<HotelBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _requestsController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(
      text: user != null && user.emergencyContacts.isNotEmpty ? user.emergencyContacts.first.phone : '',
    );
    _requestsController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _requestsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final bookingNotifier = ref.read(bookingProvider.notifier);
    final booking = await bookingNotifier.createReservation(
      hotelData: {
        'id': widget.hotel.id,
        'title': widget.hotel.title,
        'city': widget.hotel.city,
        'address': widget.hotel.address,
        'image': widget.hotel.image,
        'rating': widget.hotel.rating,
      },
      roomType: widget.selectedRoom.name,
      pricePerNight: widget.selectedRoom.pricePerNight,
      numberOfRooms: 1,
      checkInDate: widget.checkInDate,
      checkOutDate: widget.checkOutDate,
      adults: widget.guestsCount,
      children: 0,
      guestName: _nameController.text.trim(),
      guestEmail: _emailController.text.trim(),
      guestPhone: _phoneController.text.trim(),
      specialRequests: _requestsController.text.trim(),
    );

    if (booking != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingSuccessScreen(booking: booking),
        ),
      );
    } else if (mounted) {
      final error = ref.read(bookingProvider).errorMessage ?? 'Booking could not be confirmed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final baseTotal = widget.selectedRoom.pricePerNight * widget.numberOfNights;
    final tax = (baseTotal * 0.12).round();
    final grandTotal = baseTotal + tax;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Reservation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hotel & Stay Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.hotel.image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.background,
                          child: const Icon(Icons.hotel, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.hotel.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.selectedRoom.name,
                            style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(widget.checkInDate)} - ${_formatDate(widget.checkOutDate)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          Text(
                            '${widget.numberOfNights} Night${widget.numberOfNights > 1 ? "s" : ""} • ${widget.guestsCount} Guests',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Guest Information
              const Text(
                'Guest Information',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter guest name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address for Confirmation',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => v == null || !v.contains('@') ? 'Please enter a valid email' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Contact Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a phone number' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _requestsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Special Requests (Optional)',
                  hintText: 'e.g. Quiet room, late check-in, high floor...',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Pricing Summary
              const Text(
                'Price Summary',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildPriceRow(
                      '₹${widget.selectedRoom.pricePerNight.toInt()} x ${widget.numberOfNights} night${widget.numberOfNights > 1 ? "s" : ""}',
                      '₹${baseTotal.toInt()}',
                    ),
                    const SizedBox(height: 8),
                    _buildPriceRow('Taxes & Service Fees (12%)', '₹$tax'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: AppColors.cardBorder, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${grandTotal.toInt()}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: bookingState.isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: bookingState.isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm & Reserve Room',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
