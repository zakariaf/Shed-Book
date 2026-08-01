import 'package:clock/clock.dart';
import 'package:shed_book/domain/time/instant.dart';

/// The single allowlisted reader of wall-clock time in the app (R23, #46).
///
/// Every timestamp originates here. Repositories and controllers call this;
/// pure domain functions take the result as a parameter, which is why
/// `package:clock` is banned under `lib/domain/` outright (R24).
///
/// **There is no second clock abstraction and this is the file where somebody
/// adds one.** No `abstract class Clock`, no `SystemClock`, no `clockProvider`,
/// no `Clock` parameter on a repository. Two clock seams are worse than none,
/// because a test that fakes one does not fake the other (#46, 05 §1.3), and
/// CONVENTIONS §3.5 puts the clock explicitly outside the provider graph.
///
/// `clock.now()` returns a **local** `DateTime`, and that is fine:
/// `millisecondsSinceEpoch` is zone-independent, so this is a true instant
/// whatever the device zone. Do not "fix" it to `.toUtc().millisecondsSinceEpoch`
/// — same number, more code, and it invites a reader to think the zone mattered.
///
/// In tests you install time with `withClock(Clock.fixed(...))`. In **widget**
/// tests you do not: the binding already runs every `testWidgets` body inside a
/// `FakeAsync` zone whose clock is this one, so `tester.pump(const Duration(hours: 25))`
/// really moves this function. Wrapping a widget test in `Clock.fixed` freezes
/// it and every elapsed-time readout silently measures 0 h and passes (#113).
Instant appNow() => Instant(clock.now().millisecondsSinceEpoch);
