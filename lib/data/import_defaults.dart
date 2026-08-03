// lib/data/import_defaults.dart — what a restored row gets for a column that did
// not exist when the file was written (`09 §5.6`, `04 §6.7`).
//
// **STRUCTURAL VALUES ONLY, NEVER A DOMAIN VALUE THE USER DID NOT ENTER.** A
// default `withdrawal_days` here would be §12.1 defeated by the restore path,
// and a default `ease` would be the app scoring a lambing nobody watched. The
// only things that belong here are values a row cannot be without and that carry
// no meaning — a `created_at` copied from its sibling, a boolean that is false
// because the feature did not exist.
//
// **EMPTY AT SCHEMA v1, AND THAT IS THE CORRECT VALUE.** A v1 backup carries
// every v1 column, so nothing can be missing yet. `import_defaults_are_complete_test.dart`
// is what turns that from a claim into a check: it reads the committed schema
// JSON and fails the day a migration adds a NOT NULL column with no default and
// no entry here.
library;

const Map<String, Map<String, Object?>> importDefaults = <String, Map<String, Object?>>{};
