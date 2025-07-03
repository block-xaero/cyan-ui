import 'package:cyan/events/cyan_event.dart';
import 'package:cyan/services/xaeroflux_ffi.dart';
import 'package:rxdart/rxdart.dart';

class CyanEventBus {
  static final _instance = CyanEventBus._internal();
  factory CyanEventBus() => _instance;
  CyanEventBus._internal();

  final _eventSubject = BehaviorSubject<CyanEvent>();

  Stream<CyanEvent> get eventStream => _eventSubject.stream;
  Stream<CyanEvent> eventsOfType(CyanEventType type) =>
      eventStream.where((event) => event.type == type);

  void dispatch(CyanEvent event) {
    XaeroFluxFFI.sendEvent(event);
    _eventSubject.add(event);
  }

  void dispose() {
    _eventSubject.close();
  }
}
