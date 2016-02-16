import XCTest
import OHHTTPStubs
import APIKit

class RequestTypeTests: XCTestCase {
    struct SearchRequest: MockSessionRequestType {
        let query: String
        
        // MARK: RequestType
        typealias Response = [String: AnyObject]
        
        var method: HTTPMethod {
            return .GET
        }
        
        var path: String {
            return "/"
        }
        
        var parameters: [String: AnyObject] {
            return [
                "q": query,
                "dummy": NSNull()
            ]
        }
        
        func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
            guard let response = object as? [String: AnyObject] else {
                throw FatalError("Invalid object \(object)")
            }
            return response
        }
    }
    
    // request type for URL building tests
    struct ParameterizedRequest: RequestType {
        typealias Response = Void
        
        init?(baseURL: String = "https://example.com", path: String = "/", method: HTTPMethod = .GET, parameters: [String: AnyObject] = [:], HTTPHeaderFields: [String: String] = [:]) {
            guard let baseURL = NSURL(string: baseURL) else {
                return nil
            }
            
            self.baseURL = baseURL
            self.path = path
            self.method = method
            self.parameters = parameters
            self.HTTPHeaderFields = HTTPHeaderFields
        }
        
        let baseURL: NSURL
        let method: HTTPMethod
        let path: String
        let parameters: [String: AnyObject]
        let HTTPHeaderFields: [String: String]
        
        func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
            abort()
        }
    }

    func URLOfRequest<T: RequestType>(request: T?) -> NSURL? {
        guard let request = request, URL = try? request.buildURLRequest().URL else {
            return nil
        }

        return URL
    }

    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testJapanesesURLQueryParameterEncoding() {
        OHHTTPStubs.stubRequestsPassingTest({ request in
            XCTAssertEqual(request.URL?.query, "q=%E3%81%93%E3%82%93%E3%81%AB%E3%81%A1%E3%81%AF&dummy")
            return true
        }, withStubResponse: { request in
            return OHHTTPStubsResponse(data: NSData(), statusCode: 200, headers: nil)
        })
        
        let request = SearchRequest(query: "こんにちは")
        let expectation = expectationWithDescription("waiting for the response.")
        
        Session.sendRequest(request) { result in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testSymbolURLQueryParameterEncoding() {
        OHHTTPStubs.stubRequestsPassingTest({ request in
            XCTAssertEqual(request.URL?.query, "q=%21%22%23%24%25%26%27%28%290%3D~%7C%60%7B%7D%2A%2B%3C%3E?_&dummy")
            return true
        }, withStubResponse: { request in
            return OHHTTPStubsResponse(data: NSData(), statusCode: 200, headers: nil)
        })
        
        let request = SearchRequest(query: "!\"#$%&'()0=~|`{}*+<>?_")
        let expectation = expectationWithDescription("waiting for the response.")
        
        Session.sendRequest(request) { result in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testHTTPHeaderFields() {
        guard let request = ParameterizedRequest(HTTPHeaderFields: ["Foo": "f", "Accept": "a", "Content-Type": "c"]) else {
            XCTFail()
            return
        }

        let URLReqeust = try? request.buildURLRequest()
        XCTAssertEqual(URLReqeust?.valueForHTTPHeaderField("Foo"), "f")
        XCTAssertEqual(URLReqeust?.valueForHTTPHeaderField("Accept"), "a")
        XCTAssertEqual(URLReqeust?.valueForHTTPHeaderField("Content-Type"), "c")
    }

    func testBuildURL() {
        // MARK: - baseURL = https://example.com
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "")),
            NSURL(string: "https://example.com")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "/")),
            NSURL(string: "https://example.com/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "/", parameters: ["p": 1])),
            NSURL(string: "https://example.com/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "foo")),
            NSURL(string: "https://example.com/foo")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "/foo", parameters: ["p": 1])),
            NSURL(string: "https://example.com/foo?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "/foo/")),
            NSURL(string: "https://example.com/foo/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "/foo/", parameters: ["p": 1])),
            NSURL(string: "https://example.com/foo/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "foo/bar")),
            NSURL(string: "https://example.com/foo/bar")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "/foo/bar")),
            NSURL(string: "https://example.com/foo/bar")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "/foo/bar", parameters: ["p": 1])),
            NSURL(string: "https://example.com/foo/bar?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "/foo/bar/")),
            NSURL(string: "https://example.com/foo/bar/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "/foo/bar/", parameters: ["p": 1])),
            NSURL(string: "https://example.com/foo/bar/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com", path: "/foo/bar//")),
            NSURL(string: "https://example.com/foo/bar//")
        )
        
        // MARK: - baseURL = https://example.com/
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "")),
            NSURL(string: "https://example.com/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "/")),
            NSURL(string: "https://example.com//")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "/", parameters: ["p": 1])),
            NSURL(string: "https://example.com//?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "foo")),
            NSURL(string: "https://example.com/foo")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "/foo")),
            NSURL(string: "https://example.com//foo")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "/foo", parameters: ["p": 1])),
            NSURL(string: "https://example.com//foo?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "/foo/")),
            NSURL(string: "https://example.com//foo/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "/foo/", parameters: ["p": 1])),
            NSURL(string: "https://example.com//foo/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "foo/bar")),
            NSURL(string: "https://example.com/foo/bar")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "/foo/bar")),
            NSURL(string: "https://example.com//foo/bar")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "/foo/bar", parameters: ["p": 1])),
            NSURL(string: "https://example.com//foo/bar?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "/foo/bar/")),
            NSURL(string: "https://example.com//foo/bar/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "/foo/bar/", parameters: ["p": 1])),
            NSURL(string: "https://example.com//foo/bar/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/", path: "foo//bar//")),
            NSURL(string: "https://example.com/foo//bar//")
        )
        
        // MARK: - baseURL = https://example.com/api
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "")),
            NSURL(string: "https://example.com/api")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "/")),
            NSURL(string: "https://example.com/api/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "/", parameters: ["p": 1])),
            NSURL(string: "https://example.com/api/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "foo")),
            NSURL(string: "https://example.com/api/foo")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "/foo")),
            NSURL(string: "https://example.com/api/foo")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "/foo", parameters: ["p": 1])),
            NSURL(string: "https://example.com/api/foo?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "/foo/")),
            NSURL(string: "https://example.com/api/foo/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "/foo/", parameters: ["p": 1])),
            NSURL(string: "https://example.com/api/foo/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "foo/bar")),
            NSURL(string: "https://example.com/api/foo/bar")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "/foo/bar")),
            NSURL(string: "https://example.com/api/foo/bar")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "/foo/bar", parameters: ["p": 1])),
            NSURL(string: "https://example.com/api/foo/bar?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "/foo/bar/")),
            NSURL(string: "https://example.com/api/foo/bar/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "/foo/bar/", parameters: ["p": 1])),
            NSURL(string: "https://example.com/api/foo/bar/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api", path: "foo//bar//")),
            NSURL(string: "https://example.com/api/foo//bar//")
        )
        
        // MARK: - baseURL = https://example.com/api/
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "")),
            NSURL(string: "https://example.com/api/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "/")),
            NSURL(string: "https://example.com/api//")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "/", parameters: ["p": 1])),
            NSURL(string: "https://example.com/api//?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "foo")),
            NSURL(string: "https://example.com/api/foo")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "/foo")),
            NSURL(string: "https://example.com/api//foo")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "/foo", parameters: ["p": 1])),
            NSURL(string: "https://example.com/api//foo?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "/foo/")),
            NSURL(string: "https://example.com/api//foo/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "/foo/", parameters: ["p": 1])),
            NSURL(string: "https://example.com/api//foo/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "foo/bar")),
            NSURL(string: "https://example.com/api/foo/bar")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "/foo/bar")),
            NSURL(string: "https://example.com/api//foo/bar")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "/foo/bar", parameters: ["p": 1])),
            NSURL(string: "https://example.com/api//foo/bar?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "/foo/bar/")),
            NSURL(string: "https://example.com/api//foo/bar/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "/foo/bar/", parameters: ["p": 1])),
            NSURL(string: "https://example.com/api//foo/bar/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com/api/", path: "foo//bar//")),
            NSURL(string: "https://example.com/api/foo//bar//")
        )
        
        //　MARK: - baseURL = https://example.com///
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "")),
            NSURL(string: "https://example.com///")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "/")),
            NSURL(string: "https://example.com////")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "/", parameters: ["p": 1])),
            NSURL(string: "https://example.com////?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "foo")),
            NSURL(string: "https://example.com///foo")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "/foo")),
            NSURL(string: "https://example.com////foo")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "/foo", parameters: ["p": 1])),
            NSURL(string: "https://example.com////foo?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "/foo/")),
            NSURL(string: "https://example.com////foo/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "/foo/", parameters: ["p": 1])),
            NSURL(string: "https://example.com////foo/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "foo/bar")),
            NSURL(string: "https://example.com///foo/bar")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "/foo/bar")),
            NSURL(string: "https://example.com////foo/bar")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "/foo/bar", parameters: ["p": 1])),
            NSURL(string: "https://example.com////foo/bar?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "/foo/bar/")),
            NSURL(string: "https://example.com////foo/bar/")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "/foo/bar/", parameters: ["p": 1])),
            NSURL(string: "https://example.com////foo/bar/?p=1")
        )
        
        XCTAssertEqual(
            URLOfRequest(ParameterizedRequest(baseURL: "https://example.com///", path: "foo//bar//")),
            NSURL(string: "https://example.com///foo//bar//")
        )
    }
}
