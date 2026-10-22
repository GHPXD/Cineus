import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/editorial_feedback_repository.dart';
import '../providers/providers.dart';
import '../providers/app_clock.dart';
import '../l10n_mappers.dart';

class EditorialFeedbackButton extends ConsumerWidget {
  final String mode;
  final int? movieId;
  final String? question;
  const EditorialFeedbackButton({
    super.key,
    required this.mode,
    this.movieId,
    this.question,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
    child: Text(context.l10n.editorialFeedback),
    onPressed: () async {
      final repo = EditorialFeedbackRepository(
        ref.read(databaseProvider),
        ref.read(appClockProvider),
      );
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _FeedbackForm(
          repo: repo,
          mode: mode,
          movieId: movieId,
          question: question,
        ),
      );
      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.feedbackSent)));
      }
    },
  );
}

class _FeedbackForm extends StatefulWidget {
  final EditorialFeedbackRepository repo;
  final String mode;
  final int? movieId;
  final String? question;
  const _FeedbackForm({
    required this.repo,
    required this.mode,
    this.movieId,
    this.question,
  });
  @override
  State<_FeedbackForm> createState() => _FeedbackState();
}

class _FeedbackState extends State<_FeedbackForm> {
  final _note = TextEditingController();
  String _category = 'answer';
  bool _busy = false, _error = false;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.editorialFeedback,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final pair in [
                  ('answer', l.feedbackClue),
                  ('art', l.feedbackArtwork),
                  ('difficulty', l.feedbackDifficulty),
                  ('other', l.feedbackOther),
                ])
                  ChoiceChip(
                    label: Text(pair.$2),
                    selected: _category == pair.$1,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _category = pair.$1),
                  ),
              ],
            ),
            TextField(
              controller: _note,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.feedbackNote),
            ),
            if (_error) Text(l.retryAction),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await widget.repo.submit(
                          mode: widget.mode,
                          category: _category,
                          movieId: widget.movieId,
                          question: widget.question,
                          note: _note.text,
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (_) {
                        if (mounted) {
                          setState(() {
                            _busy = false;
                            _error = true;
                          });
                        }
                      }
                    },
              child: Text(l.sendFeedback),
            ),
          ],
        ),
      ),
    );
  }
}
