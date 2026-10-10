import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transport_model.dart';
import '../providers/transport_provider.dart';
import '../utils/theme.dart';

class TransportScreen extends ConsumerStatefulWidget {
  const TransportScreen({super.key});

  @override
  ConsumerState<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends ConsumerState<TransportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddTicketDialog() {
    String transportType = 'flight';
    String carrier = '';
    String transitNumber = '';
    String depCity = '';
    String depCode = '';
    String arrCity = '';
    String arrCode = '';
    String seat = '12A';
    String seatClass = 'Economy';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text('Add Transport Ticket', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: transportType,
                      decoration: InputDecoration(
                        labelText: 'Transport Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'flight', child: Text('✈️ Flight')),
                        DropdownMenuItem(value: 'train', child: Text('🚄 Train / High Speed Rail')),
                        DropdownMenuItem(value: 'bus', child: Text('🚌 Bus / Transit')),
                        DropdownMenuItem(value: 'ferry', child: Text('⛴️ Ferry / Cruise')),
                      ],
                      onChanged: (v) => setModalState(() => transportType = v ?? 'flight'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Carrier Name (e.g. Emirates, SNCF, Shinkansen)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => carrier = v,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Flight / Train Number (e.g. EK-202, TGV-994)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => transitNumber = v,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'From City',
                              hintText: 'e.g. Dubai',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (v) => depCity = v,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Code',
                              hintText: 'DXB',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (v) => depCode = v,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'To City',
                              hintText: 'e.g. Paris',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (v) => arrCity = v,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Code',
                              hintText: 'CDG',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (v) => arrCode = v,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Seat Number',
                              hintText: '14A',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (v) => seat = v,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Class',
                              hintText: 'Business Club',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (v) => seatClass = v,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (carrier.isNotEmpty && transitNumber.isNotEmpty && depCity.isNotEmpty && arrCity.isNotEmpty) {
                          Navigator.pop(ctx);
                          final ok = await ref.read(transportProvider.notifier).createTransport(
                            transportType: transportType,
                            carrier: carrier,
                            transitNumber: transitNumber,
                            departureCity: depCity,
                            departureCode: depCode.isNotEmpty ? depCode : null,
                            arrivalCity: arrCity,
                            arrivalCode: arrCode.isNotEmpty ? arrCode : null,
                            seatNumber: seat,
                            seatClass: seatClass,
                          );
                          if (mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ticket saved to wallet!'), backgroundColor: AppColors.success),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Boarding Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _showBoardingPassModal(TransportModel t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Airline Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.accent,
                          radius: 16,
                          child: Icon(_getIcon(t.transportType), color: Colors.black, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.carrier, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(t.transitNumber, style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(t.status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStatusColor(t.status)),
                      ),
                      child: Text(t.status, style: TextStyle(color: _getStatusColor(t.status), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Route Details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.departure.code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(t.departure.city, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(t.departure.time.toLocal().toString().substring(11, 16), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(_getIcon(t.transportType), color: AppColors.accent, size: 24),
                            const SizedBox(height: 4),
                            Text(t.transportType.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1.5)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(t.arrival.code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(t.arrival.city, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(t.arrival.time.toLocal().toString().substring(11, 16), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Passenger Info Grid
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoItem('PASSENGER', t.passengerName),
                              _buildInfoItem('PNR / BOOKING REF', t.bookingReference),
                            ],
                          ),
                          const Divider(color: AppColors.cardBorder, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoItem('TERMINAL', t.departure.terminal),
                              _buildInfoItem('GATE', t.departure.gate),
                              _buildInfoItem('SEAT', t.seatNumber),
                              _buildInfoItem('CLASS', t.seatClass),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Digital Barcode / QR Simulation
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              28,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: (index % 3 == 0) ? 4 : ((index % 2 == 0) ? 2 : 1),
                                height: 40,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.qrCodeData,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black87, fontSize: 10, letterSpacing: 1.5, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final msg = await ref.read(transportProvider.notifier).refreshLiveStatus(t.id);
                          if (ctx.mounted && msg != null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.primary));
                            Navigator.pop(ctx);
                          }
                        },
                        icon: const Icon(Icons.sync, size: 16, color: AppColors.accent),
                        label: const Text('Live Status Refresh', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        ref.read(transportProvider.notifier).deleteTransport(t.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ticket removed from wallet.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
        return Icons.flight_takeoff;
      case 'train':
        return Icons.train;
      case 'bus':
        return Icons.directions_bus;
      case 'ferry':
        return Icons.directions_boat;
      default:
        return Icons.confirmation_number;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on time':
        return AppColors.success;
      case 'boarding':
        return AppColors.accent;
      case 'delayed':
        return Colors.redAccent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transportState = ref.watch(transportProvider);
    final allTransports = transportState.transports;
    final flights = allTransports.where((t) => t.transportType == 'flight').toList();
    final trains = allTransports.where((t) => t.transportType != 'flight').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Transport & Ticket Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'All (${allTransports.length})'),
            Tab(text: 'Flights (${flights.length})'),
            Tab(text: 'Trains & Bus (${trains.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTicketDialog,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: transportState.isLoading && allTransports.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTicketList(allTransports),
                _buildTicketList(flights),
                _buildTicketList(trains),
              ],
            ),
    );
  }

  Widget _buildTicketList(List<TransportModel> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.airplane_ticket_outlined, size: 54, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('No transport tickets saved yet.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Tap Add Ticket to add flight or train booking passes!', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final t = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: () => _showBoardingPassModal(t),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(_getIcon(t.transportType), color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(t.carrier, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                          const SizedBox(width: 6),
                          Text('• ${t.transitNumber}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusColor(t.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getStatusColor(t.status).withValues(alpha: 0.5)),
                        ),
                        child: Text(t.status, style: TextStyle(color: _getStatusColor(t.status), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.departure.code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(t.departure.city, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(t.departure.time.toLocal().toString().substring(11, 16), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.arrow_forward, color: AppColors.cardBorder, size: 20),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(t.arrival.code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(t.arrival.city, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(t.arrival.time.toLocal().toString().substring(11, 16), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.cardBorder, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Seat: ${t.seatNumber} (${t.seatClass})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const Row(
                        children: [
                          Text('View Boarding Pass', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Icon(Icons.qr_code_2, size: 16, color: AppColors.accent),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
