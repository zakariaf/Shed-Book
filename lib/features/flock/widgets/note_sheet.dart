// lib/features/flock/widgets/note_sheet.dart
//
// **`addNote` HAD NO CALLER.** It landed at N15-T04 with its own tests: the one
// verb for a fact the schema has no column for — *she is limping*, *ram out on
// the 4th*, *the gate is broken* — and there was nowhere in the product to
// write one. Until `ShedTextField` there was nowhere it could have been.
//
// **ONE ROW PER SHEET, CREATED ON THE FIRST KEYSTROKE.** The same rule Quick
// Entry's `beginLambing` holds: the row is created on entry, not on exit, and
// every keystroke after that is its own committed write. Batching them into a
// commit would be a draft wearing a different name, and there are no drafts
// here.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_text_field.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/note_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/l10n/app_localizations.dart';

class NoteSheet extends ConsumerStatefulWidget {
  const NoteSheet({required this.eweId, super.key});

  final EweId eweId;

  @override
  ConsumerState<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends ConsumerState<NoteSheet> {
  /// The row this sheet is writing, once there is one.
  NoteId? _note;

  /// **THE WRITES ARE CHAINED, NOT FIRED IN PARALLEL.** Two keystrokes 40 ms
  /// apart would otherwise race: both see `_note == null`, both insert, and the
  /// shepherd gets two notes. Awaiting the previous one before starting the
  /// next is the same defence `guard()` gives every other write path.
  Future<void> _pending = Future<void>.value();

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.all(t.gapMin),
      child: ShedTextField(
        key: const Key('ewe_card.note.field'),
        label: l10n.eweCardNoteHeading,
        value: null,
        semanticLabel: l10n.eweCardNoteHeading,
        onChanged: _write,
      ),
    );
  }

  void _write(String? body) {
    // **AN EMPTIED FIELD IS NOT A DELETE.** Nothing is removed from this book,
    // so clearing the text leaves what was already committed — a shepherd
    // strikes a note, they do not un-type it. The next keystroke updates the
    // same row.
    if (body == null) {
      return;
    }
    _pending = _pending.then((_) => _commit(body));
    unawaited(_pending);
  }

  Future<void> _commit(String body) async {
    final NoteRepository notes = await ref.read(noteRepositoryProvider.future);

    if (_note case final NoteId id) {
      await notes.editNoteBody(id, body);
      return;
    }
    final WriteOutcome outcome = await notes.addNote(body: body, ewe: widget.eweId);
    if (outcome case WriteCommitted(insertedId: final int id?)) {
      _note = NoteId(id);
    }
  }
}
