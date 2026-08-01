/// A caveat is a **fact, never a judgement**. *"32 of 48 ewes lambed in the
/// first 17 days"* is a fact; *"your tupping was tight"* is a judgement, is
/// banned by §12.2, and would trip `copy.vet_advice` in N06-T09.
///
/// The inflection is here rather than at four call sites so the wording exists
/// once. 10 §8.5 eventually moves these sentences into ARB messages with
/// placeholders; until then the domain hands over the numbers and keeps the
/// sentence plain.
String ewesPhrase(int n, String singular, String plural) =>
    n == 1 ? '1 ewe $singular' : '$n ewes $plural';
