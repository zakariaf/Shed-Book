/// The **domain concept**, not the word.
///
/// These keys go into the database, the CSV `animal_class` column and the JSON
/// backup, and **they never change** — not on a rename, not on a translation.
/// The stored value is `.name`; there is deliberately no `key` field, because a
/// second spelling of the same thing is a second thing to keep in step.
///
/// **The words genuinely are not synonyms and not a clean taxonomy**, which is
/// why the concepts are closed and the labels are an overlay. The National Sheep
/// Association's own glossary defines *gimmer* by age plus parity, *shearling*
/// by **dentition**, *hogget* by age (and overloads it with a meat term), and
/// *teg* as two years old — while other regions use *teg* for a sheep in its
/// second year. Three measuring sticks for overlapping classes, with regional
/// disagreement inside one national body's glossary. There is no canonical
/// taxonomy to normalise to.
enum AnimalClass {
  /// Adult female that has lambed.
  ewe,

  /// Gimmer / theave / shearling ewe / hogg — the regional one.
  maidenFemale,

  eweLamb,
  ram,
  ramLamb,
  wether,

  /// Sex unknown, or not yet sexed.
  lamb,
}
