import 'dart:async';

import '../model/host4_event.dart';

abstract interface class Host4AnalyticsSink {
  FutureOr<void> emit(Host4Event event);
}
