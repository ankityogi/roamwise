import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../providers/explore_provider.dart';

class ExploreTab extends ConsumerStatefulWidget {
  const ExploreTab({super.key});

  @override
  ConsumerState<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<ExploreTab> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['All', 'Hotels', 'Dining', 'Sights', 'Transit'];

  @override
  void initState() {
    super.initState();
    // Initialize search controller text with current provider search city state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(exploreProvider).searchCity;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Hotels':
        return Icons.hotel;
      case 'Dining':
        return Icons.restaurant;
      case 'Sights':
        return Icons.museum;
      case 'Transit':
        return Icons.train;
      default:
        return Icons.location_on;
    }
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(exploreProvider.notifier).updateSearchCity(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreProvider);
    final places = exploreState.places;

    return Column(
      children: [
        // Top Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _triggerSearch(),
            decoration: InputDecoration(
              hintText: 'Search city (e.g. Kyoto, Rome)...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: AppColors.accent),
                onPressed: _triggerSearch,
              ),
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
        ),

        // Horizontal Category Chips
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = exploreState.selectedCategory == cat;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(exploreProvider.notifier).updateCategory(cat);
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withValues(alpha: 0.3),
                  checkmarkColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.accent : AppColors.cardBorder,
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Mock Maps Preview Window
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              color: AppColors.surface,
            ),
            child: Stack(
              children: [
                // Simulated Grid Map Lines
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                      ),
                      itemBuilder: (c, i) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                // Glowing Pulse GPS Pin (user position)
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                // Floating Action Map controls
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      _buildMapIconButton(Icons.my_location),
                      const SizedBox(height: 8),
                      _buildMapIconButton(Icons.add),
                      const SizedBox(height: 8),
                      _buildMapIconButton(Icons.remove),
                    ],
                  ),
                ),
                // Location Bar banner overlay
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_searching, color: AppColors.success, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          exploreState.searchCity,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Nearby Location Grid Cards
        Expanded(
          flex: 3,
          child: exploreState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : exploreState.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          exploreState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    )
                  : places.isEmpty
                      ? const Center(
                          child: Text(
                            'No places found for this search.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: places.length,
                          itemBuilder: (context, index) {
                            final place = places[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(place.category),
                                    color: AppColors.accent,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  place.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(place.distance, style: const TextStyle(color: AppColors.textSecondary)),
                                    const SizedBox(width: 8),
                                    const Text('|', style: TextStyle(color: AppColors.cardBorder)),
                                    const SizedBox(width: 8),
                                    Text(place.price, style: const TextStyle(color: AppColors.success)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      place.rating.toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildMapIconButton(IconData icon) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.surface.withValues(alpha: 0.9),
      child: IconButton(
        icon: Icon(icon, size: 18, color: Colors.white),
        onPressed: () {},
        padding: EdgeInsets.zero,
      ),
    );
  }
}
