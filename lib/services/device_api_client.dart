import 'package:Wicore/models/active_device_model.dart';
import 'package:Wicore/models/device_list_response_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:Wicore/models/device_request_model.dart';
import 'package:Wicore/models/device_response_model.dart';

part 'device_api_client.g.dart';

@RestApi()
abstract class DeviceApiClient {
  factory DeviceApiClient(Dio dio) =
      _DeviceApiClient; // Remove baseUrl parameter

  @POST('/device/pair')
  Future<DeviceResponse> registerDevice(@Body() DeviceRequest request);

  @GET('/device/active')
  Future<ActiveDeviceResponse> getActiveDevices({
    @Query('uId') required String userId,
  });

  @GET('/device/all')
  Future<DeviceListResponse> getAllDevices({
    @Query('uId') required String userId,
  });

  @DELETE('/device/unpair/{dId}')
  Future<DeviceListResponse> unpairDevice({
    @Path('dId') required String deviceId,
  });
}
