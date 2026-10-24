import 'package:dio/dio.dart';
import '../models/dispatch_order.dart';
import '../models/waybill_draft.dart';
import 'dispatch_requests.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

// REQ-SHIP-PUB-003: the server alone decides order and deposit state.
class DispatchOrderApi {
  DispatchOrderApi(this.client);
  final HttpClient client;
  Future<DispatchOrder> _transition(
    String path, [
    Map<String, dynamic>? input,
  ]) async => DispatchOrder(
    ApiDispatchOrderVO.fromJson(
      await _send(() => client.dio.post(path, data: input))
          as Map<String, dynamic>,
    ),
  );
  Future<DispatchOrder> startTransport(String id, int version) => _transition(
    ApiPaths.dispatchOrdersStartTransportPath(id),
    ApiDispatchAssignmentDTO(assignmentVersion: version).toJson(),
  );
  Future<DispatchOrder> deliver(String id, int version, List<String> ids) =>
      _transition(
        ApiPaths.dispatchOrdersDeliverPath(id),
        ApiDispatchDeliveryDTO(
          assignmentVersion: version,
          materialIds: ids,
        ).toJson(),
      );
  Future<DispatchOrder> receipt(String id, List<String> ids) => _transition(
    ApiPaths.dispatchOrdersReceiptPath(id),
    ApiDispatchReceiptDTO(materialIds: ids).toJson(),
  );
  Future<DispatchOrder> settle(String id) =>
      _transition(ApiPaths.dispatchOrdersSettlePath(id));
  Future<DispatchOrder> review(String id, int score, String comment) =>
      _transition(
        ApiPaths.dispatchOrdersReviewPath(id),
        ApiDispatchReviewDTO(score: score, comment: comment).toJson(),
      );
  Future<dynamic> _send(
    Future<Response<dynamic>> Function() request, {
    bool allowEmpty = false,
  }) => dispatchRequest(request, allowEmpty: allowEmpty);

  ApiWaybillDraftDTO _waybill(WaybillDraft draft) =>
      ApiWaybillDraftDTO(schemaVersion: 1, step: 4, fields: draft.cloudFields);
  Future<DispatchReadiness> readiness() async => DispatchReadiness.fromApi(
    ApiDispatchReadinessVO.fromJson(
      await _send(() => client.dio.get(ApiPaths.dispatchReadiness))
          as Map<String, dynamic>,
    ),
  );
  Future<DispatchAssessment> assess(WaybillDraft draft) async =>
      DispatchAssessment(
        ApiWaybillAssessmentVO.fromJson(
          await _send(
                () => client.dio.post(
                  ApiPaths.dispatchAssessments,
                  data: _waybill(draft).toJson(),
                ),
              )
              as Map<String, dynamic>,
        ),
      );
  Future<DispatchOrder> create(
    WaybillDraft draft,
    String assessmentId,
    String requestKey,
  ) async {
    final input = ApiDispatchOrderDTO(
      assessmentId: assessmentId,
      requestKey: requestKey,
      declarationAccepted: true,
      waybill: _waybill(draft),
    );
    return DispatchOrder(
      ApiDispatchOrderVO.fromJson(
        await _send(
              () => client.dio.post(
                ApiPaths.postDispatchOrders,
                data: input.toJson(),
              ),
            )
            as Map<String, dynamic>,
      ),
    );
  }

  Future<List<DispatchOrder>> list() async {
    final data =
        await _send(() => client.dio.get(ApiPaths.dispatchOrders)) as List;
    return data
        .map(
          (item) => DispatchOrder(
            ApiDispatchOrderVO.fromJson(item as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  Future<DispatchHall> pilotHall(int page) async => DispatchHall(
    ApiDispatchHallVO.fromJson(
      await _send(
            () => client.dio.get(
              ApiPaths.dispatchPilotHall,
              queryParameters: ApiPaths.dispatchPilotHallQuery(page: page),
            ),
          )
          as Map<String, dynamic>,
    ),
  );
  Future<List<DispatchOrder>> pilotOrders() async {
    final data =
        await _send(() => client.dio.get(ApiPaths.dispatchPilotOrders)) as List;
    return data
        .map(
          (item) => DispatchOrder(
            ApiDispatchOrderVO.fromJson(item as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  Future<DispatchOrder> pilotGet(String id) async => DispatchOrder(
    ApiDispatchOrderVO.fromJson(
      await _send(() => client.dio.get(ApiPaths.getDispatchPilotOrdersPath(id)))
          as Map<String, dynamic>,
    ),
  );
  Future<DispatchOrder> claim(String id, int revision) async => DispatchOrder(
    ApiDispatchOrderVO.fromJson(
      await _send(
            () => client.dio.post(
              ApiPaths.dispatchPilotOrdersClaimPath(id),
              data: ApiDispatchClaimDTO(offerRevision: revision).toJson(),
            ),
          )
          as Map<String, dynamic>,
    ),
  );
  Future<DispatchOrder> arrive(String id, int version) async => DispatchOrder(
    ApiDispatchOrderVO.fromJson(
      await _send(
            () => client.dio.post(
              ApiPaths.dispatchPilotOrdersArrivePath(id),
              data: ApiDispatchAssignmentDTO(
                assignmentVersion: version,
              ).toJson(),
            ),
          )
          as Map<String, dynamic>,
    ),
  );
  Future<void> release(String id, int version) async {
    await _send(
      () => client.dio.post(
        ApiPaths.dispatchPilotOrdersReleasePath(id),
        data: ApiDispatchAssignmentDTO(assignmentVersion: version).toJson(),
      ),
      allowEmpty: true,
    );
  }

  Future<DispatchOrder> get(String id) async => DispatchOrder(
    ApiDispatchOrderVO.fromJson(
      await _send(() => client.dio.get(ApiPaths.getDispatchOrdersPath(id)))
          as Map<String, dynamic>,
    ),
  );
  Future<DispatchOrder> pay(String id) async => DispatchOrder(
    ApiDispatchOrderVO.fromJson(
      await _send(
            () =>
                client.dio.post(ApiPaths.dispatchOrdersSimulatePaymentPath(id)),
          )
          as Map<String, dynamic>,
    ),
  );
  Future<DispatchOrder> cancel(String id) async => DispatchOrder(
    ApiDispatchOrderVO.fromJson(
      await _send(() => client.dio.post(ApiPaths.dispatchOrdersCancelPath(id)))
          as Map<String, dynamic>,
    ),
  );
}
