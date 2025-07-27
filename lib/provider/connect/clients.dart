import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotube/services/device_info/device_info.dart';
import 'package:spotube/services/logger/logger.dart';

class ConnectClientsState {
  final List<BonsoirService> services;
  final ResolvedBonsoirService? resolvedService;
  final BonsoirDiscovery discovery;

  ConnectClientsState({
    required this.services,
    required this.discovery,
    this.resolvedService,
  });

  ConnectClientsState copyWith({
    List<BonsoirService>? services,
    BonsoirDiscovery? discovery,
    ResolvedBonsoirService? resolvedService,
  }) {
    return ConnectClientsState(
      services: services ?? this.services,
      discovery: discovery ?? this.discovery,
      resolvedService: resolvedService ?? this.resolvedService,
    );
  }
}

class ConnectClientsNotifier extends AsyncNotifier<ConnectClientsState> {
  ConnectClientsNotifier();

  @override
  build() async {
    final discovery = BonsoirDiscovery(type: '_spotube._tcp');
    final deviceId = await DeviceInfoService.instance.deviceId();
    await discovery.initialize();

    final subscription = discovery.eventStream?.listen((event) {
      // ignore device itself
      try {
        if (event.service?.attributes["deviceId"] == deviceId) {
          return;
        }

        switch (event) {
          case BonsoirDiscoveryServiceFoundEvent():
            state = AsyncData(state.value!.copyWith(
              services: [
                ...?state.value?.services,
                event.service,
              ],
            ));
            break;
          case BonsoirDiscoveryServiceResolvedEvent():
            state = AsyncData(
              state.value!.copyWith(
                resolvedService: event.service,
              ),
            );
            break;
          case BonsoirDiscoveryServiceLostEvent():
            state = AsyncData(
              ConnectClientsState(
                services: state.value!.services
                    .where((s) => s.name != event.service.name)
                    .toList(),
                discovery: state.value!.discovery,
                resolvedService: state.value?.resolvedService != null &&
                        event.service.name ==
                            state.value?.resolvedService?.name
                    ? null
                    : state.value!.resolvedService,
              ),
            );
            break;
          default:
            break;
        }
      } catch (e, stack) {
        AppLogger.reportError(e, stack);
      }
    });

    ref.onDispose(() {
      subscription?.cancel();
      discovery.stop();
    });

    await discovery.start();

    return ConnectClientsState(
      services: [],
      discovery: discovery,
    );
  }

  Future<void> resolveService(BonsoirService service) async {
    if (state.value == null) return;
    await service.resolve(state.value!.discovery);
  }

  Future<void> clearResolvedService() async {
    if (state.value == null) return;
    state = AsyncData(
      ConnectClientsState(
        services: state.value!.services,
        discovery: state.value!.discovery,
      ),
    );
  }
}

final connectClientsProvider =
    AsyncNotifierProvider<ConnectClientsNotifier, ConnectClientsState>(
  () => ConnectClientsNotifier(),
);
