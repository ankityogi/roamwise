import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../providers/trip_provider.dart';

class PlannerTab extends ConsumerStatefulWidget {
  const PlannerTab({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PlannerTabState();
}

class _PlannerTabState extends ConsumerState<PlannerTab> {
  void _showCreateTripDialog() {
    String dest = '';
    String daysCount = '3';
    String travelStyle = 'Leisure';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Generate AI Itinerary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Our AI recommendation engine will draft a custom travel itinerary matching your choices.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Destination (City, Country)',
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => dest = v,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: daysCount,
                decoration: InputDecoration(
                  labelText: 'Duration (Days)',
                  prefixIcon: const Icon(Icons.timer_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['3', '5', '7', '10'].map((d) => DropdownMenuItem(value: d, child: Text('$d Days'))).toList(),
                onChanged: (v) => daysCount = v ?? '3',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: travelStyle,
                decoration: InputDecoration(
                  labelText: 'Travel Style',
                  prefixIcon: const Icon(Icons.interests_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Leisure', 'Adventure', 'Budget', 'Luxury', 'Cultural'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => travelStyle = v ?? 'Leisure',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (dest.isNotEmpty) {
                    Navigator.pop(context);
                    final success = await ref.read(tripProvider.notifier).generateTrip(
                      dest,
                      int.parse(daysCount),
                      travelStyle,
                    );
                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('AI Itinerary generated for $dest!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        final errorMsg = ref.read(tripProvider).errorMessage ?? 'Failed to generate itinerary.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMsg),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Generate Itinerary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final trips = tripState.trips;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTripDialog,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_road),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tripProvider.notifier).fetchTrips(),
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Trips',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  if (tripState.isLoading && trips.isNotEmpty)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (tripState.isLoading && trips.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (trips.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.explore_outlined, color: AppColors.textSecondary, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'No itineraries generated yet.',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap the + button to create a new AI trip!',
                          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        tilePadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.card_travel, color: AppColors.primary, size: 28),
                        ),
                        title: Text(
                          trip.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(trip.destination, style: const TextStyle(color: AppColors.textSecondary)),
                            Text(trip.dates, style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: AppColors.cardBorder),
                                const SizedBox(height: 8),
                                _buildInfoRow('Duration:', '${trip.daysCount} Days'),
                                const SizedBox(height: 6),
                                _buildInfoRow('Travel Style:', trip.travelStyle),
                                const SizedBox(height: 16),
                                Text(
                                  'Itinerary Schedule',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary.withValues(alpha: 0.9),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (trip.itinerarySchedule.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'No itinerary days parsed.',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  )
                                else
                                  ...trip.itinerarySchedule.expand((day) {
                                    return day.events.map((event) {
                                      return _buildTimelineStep(
                                        'Day ${day.dayNumber} - ${event.title}',
                                        '${event.time} - ${event.description}',
                                      );
                                    });
                                  }),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => ref.read(tripProvider.notifier).deleteTrip(trip.id),
                                    icon: const Icon(Icons.delete_outline, size: 16),
                                    label: const Text('Delete Trip'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: Colors.redAccent, width: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(val, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildTimelineStep(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const CircleAvatar(
              radius: 6,
              backgroundColor: AppColors.accent,
            ),
            Container(
              width: 2,
              height: 40,
              color: AppColors.cardBorder,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
