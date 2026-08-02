// lib/features/lambing/lambing_entry_screen.dart
//
// The shell. The header, the lambs region and the care region are empty regions
// today; T02 onward fills them. It exists now because the anchor test has to
// pump something, and because the route helper needs a destination.
//
// It watches ONE provider. lib/features/ may not import package:drift or
// lib/core/db/ at all (layer rule 5), which is why LambingEntryData is declared
// in lib/data/ and assembled there.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/data/lambing_repository.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/lambing/lambing_entry_controller.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class LambingEntryScreen extends ConsumerWidget {
  const LambingEntryScreen({required this.lambingId, super.key});

  final LambingId lambingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<LambingEntryData> data = ref.watch(lambingEntryProvider(lambingId));

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(t.gapMin),
              child: Semantics(
                headingLevel: 1,
                child: Text(
                  l10n.lambingEntryTitle.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            Expanded(
              child: switch (data) {
                AsyncData<LambingEntryData>(value: final LambingEntryData d) => _Regions(
                  data: d,
                  lambsLabel: l10n.lambingEntryLambs,
                  careLabel: l10n.lambingEntryCare,
                ),
                // NO SPINNER (07 §1.4): loading is a fixed-height placeholder or
                // it is nothing. A spinner on a screen the shepherd reached by
                // committing a row says the row might not be there.
                _ => const SizedBox.expand(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Regions extends StatelessWidget {
  const _Regions({required this.data, required this.lambsLabel, required this.careLabel});

  final LambingEntryData data;
  final String lambsLabel;
  final String careLabel;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ShedTokens t = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin),
          child: Text(
            // The provenance travels with the time, always — it is the only
            // place §12.5's claim reaches the shepherd.
            data.lambing.time.provenanceLabel,
            key: const Key('lambing_entry.provenance'),
            style: text.bodySmall,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(t.gapMin),
          child: Text(
            '$lambsLabel ${data.lambs.length}',
            key: const Key('lambing_entry.lambs'),
            style: text.bodyMedium,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin),
          child: Text(
            '$careLabel ${data.lambs.fold<int>(0, (int n, LambEntryRow l) => n + l.care.length) + data.lambingCare.length}',
            key: const Key('lambing_entry.care'),
            style: text.bodyMedium,
          ),
        ),
        const Expanded(child: SizedBox.expand()),
      ],
    );
  }
}
