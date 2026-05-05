import 'package:venastudio/common.dart';

final mpesaCodesServicesProvider =
    StateNotifierProvider.autoDispose<
      MpesaCodesServiceNotifier,
      AsyncValue<List<Map>>
    >((ref) {
      final authService = ref.watch(authenticationServiceProvider);
      return MpesaCodesServiceNotifier(authService: authService.value);
    });

class MpesaCodesServiceNotifier extends StateNotifier<AsyncValue<List<Map>>> {
  MpesaCodesServiceNotifier({required this.authService})
    : super(const AsyncLoading()) {
    if (authService != null) {
      init();
    }
  }

  final AuthData? authService;
  final _apiService = ApiProvider();
  List<Map<dynamic, dynamic>> pureData = [];

  // Stores current filters
  bool? showUsed;
  (DateTime, DateTime)? _range;

  // Initialize or reload data with optional date range
  Future<void> init({(DateTime, DateTime)? range}) async {
    if (authService == null) return;

    // Update stored range
    if (range != null) {
      _range = range;
      state = const AsyncLoading();
    }

    final user = authService!.user;

    final body = {
      'userid': '${user.id}',
      'usertype': user.type ?? '',
      'storenumber': user.paybill ?? '',
      'start_date': sDate(_range?.$1 ?? DateTime.now()),
      'end_date': sDate(_range?.$2 ?? DateTime.now()),
      'limit': '5000',
    };

    try {
      final dynamic response =
          await _apiService.post('/api/servicebooktransactions.php', body: body)
              as Map;

      final info = response['data'] as List;
      final comms = List<Map>.from(info.map((e) => e as Map));

      pureData = comms;
      // Apply any filter if previously set
      _applyFilter();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Refresh while maintaining current filters and date range
  Future<void> refresh() async {
    await init(); // Uses stored _range
  }

  // Filter codes based on selected type
  void filter(String show) {
    if (show == 'ALL CODES') {
      showUsed = null;
    } else if (show == 'USED CODES') {
      showUsed = true;
    } else if (show == 'UNUSED CODES') {
      showUsed = false;
    }
    _applyFilter();
  }

  // Applies the currently selected filter to the data
  void _applyFilter() {
    if (showUsed == null) {
      state = AsyncData(pureData);
    } else {
      final filtered = pureData
          .where((element) => (element['used'] == true) == showUsed)
          .toList();
      state = AsyncData(filtered);
    }
  }
}
