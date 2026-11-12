import 'package:audioplayers/audioplayers.dart';
import 'package:material_ui/material_ui.dart';

import '../models/discovered_sound.dart';
import '../services/rarity_catalog.dart';
import '../services/sound_collection_repository.dart';
import '../services/yamnet_class_catalog.dart';
import '../theme/sounddex_colors.dart';
import '../widgets/sound_icon.dart';
import '../widgets/sounddex_primitives.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  static const _filters = [
    'Tous',
    'Animaux',
    'Machines',
    'Alertes',
    'Nature',
    'Musique',
    'Voix',
    'Maison',
    'Autres',
  ];

  final _repository = SoundCollectionRepository();
  final _catalog = YamnetClassCatalog();
  final _rarityCatalog = RarityCatalog();
  late Future<_CollectionData> _collectionFuture;
  String _selectedFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _collectionFuture = _loadCollection();
  }

  Future<_CollectionData> _loadCollection() async {
    final results = await Future.wait([
      _catalog.loadLabels(),
      _repository.getDiscoveredSounds(),
      _rarityCatalog.load(),
      _rarityCatalog.loadRemote(),
    ]);
    return _CollectionData(
      labels: results[0] as List<String>,
      discoveredSounds: results[1] as List<DiscoveredSound>,
      rarityCatalog: _rarityCatalog,
    );
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mon carnet')),
    body: FutureBuilder<_CollectionData>(
      future: _collectionFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Impossible de charger la collection : ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildCollection(context, snapshot.data!);
      },
    ),
  );

  Widget _buildCollection(BuildContext context, _CollectionData data) {
    final discoveredByName = {
      for (final sound in data.discoveredSounds) sound.name: sound,
    };
    final visibleIndexes = List<int>.generate(data.labels.length, (index) {
      final label = data.labels[index];
      return _selectedFilter == 'Tous' ||
              soundCategoryForName(label) == _selectedFilter
          ? index
          : -1;
    }).where((index) => index >= 0).toList();
    final progress = discoveredByName.length / YamnetClassCatalog.classCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${discoveredByName.length} / ${YamnetClassCatalog.classCount}',
                style: const TextStyle(fontFamily: 'IBMPlexMono'),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)} %',
                style: const TextStyle(fontFamily: 'IBMPlexMono'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ThinProgressBar(value: progress),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _filters.map((filter) {
                final selected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: selected
                            ? SoundDexColors.terracotta
                            : SoundDexColors.warmGray,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        decoration: selected
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: SoundDexColors.terracotta,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 104),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.82,
            ),
            itemCount: visibleIndexes.length,
            itemBuilder: (context, position) {
              final index = visibleIndexes[position];
              final label = data.labels[index];
              final sound = discoveredByName[label];
              return _SoundCard(
                index: index,
                label: label,
                sound: sound,
                rarity: data.rarityCatalog.rarityForIndex(index, label),
                onTap: sound == null
                    ? null
                    : () => _showDetails(context, sound, label),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, DiscoveredSound sound, String label) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SoundDexColors.fiche,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _SoundDetails(sound: sound, label: label),
    );
  }
}

class _CollectionData {
  const _CollectionData({
    required this.labels,
    required this.discoveredSounds,
    required this.rarityCatalog,
  });

  final List<String> labels;
  final List<DiscoveredSound> discoveredSounds;
  final RarityCatalog rarityCatalog;
}

class _SoundCard extends StatelessWidget {
  const _SoundCard({
    required this.index,
    required this.label,
    required this.sound,
    required this.rarity,
    required this.onTap,
  });

  final int index;
  final String label;
  final DiscoveredSound? sound;
  final SoundRarity rarity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDiscovered = sound != null;
    if (!isDiscovered) {
      return GestureDetector(
        onTap: onTap,
        child: LockedCard(child: _cardContent(context)),
      );
    }

    final content = _cardContent(context);
    final card = switch (rarity) {
      SoundRarity.common => SpecimenCard(child: content),
      SoundRarity.uncommon => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          border: Border.all(color: SoundDexColors.ink),
        ),
        child: SpecimenCard(child: content),
      ),
      SoundRarity.rare => SpecimenCard(
        isRare: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [content, const StampLabel('RARE')],
        ),
      ),
      SoundRarity.legendary => Container(
        decoration: BoxDecoration(
          border: Border.all(color: SoundDexColors.terracotta, width: 2),
        ),
        padding: const EdgeInsets.all(2),
        child: SpecimenCard(
          isRare: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [content, const StampLabel('LÉGENDAIRE')],
          ),
        ),
      ),
    };
    return GestureDetector(onTap: onTap, child: card);
  }

  Widget _cardContent(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SoundIcon(
        name: sound == null ? 'inconnu' : label,
        size: 30,
        color: sound == null
            ? SoundDexColors.locked
            : SoundDexColors.terracotta,
      ),
      const SizedBox(height: 8),
      Text(
        sound == null ? '???' : label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: sound == null ? SoundDexColors.locked : SoundDexColors.ink,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'N° ${(index + 1).toString().padLeft(3, '0')}',
        style: const TextStyle(
          color: SoundDexColors.warmGray,
          fontFamily: 'IBMPlexMono',
          fontSize: 10,
        ),
      ),
    ],
  );
}

class _SoundDetails extends StatefulWidget {
  const _SoundDetails({required this.sound, required this.label});
  final DiscoveredSound sound;
  final String label;

  @override
  State<_SoundDetails> createState() => _SoundDetailsState();
}

class _SoundDetailsState extends State<_SoundDetails> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> _play() async {
    try {
      if (_isPlaying) {
        await _player.stop();
      } else {
        await _player.play(DeviceFileSource(widget.sound.audioPath));
      }
      if (mounted) setState(() => _isPlaying = !_isPlaying);
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lecture impossible : $error')));
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SoundIcon(
            name: widget.label,
            size: 58,
            color: SoundDexColors.terracotta,
          ),
          const SizedBox(height: 12),
          Text(widget.label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Première découverte : ${_date(widget.sound.discoveredAt)}'),
          Text(
            'Meilleur score : '
            '${(widget.sound.bestScore * 100).toStringAsFixed(1)} %',
            style: const TextStyle(fontFamily: 'IBMPlexMono'),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _isPlaying ? 'Arrêter' : 'Lire l’enregistrement',
            onPressed: _play,
          ),
        ],
      ),
    ),
  );

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
