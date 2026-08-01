/// One class's two words. **Both are required.**
///
/// **Never derive a plural by appending `s`.** The user is already typing one
/// word; guessing the other is §12.4 — *"3 sheeps"* is the cheap example, and
/// *tup/tups* versus *ox/oxen* is why no rule works. `validateOverride` rejects
/// a blank one rather than inventing it.
final class TermLabel {
  const TermLabel(this.singular, this.plural);

  final String singular;
  final String plural;

  @override
  bool operator ==(Object other) =>
      other is TermLabel && other.singular == singular && other.plural == plural;

  @override
  int get hashCode => Object.hash(singular, plural);
}
