import 'package:material_ui/material_ui.dart';

import '../models/discovered_sound.dart';
import '../services/sound_collection_repository.dart';
import '../services/yamnet_class_catalog.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final SoundCollectionRepository _repository = SoundCollectionRepository();
  final YamnetClassCatalog _classCatalog = YamnetClassCatalog();
  late Future<_CollectionData> _collectionFuture;

  @override
  void initState() {
    super.initState();
    _collectionFuture = _loadCollection();
  }

  Future<_CollectionData> _loadCollection() async {
    final results = await Future.wait([
      _classCatalog.loadLabels(),
      _repository.getDiscoveredSounds(),
    ]);
    return _CollectionData(
      labels: results[0] as List<String>,
      discoveredSounds: results[1] as List<DiscoveredSound>,
    );
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Pokédex'), centerTitle: true),
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

          final data = snapshot.data!;
          final discoveredByName = {
            for (final sound in data.discoveredSounds) sound.name: sound,
          };

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${discoveredByName.length}/${YamnetClassCatalog.classCount}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: data.labels.length,
                  itemBuilder: (context, index) {
                    final label = data.labels[index];
                    final sound = discoveredByName[label];
                    return _SoundCard(label: label, sound: sound);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CollectionData {
  const _CollectionData({required this.labels, required this.discoveredSounds});

  final List<String> labels;
  final List<DiscoveredSound> discoveredSounds;
}

class _SoundCard extends StatelessWidget {
  const _SoundCard({required this.label, required this.sound});

  final String label;
  final DiscoveredSound? sound;

  @override
  Widget build(BuildContext context) {
    final isDiscovered = sound != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isDiscovered
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDiscovered ? Icons.graphic_eq : Icons.help_outline,
              size: 40,
              color: isDiscovered
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              isDiscovered ? label : '???',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDiscovered
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isDiscovered) ...[
              const SizedBox(height: 6),
              Text(
                '${(sound!.bestScore * 100).toStringAsFixed(0)} %',
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
