//
//  The Network Service is an iOS implementation that facilitates network communication and data retrieval using Alamofire, Foundation, and
//  Combine. Alamofire, a popular networking library, handles API requests and responses. Foundation provides fundamental data types and
//  tools, while Combine enables asynchronous data processing using publishers and subscribers. The NetworkService class manages the network
//  session through Alamofire's Session, allowing efficient handling of API requests. It also supports data fetching with data, status code,
//  and JSON response types through generic methods. The network reachability check ensures connectivity before initiating requests. By
//  combining these technologies, the implementation achieves robust and efficient network communication, making it suitable for various iOS
//  applications that rely on web services.

import Foundation
import Combine
import Alamofire

final class NetworkService: NetworkServiceProtocol {
    private let sessionManager: Session
    private let responseSerializer = BaseDataResponseSerializer()
    private let responseCodeSerializer = StatusCodeResponseSerializer()

    private let queue: DispatchQueue = .init(
        label: String(describing: NetworkService.self),
        qos: .background
    )

    init(sessionManager: Session) {
        self.sessionManager = sessionManager
    }

    // MARK: - Instance Methods

    private func createUrlRequest<T: NetworkingRequest>(_ request: T) throws -> URLRequest {
        let requestDescriptor = request.getRequestDescriptor()
        let url = requestDescriptor.baseUrl
            .appendingPathComponent(requestDescriptor.prefix)
            .appendingPathComponent(requestDescriptor.path)
        var urlRequest = try URLRequest(url: url, method: requestDescriptor.method)
        urlRequest = applyAdapter(urlRequest, requestDescriptor: requestDescriptor)
        urlRequest = try requestDescriptor.encoding.encode(urlRequest, with: requestDescriptor.params)
        return urlRequest
    }

    private func applyAdapter(
        _ urlRequest: URLRequest,
        requestDescriptor: RequestDescriptor
    ) -> URLRequest {
        var urlRequest = urlRequest
        urlRequest.allHTTPHeaderFields = requestDescriptor.headers
        return urlRequest
    }

    private var isConnected: Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
}

extension NetworkService {
    func data<T: NetworkingRequest>(_ request: T) -> AnyPublisher<Data, NetworkError> {
        doRequest(request: request, serializer: responseSerializer)
    }

    func statusCode<T: NetworkingRequest>(_ request: T) -> AnyPublisher<Int, NetworkError> {
        doRequest(request: request, serializer: responseCodeSerializer)
    }

    func json<T: NetworkingRequest>(_ request: T) -> AnyPublisher<T.ResponseType, NetworkError> {
        data(request)
            .tryMap {
                let object = try JSONDecoder().decode(T.ResponseType.self, from: $0)
                return object
            }
            .mapError { NetworkError.custom($0) }
            .eraseToAnyPublisher()
    }

    func silent<T: NetworkingRequest>(_ request: T) {
        guard isConnected else { return }
        guard let request = try? self.createUrlRequest(request) else { return }
        sessionManager.request(request).resume()
    }

    private func doRequest<Serializer: ResponseSerializer, R: NetworkingRequest, T>(
        request: R,
        serializer: Serializer
    ) -> AnyPublisher<T, NetworkError> where T == Serializer.SerializedObject {
        guard isConnected else { return Fail(error: NetworkError.noConnection).eraseToAnyPublisher() }
        guard let request = try? createUrlRequest(request) else {
            return Fail(error: NetworkError.badRequest).eraseToAnyPublisher()
        }
        return sessionManager.request(request)
            .publishResponse(using: serializer, on: queue)
            .value()
            .mapError { NetworkError.alamofireError(error: $0) }
            .eraseToAnyPublisher()
    }
}
