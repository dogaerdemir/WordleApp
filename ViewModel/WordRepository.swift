//
//  WordRepository.swift
//  WordleApp
//
//  Created by Doğa Erdemir on 15.10.2025.
//

import Foundation
import Combine

@MainActor
final class WordRepository: ObservableObject {
    static let shared = WordRepository()
    @Published private(set) var words: [String] = []
    
    private let session: URLSession
    private let sourceURL: URL
    
    init(session: URLSession = .shared,
         sourceURL: URL = URL(string: "https://raw.githubusercontent.com/mertemin/turkish-word-list/master/words.txt")!) {
        self.session = session
        self.sourceURL = sourceURL
    }
    
    func loadWordsIfNeeded() async {
        if !words.isEmpty { return }
        
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--useLocalWords") {
            self.words = ["kalem","bursa","izmir","kitap","kalemlik"]
            return
        }
#endif
        
        do {
            let (data, _) = try await session.data(from: sourceURL)
            if let text = String(data: data, encoding: .utf8) {
                let all = text.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    .filter {
                        !$0.isEmpty &&
                        !$0.contains(" ") &&
                        !$0.contains("-") &&
                        $0.allSatisfy({ $0.isLetter })
                    }
                self.words = all
            }
        } catch {
            print("Kelime listesi alınamadı: \(error)")
        }
    }
}

final class URLProtocolStub: URLProtocol {
    struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }
    private static var stub: Stub?
    
    static func register(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
        stub = Stub(data: data, response: response, error: error)
    }
    
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    
    override func startLoading() {
        guard let stub = URLProtocolStub.stub else { return }
        if let response = stub.response { client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed) }
        if let data = stub.data { client?.urlProtocol(self, didLoad: data) }
        if let error = stub.error { client?.urlProtocol(self, didFailWithError: error) }
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
