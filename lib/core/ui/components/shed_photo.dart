// lib/core/ui/components/shed_photo.dart
//
// A RULED CELL, NEVER A THUMBNAIL GRID. Every framework example of "show a
// photo" is a Card in a GridView with a radius and a shadow, and every one of
// those is wrong here: indelible.md §4.2 — "nothing in the record has a corner
// radius, because a document has no corners" — and §4.4, where the record row
// is 64 px and rows SHARE EDGES.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// The **only sanctioned `ColorFiltered` in the app** (decision #96).
///
/// Its cost is bounded to the image's own bounds, which is why this one is
/// permitted and a filter over a subtree is not. In `night` and in every
/// high-contrast palette `photoTint` is null and this is a plain `Image`.
class ShedPhoto extends StatefulWidget {
  const ShedPhoto({
    required this.image,
    required this.capturedAtLabel,
    required this.provenanceLabel,
    required this.semanticLabel,
    required this.fullColourLabel,
    super.key,
    this.missing = false,
    this.missingLabel,
  });

  /// An `ImageProvider`: `lib/core/ui/` may not import `lib/data/`, so the
  /// CALLER resolves the relative path through `MediaStore` and hands the
  /// result down. A component that resolved its own file would be a component
  /// that knew where bytes live.
  final ImageProvider image;

  /// Pre-formatted `d MMM y` and `HH:mm`. One formatting authority, not two.
  final String capturedAtLabel;

  /// `RecordedTime.provenanceLabel` — never empty, by exhaustive switch.
  final String provenanceLabel;

  /// Carries the provenance as well as the time: a screen-reader user has no
  /// margin stamp to read, so this is the only place §12.5's claim reaches them.
  final String semanticLabel;

  final String fullColourLabel;

  /// `media_assets.missing_since` is not null.
  final bool missing;

  final String? missingLabel;

  @override
  State<ShedPhoto> createState() => _ShedPhotoState();
}

class _ShedPhotoState extends State<ShedPhoto> {
  bool _fullColour = false;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;

    if (widget.missing) {
      // THE ROW SURVIVES WHEN THE FILE DOES NOT. Deleting it would make the app
      // lie by omission (§12.4) — the shepherd remembers taking the photo, and
      // an app that shows nothing is an app that says it never happened.
      return _cell(
        t,
        child: Padding(
          padding: EdgeInsets.all(t.gapMin),
          child: Text(widget.missingLabel ?? '', style: text.bodyMedium),
        ),
      );
    }

    final ColorFilter? tint = t.photoTint;

    // A BOUNDED HEIGHT, DERIVED FROM THE WIDTH. An Image with BoxFit.cover and
    // no height constraint takes whatever the ambient constraints allow, so the
    // cell overflowed by 244 px the moment it was pumped somewhere other than
    // the one place it was written against — FOUND IN THE FULL SUITE, not in
    // isolation, which is why it took reading the log rather than reasoning.
    //
    // 4:3 is the frame a phone camera produces, so the cell shows the photo the
    // shepherd took rather than a crop of it.
    final Widget img = AspectRatio(
      aspectRatio: 4 / 3,
      child: Image(image: widget.image, fit: BoxFit.cover),
    );

    // NEVER AN IDENTITY FILTER WHEN THE TINT IS NULL: an identity ColorFiltered
    // still pays for a saveLayer, on every frame, for nothing.
    final Widget body = tint == null || _fullColour
        ? img
        : ColorFiltered(colorFilter: tint, child: img);

    return _cell(
      t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // FLEXIBLE, SO THE CAPTION ALWAYS FITS. The image is the part that can
          // give: a photo cropped a little is still the photo, whereas a caption
          // pushed off the bottom takes the time and the provenance with it —
          // and §12.5's claim travels in that caption.
          //
          // MEASURED at text scale 2.0, where the caption doubles and the 4:3
          // image no longer leaves room for it.
          Flexible(
            child: Semantics(image: true, label: widget.semanticLabel, child: body),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 2),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${widget.capturedAtLabel} · ${widget.provenanceLabel}',
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // PERMANENT, NOT CONDITIONAL (06 §4.7). A shepherd looking at a
                // photo of a prolapse needs the colour information, and a tinted
                // view of tissue is useless. It is also what keeps the app on
                // the right side of §12.2: it shows what was photographed and
                // never interprets it.
                if (tint != null)
                  Semantics(
                    button: true,
                    label: widget.fullColourLabel,
                    onTap: () => setState(() => _fullColour = !_fullColour),
                    child: ExcludeSemantics(
                      child: GestureDetector(
                        key: const Key('photo.full_colour'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _fullColour = !_fullColour),
                        child: SizedBox(
                          height: t.tapMin,
                          width: t.tapMin,
                          child: Center(
                            child: Text(
                              widget.fullColourLabel,
                              style: text.labelSmall,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The rule, and nothing else. **No card, no shadow, no radius, no grid** —
  /// and `outlineWidth` is 2, not 1: a 1 px rule disappears under a head torch.
  Widget _cell(ShedTokens t, {required Widget child}) => DecoratedBox(
    decoration: BoxDecoration(
      color: t.surfaceBase,
      border: Border(
        bottom: BorderSide(color: t.outline, width: t.outlineWidth),
      ),
    ),
    child: child,
  );
}
