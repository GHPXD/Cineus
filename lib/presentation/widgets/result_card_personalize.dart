import 'package:flutter/material.dart';
import '../../domain/entities/player_collection.dart';
import '../../l10n/app_l10n.dart';
import '../screens/player_collection_screen.dart';

class ResultCardPersonalize extends StatefulWidget {
  final Widget Function(CollectionLook) cardBuilder;
  final bool enabled;
  const ResultCardPersonalize({
    super.key,
    required this.cardBuilder,
    this.enabled = true,
  });
  @override
  State<ResultCardPersonalize> createState() => _ResultCardPersonalizeState();
}

class _ResultCardPersonalizeState extends State<ResultCardPersonalize> {
  bool _opening = false;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    key: const ValueKey('personalize-result-card'),
    onPressed: widget.enabled && !_opening
        ? () async {
            setState(() => _opening = true);
            try {
              await Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute(
                  builder: (_) => PlayerCollectionScreen(
                    previewBuilder: widget.cardBuilder,
                  ),
                ),
              );
            } finally {
              if (mounted) setState(() => _opening = false);
            }
          }
        : null,
    child: Text(AppL10n.of(context).collectionPersonalize),
  );
}
