// test/features/csv_header_golden_test.dart
//
// A GOLDEN THAT IS A STRING, NOT A `.png`. `09 §3.4` asks for one and this is
// it: the three header rows, character for character, against the document that
// publishes them.
//
// **THIS IS THE MOST IRREVERSIBLE THING IN THE EPIC.** The file lands on
// somebody else's laptop the day after the first tap and you cannot recall it.
// Appending a column to the end of a list is allowed. Renaming or reordering one
// is a breaking change to every spreadsheet a shepherd has built on top of it —
// and a shepherd who has built a spreadsheet on top of it is exactly the user
// this product is for.
//
// The failure message prints the field count, because the two ways this goes
// wrong are a renamed column and a miscounted one, and the count is the half a
// diff of two long strings does not show you.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/data/export_repository.dart';

/// Copied from `09 §3.4`, which is where they are published.
///
/// **Deliberately a literal rather than a read of the document.** A golden that
/// parses the document it is guarding proves the two agree and nothing else —
/// edit the document and the test follows it silently, which is the one failure
/// this assertion exists to catch.
const String _lambs =
    'lamb_uid,season_year,season_label,lamb_tag,sex,birth_dam_tag,birth_dam_uid,'
    'rearing_dam_tag,rearing_dam_uid,was_fostered,lambing_uid,born_at_utc,'
    'born_at_local,born_local_date,local_date_disagrees,time_source,'
    'time_provenance,time_captured_at_utc,time_original_effective_utc,'
    'declared_birth_type,lambs_recorded_for_lambing,birth_type_mismatch,'
    'lambing_ease,assisted_by,presentation_key,presentation_label,'
    'birth_weight_g,birth_weight_kg,status,death_date,death_cause_key,'
    'death_cause_label,pet_lamb,bottle_feeds,notes,struck,struck_at';

const String _ewes =
    'ewe_uid,tag,eid,breed,date_of_birth,source,status,season_year,season_label,'
    'season_status,scanned_count,lambings_recorded,lambings_scored,'
    'lambings_scored_assisted,lambs_born,lambs_born_alive,lambs_stillborn,'
    'lambs_reared,first_lambing_at_utc,first_lambing_local_date,'
    'last_lambing_at_utc,observations,treatments_recorded,'
    'latest_meat_clear_date,latest_milk_clear_date,notes,struck,struck_at';

const String _treatments =
    'treatment_uid,season_year,season_label,animal_kind,animal_tag,animal_uid,'
    'product_name,dose_text,route_key,route_label,batch_no,administered_at_utc,'
    'administered_at_local,time_source,time_provenance,time_captured_at_utc,'
    'time_original_effective_utc,meat_withdrawal_state,meat_withdrawal_days,'
    'meat_clear_date,meat_withdrawal_source,milk_withdrawal_state,'
    'milk_withdrawal_days,milk_clear_date,milk_withdrawal_source,'
    'clear_date_disagrees,is_voided,voided_at_utc,note,struck,struck_at';

void main() {
  for (final (String name, String published, List<String> actual, int fields)
      in <(String, String, List<String>, int)>[
        ('lambs.csv', _lambs, ExportRepository.lambsHeader, 37),
        ('ewes.csv', _ewes, ExportRepository.ewesHeader, 28),
        ('treatments.csv', _treatments, ExportRepository.treatmentsHeader, 31),
      ]) {
    test("$name's header row is frozen, field for field", () {
      expect(
        actual.join(','),
        published,
        reason:
            '$name is published in 09 §3.4 with $fields fields; this header has '
            '${actual.length}. Appending is allowed — renaming or reordering '
            'breaks every spreadsheet built on the file.',
      );
      expect(actual, hasLength(fields));
    });
  }
}
