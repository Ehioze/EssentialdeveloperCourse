//
//  RemoteFeedLoaderTests.swift
//  FeedLoaderTests
//
//  Created by sinbyte on 27/12/2024.
//

import XCTest
import FeedLoader

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
            let (_, client) = makeSUT()
            
            XCTAssertTrue(client.requestedURLs.isEmpty)
        }
        
        func test_load_requestsDataFromURL() {
            let url = URL(string: "https://a-given-url.com")!
            let (sut, client) = makeSUT(url: url)
            
            sut.load { _ in }
            
            XCTAssertEqual(client.requestedURLs, [url])
        }
        
        func test_loadTwice_requestsDataFromURLTwice() {
            let url = URL(string: "https://a-given-url.com")!
            let (sut, client) = makeSUT(url: url)
            
            sut.load { _ in }
            sut.load { _ in }
            
            XCTAssertEqual(client.requestedURLs, [url, url])
        }
        
        func test_load_deliversErrorOnClientError() {
            let (sut, client) = makeSUT()
            expect(sut, toCompleteWith: .failure(.connectivity)) {
                let clientError = NSError(domain: "Test", code: 0)
                client.complete(with: clientError)
            }
        }
        
        func test_load_deliversErrorOnNon200HTTPResponse() {
            let (sut, client) = makeSUT()
            
            let samples = [199, 201, 300, 400, 500]
            
            samples.enumerated().forEach { index, code in
                
                expect(sut, toCompleteWith: .failure(.invalidData)) {
                    client.complete(withStatusCode: code, at: index)
                }
            }
        }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON(){
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            let invalidJSON = Data(bytes: "Invalid json data".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList(){
        let (sut, client) = makeSUT()
       
        expect(sut, toCompleteWith: .success([])) {
            let emptyListJSON = Data(bytes: "{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }
    
    func test_load_deliversItemOn200HTTPResponseWithJSONItems(){
        let (sut, client) = makeSUT()
        
        let item1 = FeedItem(
            id: UUID(),
            description: nil,
            location: nil,
            imageURL: URL(string: "http://a-url.com")!)
        
        let item1Json = [
            "id": item1.id.uuidString,
            "image": item1.imageURL.absoluteString
        ]
        
        let item2 = FeedItem(
            id: UUID(),
            description: "a dummy description",
            location: "A location",
            imageURL: URL(string: "http://a-url.com")!)
        
        let item2Json = [
            "id": item2.id.uuidString,
            "description": item2.description,
            "location": item2.location,
            "image": item2.imageURL.absoluteString
        ]
        
        let itemsJSON = [
            "items": [item1Json, item2Json]
        ]
        
        expect(sut, toCompleteWith: .success([item1, item2])) {
            let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
   
        
        // MARK: - Helpers
        
        private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
            let client = HTTPClientSpy()
            let sut = RemoteFeedLoader(url: url, client: client)
            return (sut, client)
        }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line){
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, [result], file: file, line:  line)
        
    }

        private class HTTPClientSpy: HTTPClient {
            private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
            
            var requestedURLs: [URL] {
                return messages.map { $0.url }
            }
            
            func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
                messages.append((url, completion))
            }
            
            func complete(with error: Error, at index: Int = 0) {
                messages[index].completion(.failure(error))
            }
            
            func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
                let response = HTTPURLResponse(
                    url: requestedURLs[index],
                    statusCode: code,
                    httpVersion: nil,
                    headerFields: nil
                )!
                messages[index].completion(.success(data, response))
            }
        }

}
