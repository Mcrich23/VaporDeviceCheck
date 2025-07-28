import Vapor
import JWT

public struct AppleDeviceCheckClient: DeviceCheckClient, Sendable {
    public let jwkKid: JWKIdentifier
    public let jwkIss: String
    
    public func request(_ request: Request, deviceToken: String, isSandbox: Bool) -> EventLoopFuture<ClientResponse> {
        let promise = request.eventLoop.makePromise(of: ClientResponse.self)
        
        promise.completeWithTask {
            var headers = HTTPHeaders()
            headers.add(name: .authorization, value: "Bearer \(try await signedJwt(for: request))")
            
            let response = try await request.client.put((URI(string: "https://\(isSandbox ? "api.development" : "api").devicecheck.apple.com/v1/validate_device_token")), headers: headers, content: DeviceCheckRequest(deviceToken: deviceToken))
            
            return response
        }
        
        return promise.futureResult
    }
    
    private func signedJwt(for request: Request) async throws -> String {
        try await request.jwt.sign(DeviceCheckJWT(iss: jwkIss), kid: jwkKid)
    }
}

private struct DeviceCheckJWT: JWTPayload {
    let iss: String
    let iat: Int = Int(Date().timeIntervalSince1970)
    
    func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {
        //no-op
    }
}
