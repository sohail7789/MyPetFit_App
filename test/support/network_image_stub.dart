import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// A 1×1 transparent PNG, returned for every image request under test.
final Uint8List _transparentPixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

/// Serves a stub image for any network request.
///
/// `TestWidgetsFlutterBinding` fails every real HTTP call with a 400, which
/// makes any widget containing an `Image.network` throw during the test.
/// Installing this in `setUpAll` lets those widgets build normally.
class StubNetworkImages extends HttpOverrides {
  /// Installs the override for the current test suite.
  static void install() => HttpOverrides.global = StubNetworkImages();

  @override
  HttpClient createHttpClient(SecurityContext? context) => _StubClient();
}

class _StubClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _StubRequest();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _StubRequest();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _StubHeaders();

  @override
  Future<HttpClientResponse> close() async => _StubResponse();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubResponse implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _transparentPixel.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.value(_transparentPixel).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubHeaders implements HttpHeaders {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
