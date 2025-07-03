import 'dart:typed_data';

import 'package:cyan/events/cyan_event.dart';

class XaeroFluxFFI {
  static void sendEvent(CyanEvent event) {
    print('FFI: Sending ${event.type} event (${event.payload.length} bytes)');
  }

  static Stream<CyanEvent> getEventStream() {
    return Stream.periodic(
        const Duration(seconds: 2),
        (i) => CyanEvent(
              type: CyanEventType.syncResponse,
              id: 'sync_response_$i',
              payload: Uint8List.fromList([0, 1, 2, 3]),
            ));
  }
}
