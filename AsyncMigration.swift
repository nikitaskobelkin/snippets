// The Asynchronous Combine Extension enhances Combine's functionality by providing a convenient way to convert an AnyPublisher into an
// asynchronous task using Swift's async/await feature. The extension is designed to simplify handling Combine publishers within the context
// of asynchronous tasks. By extending AnyPublisher, the async() method transforms the publisher into a Swift async function, enabling easy
// integration into async/await workflows. The async() method utilizes a withCheckedContinuation to encapsulate the publisher's result, and
// then asynchronously resumes the continuation with either the success value or the failure error, as appropriate. By incorporating this
// extension, you can seamlessly integrate Combine publishers into Swift's new concurrency model, simplifying code for asynchronous
// operations and promoting more natural integration of Combine in asynchronous contexts.


import Combine

extension AnyPublisher {
    func async() async -> Result<Output, Failure> {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(returning: .failure(error))
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    continuation.resume(returning: .success(value))
                }
        }
    }
}
