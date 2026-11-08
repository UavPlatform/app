import '../utils/failure_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/rider_account_api.dart';
import 'auth_provider.dart';

final riderAccountApiProvider = Provider<RiderAccountApi>(
  (ref) => RiderAccountApi(ref.watch(httpClientProvider)),
);

// 飞手注册
class RiderRegisterState {
  final bool loading;
  final String? error;

  const RiderRegisterState({this.loading = false, this.error});

  RiderRegisterState copyWith({bool? loading, String? error}) {
    return RiderRegisterState(loading: loading ?? this.loading, error: error);
  }
}

class RiderRegisterNotifier extends StateNotifier<RiderRegisterState> {
  final RiderAccountApi _api;

  RiderRegisterNotifier(this._api) : super(const RiderRegisterState());

  Future<bool> register({
    required String userName,
    required String password,
    String? djiId,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.register(
        userName: userName,
        password: password,
        djiId: djiId,
      );
      if (!result.success || result.data == null) {
        state = state.copyWith(
          loading: false,
          error: resultFailureMessage(result, fallback: '注册失败'),
        );
        return false;
      }
      state = state.copyWith(loading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: failureMessage(error, fallback: '飞手注册未完成，请稍后重试'),
      );
      return false;
    }
  }
}

final riderRegisterProvider =
    StateNotifierProvider<RiderRegisterNotifier, RiderRegisterState>(
      (ref) => RiderRegisterNotifier(ref.watch(riderAccountApiProvider)),
    );
