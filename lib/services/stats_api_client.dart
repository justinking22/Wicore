import 'package:Wicore/models/stats_response_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'stats_api_client.g.dart';

@RestApi()
abstract class StatsApiClient {
  factory StatsApiClient(Dio dio) = _StatsApiClient;

  @GET('/stats/{date}')
  Future<StatsResponse> getStats(@Path('date') String date);
}
