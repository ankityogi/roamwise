import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../models/trip_model.dart';
import '../providers/trip_provider.dart';
import 'itinerary_route_map_screen.dart';

class PlannerTab extends ConsumerStatefulWidget {
  const PlannerTab({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PlannerTabState();
}

class _PlannerTabState extends ConsumerState<PlannerTab> {
  void _showJoinTripDialog() {
    String inviteCode = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.group_add, color: AppColors.accent),
              SizedBox(width: 8),
              Text('Join Shared Trip', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the 6-character trip invite code shared by your travel companion:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: const TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.accent),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'e.g. RW7K9Q',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => inviteCode = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (inviteCode.trim().length >= 4) {
                  Navigator.pop(ctx);
                  final success = await ref.read(tripProvider.notifier).joinTripByCode(inviteCode);
                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Joined collaborative trip!'), backgroundColor: AppColors.success),
                      );
                    } else {
                      final err = ref.read(tripProvider).errorMessage ?? 'Failed to join trip.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
              child: const Text('Join Trip', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddCustomEventDialog(String tripId, int totalDays) {
    int selectedDay = 1;
    String time = '04:00 PM';
    String title = '';
    String description = '';

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Custom Group Activity',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add a custom dining, meeting spot, or excursion for all companions to vote on.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedDay,
                    decoration: InputDecoration(
                      labelText: 'Select Day',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: List.generate(totalDays, (index) => index + 1)
                        .map((d) => DropdownMenuItem(value: d, child: Text('Day $d')))
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedDay = v ?? 1),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Time (e.g. 05:30 PM)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => time = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Activity Title',
                      hintText: 'e.g. Sunset Coffee at Skyline Lounge',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Description / Notes',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => description = v,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (title.isNotEmpty && time.isNotEmpty) {
                        Navigator.pop(ctx);
                        final ok = await ref.read(tripProvider.notifier).addCustomEvent(
                          tripId,
                          selectedDay,
                          time,
                          title,
                          description,
                        );
                        if (mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Activity added to itinerary!'), backgroundColor: AppColors.success),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showInviteSheet(TripModel trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final code = trip.inviteCode ?? 'ROAM99';
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.share, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Invite Trip Companions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Share this code with friends so they can view, vote, and add activities to "${trip.destination}".',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TRIP INVITE CODE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(code, style: const TextStyle(color: AppColors.accent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invite code $code copied to clipboard!'), backgroundColor: AppColors.success),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (trip.collaborators.isNotEmpty) ...[
                const Text('Active Companions:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: trip.collaborators.map((c) {
                    return Chip(
                      avatar: CircleAvatar(backgroundColor: AppColors.primary, child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 11, color: Colors.white))),
                      label: Text(c.name, style: const TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.cardBorder)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTripDialog,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Create Trip', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    'Trip Planner',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showJoinTripDialog,
                    icon: const Icon(Icons.group_add, size: 16, color: AppColors.accent),
                    label: const Text('Join with Code', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accent, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                          'Tap Create Trip or join a friend’s invite code!',
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
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                trip.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                              ),
                            ),
                            if (trip.collaborators.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.group, size: 12, color: AppColors.accent),
                                    const SizedBox(width: 4),
                                    Text('${trip.collaborators.length + 1}', style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
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
                                const SizedBox(height: 12),

                                // Collaboration & Map Action Bar
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.people_alt_outlined, color: AppColors.accent, size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                trip.collaborators.isEmpty
                                                    ? 'Solo Trip'
                                                    : '${trip.collaborators.length} Companion(s)',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => _showAddCustomEventDialog(trip.id, trip.daysCount),
                                                icon: const Icon(Icons.add_circle_outline, size: 14, color: AppColors.accent),
                                                label: const Text('Add Activity', style: TextStyle(color: AppColors.accent, fontSize: 11)),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.share, size: 16, color: Colors.white),
                                                tooltip: 'Share Invite Code',
                                                onPressed: () => _showInviteSheet(trip),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Divider(color: AppColors.cardBorder, height: 16),
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ItineraryRouteMapScreen(trip: trip),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.map_rounded, size: 16, color: AppColors.accent),
                                              SizedBox(width: 8),
                                              Text(
                                                'View Day-by-Day Route on Map',
                                                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(Icons.arrow_forward, size: 12, color: AppColors.accent),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                        tripId: trip.id,
                                        eventId: event.id,
                                        title: 'Day ${day.dayNumber} - ${event.title}',
                                        desc: '${event.time} - ${event.description}',
                                        votesCount: event.votes.length,
                                        addedBy: event.addedBy,
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

  Widget _buildTimelineStep({
    required String tripId,
    String? eventId,
    required String title,
    required String desc,
    int votesCount = 0,
    String addedBy = 'AI Assistant',
  }) {
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
              height: 48,
              color: AppColors.cardBorder,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  if (eventId != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => ref.read(tripProvider.notifier).toggleVote(tripId, eventId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: votesCount > 0 ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: votesCount > 0 ? AppColors.primary : AppColors.cardBorder, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(votesCount > 0 ? Icons.thumb_up : Icons.thumb_up_alt_outlined, size: 12, color: votesCount > 0 ? AppColors.accent : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('$votesCount', style: TextStyle(color: votesCount > 0 ? AppColors.accent : AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              if (addedBy != 'AI Assistant')
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('Suggested by $addedBy', style: const TextStyle(color: AppColors.accent, fontSize: 9, fontStyle: FontStyle.italic)),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
