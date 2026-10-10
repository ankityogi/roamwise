import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../providers/trip_provider.dart';
import '../providers/booking_provider.dart';

class OfflineGuideScreen extends ConsumerStatefulWidget {
  const OfflineGuideScreen({super.key});

  @override
  ConsumerState<OfflineGuideScreen> createState() => _OfflineGuideScreenState();
}

class _OfflineGuideScreenState extends ConsumerState<OfflineGuideScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notesController = TextEditingController();
  static const String _offlineNotesKey = 'roamwise_offline_notes';
  String _selectedLanguage = 'Japanese';

  final Map<String, List<Map<String, String>>> _phrasebook = {
    'Japanese': [
      {'phrase': 'Hello / Good day', 'translation': 'Konnichiwa (こんにちは)', 'pronunciation': 'kohn-nee-chee-wah'},
      {'phrase': 'Thank you very much', 'translation': 'Arigatou gozaimasu (ありがとうございます)', 'pronunciation': 'ah-ree-gah-toh go-zeye-mas'},
      {'phrase': 'Excuse me / Sorry', 'translation': 'Sumimasen (すみません)', 'pronunciation': 'soo-mee-mah-sen'},
      {'phrase': 'Where is the station?', 'translation': 'Eki wa doko desu ka? (駅はどこですか？)', 'pronunciation': 'eh-kee wah doh-koh dess kah?'},
      {'phrase': 'How much is this?', 'translation': 'Kore wa ikura desu ka? (これはいくらですか？)', 'pronunciation': 'koh-reh wah ee-koo-rah dess kah?'},
      {'phrase': 'Check please / Bill', 'translation': 'Okaikei onegaishimasu (お会計お願いします)', 'pronunciation': 'oh-kye-kay oh-neh-guye-she-mas'},
      {'phrase': 'Do you speak English?', 'translation': 'Eigo ga hanasemasu ka? (英語が話せますか？)', 'pronunciation': 'ay-goh gah hah-nah-seh-mas kah?'},
      {'phrase': 'Help me please (Emergency)', 'translation': 'Tasukete kudasai (助けてください)', 'pronunciation': 'tah-soo-keh-teh koo-dah-seye'},
      {'phrase': 'Call an ambulance', 'translation': 'Kyuukyuusha o yonde kudasai (救急車を呼んでください)', 'pronunciation': 'kyoo-kyoo-sha oh yohn-deh koo-dah-seye'},
    ],
    'Spanish': [
      {'phrase': 'Hello / Good morning', 'translation': 'Hola / Buenos días', 'pronunciation': 'OH-lah / BWEH-nohs DEE-ahs'},
      {'phrase': 'Thank you very much', 'translation': 'Muchas gracias', 'pronunciation': 'MOO-chahs GRAH-syahs'},
      {'phrase': 'Excuse me / Please', 'translation': 'Disculpe / Por favor', 'pronunciation': 'dees-KOOL-peh / por fah-VOR'},
      {'phrase': 'Where is the bathroom?', 'translation': '¿Dónde está el baño?', 'pronunciation': 'DOHN-deh es-TAH el BAHN-yoh?'},
      {'phrase': 'How much does it cost?', 'translation': '¿Cuánto cuesta esto?', 'pronunciation': 'KWAHN-toh KWEHS-tah EHS-toh?'},
      {'phrase': 'The bill, please', 'translation': 'La cuenta, por favor', 'pronunciation': 'lah KWEHN-tah por fah-VOR'},
      {'phrase': 'I need help (Emergency)', 'translation': 'Necesito ayuda, por favor', 'pronunciation': 'neh-seh-SEE-toh ah-YOO-dah'},
      {'phrase': 'Call the police', 'translation': 'Llame a la policía', 'pronunciation': 'YAH-meh ah lah poh-lee-SEE-ah'},
    ],
    'French': [
      {'phrase': 'Hello / Good day', 'translation': 'Bonjour', 'pronunciation': 'bohn-ZHOOR'},
      {'phrase': 'Thank you very much', 'translation': 'Merci beaucoup', 'pronunciation': 'mehr-SEE boh-KOO'},
      {'phrase': 'Excuse me / Please', 'translation': 'Pardon / S’il vous plaît', 'pronunciation': 'pahr-DOHN / seel voo PLEH'},
      {'phrase': 'Where is the train station?', 'translation': 'Où est la gare ?', 'pronunciation': 'oo eh lah GAHR?'},
      {'phrase': 'How much is it?', 'translation': 'Combien ça coûte ?', 'pronunciation': 'kohm-BYEHN sah KOOT?'},
      {'phrase': 'The bill, please', 'translation': 'L’addition, s’il vous plaît', 'pronunciation': 'lah-dee-SYOHN seel voo PLEH'},
      {'phrase': 'Help me (Emergency)', 'translation': 'Aidez-moi au secours', 'pronunciation': 'ay-DAY mwah oh seh-KOOR'},
    ],
    'German': [
      {'phrase': 'Hello / Good morning', 'translation': 'Hallo / Guten Morgen', 'pronunciation': 'HAH-loh / GOO-ten MOR-gen'},
      {'phrase': 'Thank you very much', 'translation': 'Vielen Dank', 'pronunciation': 'FEE-len dahnk'},
      {'phrase': 'Excuse me / Please', 'translation': 'Entschuldigung / Bitte', 'pronunciation': 'ent-SHOOL-dee-goong / BIT-teh'},
      {'phrase': 'Where is the station?', 'translation': 'Wo ist der Bahnhof?', 'pronunciation': 'voh ist der BAHN-hohf?'},
      {'phrase': 'How much does this cost?', 'translation': 'Wie viel kostet das?', 'pronunciation': 'vee feel KOS-tet dahs?'},
      {'phrase': 'Help (Emergency)', 'translation': 'Hilfe!', 'pronunciation': 'HIL-feh!'},
    ],
    'Hindi': [
      {'phrase': 'Hello / Greetings', 'translation': 'Namaste (नमस्ते)', 'pronunciation': 'nuh-muh-stay'},
      {'phrase': 'Thank you', 'translation': 'Dhanyavaad (धन्यवाद)', 'pronunciation': 'dhun-yuh-vaad'},
      {'phrase': 'Excuse me / Sorry', 'translation': 'Kshama kijiye (क्षमा कीजिए)', 'pronunciation': 'kshu-mah kee-jee-yeh'},
      {'phrase': 'Where is the station?', 'translation': 'Station kahan hai? (स्टेशन कहाँ है?)', 'pronunciation': 'stay-shun kuh-haan hai?'},
      {'phrase': 'How much for this?', 'translation': 'Yeh kitne ka hai? (यह कितने का है?)', 'pronunciation': 'yeh kit-nay kaa hai?'},
      {'phrase': 'Please help me', 'translation': 'Kripya meri madad kijiye (कृपया मेरी मदद कीजिए)', 'pronunciation': 'krip-yaa may-ree muh-dud kee-jee-yeh'},
    ]
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOfflineNotes();
  }

  Future<void> _loadOfflineNotes() async {
    final prefs = await SharedPreferences.getInstance();
    _notesController.text = prefs.getString(_offlineNotesKey) ?? '';
  }

  Future<void> _saveOfflineNotes(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_offlineNotesKey, val);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.offline_bolt, color: AppColors.accent, size: 20),
            SizedBox(width: 8),
            Text('Offline Travel Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Cached Trips'),
            Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Phrasebook'),
            Tab(icon: Icon(Icons.phone_in_talk, size: 18), text: 'Emergency SOS'),
            Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Travel Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCachedTripsTab(),
          _buildPhrasebookTab(),
          _buildEmergencyTab(),
          _buildTravelNotesTab(),
        ],
      ),
    );
  }

  Widget _buildCachedTripsTab() {
    final tripState = ref.watch(tripProvider);
    final trips = tripState.trips;
    final bookingState = ref.watch(bookingProvider);
    final bookings = bookingState.bookings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All items below are saved locally on your device for offline browsing without roaming or internet.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Offline Itineraries (${trips.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          const SizedBox(height: 10),
          if (trips.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: Text('No itineraries saved offline yet. Generate or view a trip while online to cache it.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center)),
            )
          else
            ...trips.map((trip) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const Icon(Icons.card_travel, color: AppColors.accent),
                  title: Text(trip.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${trip.destination} • ${trip.daysCount} Days', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: AppColors.cardBorder),
                          ...trip.itinerarySchedule.expand((day) {
                            return day.events.map((event) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Day ${day.dayNumber} [${event.time}]: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 12)),
                                    Expanded(child: Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 12))),
                                  ],
                                ),
                              );
                            });
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),
          Text('Hotel Vouchers (${bookings.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          const SizedBox(height: 10),
          if (bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: Text('No hotel bookings cached.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            )
          else
            ...bookings.map((b) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hotel, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.hotelTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                          Text('Guest: ${b.contactDetails.name.isNotEmpty ? b.contactDetails.name : 'Primary Traveler'} • ${b.roomType}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          Text('Dates: ${b.checkInDate.toLocal().toString().split(' ')[0]} to ${b.checkOutDate.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: AppColors.accent, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPhrasebookTab() {
    final phrases = _phrasebook[_selectedLanguage] ?? [];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Language:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              DropdownButton<String>(
                value: _selectedLanguage,
                dropdownColor: AppColors.surface,
                underline: const SizedBox(),
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                items: _phrasebook.keys.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: phrases.length,
            itemBuilder: (context, index) {
              final p = phrases[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['phrase']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(p['translation']!, style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Pronunciation: ${p['pronunciation']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyTab() {
    final List<Map<String, String>> globalNumbers = [
      {'country': 'Global / Europe / India (Universal)', 'number': '112', 'desc': 'Standard emergency SOS'},
      {'country': 'United States / Canada', 'number': '911', 'desc': 'Police, Fire, Ambulance'},
      {'country': 'United Kingdom / Ireland', 'number': '999', 'desc': 'Emergency dispatch'},
      {'country': 'Australia', 'number': '000', 'desc': 'National emergency'},
      {'country': 'Japan', 'number': '110 (Police) / 119 (Medical)', 'desc': 'Tokyo / Kyoto dispatch'},
      {'country': 'France / Germany / Spain / Italy', 'number': '112', 'desc': 'EU unified emergency'},
      {'country': 'India', 'number': '100 (Police) / 108 (Ambulance)', 'desc': 'National helpline'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: globalNumbers.length,
      itemBuilder: (context, index) {
        final item = globalNumbers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                child: const Icon(Icons.phone_in_talk, color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['country']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(item['desc']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item['number']!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTravelNotesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Offline Notepad',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep passport numbers, flight codes, locker pins, and hotel addresses handy without network.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              decoration: InputDecoration(
                hintText: 'Type flight booking refs, embassy addresses, or meeting points here...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.cardBorder)),
              ),
              onChanged: _saveOfflineNotes,
            ),
          ),
        ],
      ),
    );
  }
}
