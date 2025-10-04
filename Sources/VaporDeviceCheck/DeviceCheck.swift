import Vapor
import JWT

public struct NoAppleDeviceTokenError: DebuggableError {
    public var identifier: String = "NoAppleDeviceTokenError"
    public var reason: String = "No X-Apple-Device-Token header provided."
}

public struct DeviceCheck: Middleware {
    let excludes: [[PathComponent]]?
    /// Tokens to include via environment to bypass device check. Designed for applications like the xcode simulator
    let bypassTokens: Set<String>
    let client: DeviceCheckClient
    
    public init(jwkKid: JWKIdentifier, jwkIss: String, excludes: [[PathComponent]]? = nil, bypassTokens: Set<String> = [], client: DeviceCheckClient? = nil) {
        self.excludes = excludes
        self.bypassTokens = bypassTokens
        self.client = client ?? AppleDeviceCheckClient(jwkKid: jwkKid, jwkIss: jwkIss)
    }
    
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        requestDeviceCheck(on: request, chainingTo: next, isSandbox: [Environment.development, Environment.testing].contains((try? Environment.detect()) ?? .production))
    }

    private func requestDeviceCheck(on request: Request, chainingTo next: Responder, isSandbox: Bool) -> EventLoopFuture<Response> {
        if excludes?.map({ $0.string }).contains(where: { $0 == request.route?.path.string }) ?? false {
            return next.respond(to: request)
        }
        
        guard let xAppleDeviceToken = request.headers.first(name: .xAppleDeviceToken) else {
            return request.eventLoop.makeFailedFuture(NoAppleDeviceTokenError())
        }
        
        if bypassTokens.contains(where: { $0 == (String(data: Data(base64Encoded: xAppleDeviceToken) ?? Data(), encoding: .utf8) ?? xAppleDeviceToken) }) {
            return next.respond(to: request)
        }
                
        return client.request(request, deviceToken: xAppleDeviceToken, isSandbox: isSandbox)
            .flatMap { res in
                if res.status == .ok {
                    return next.respond(to: request)
                }
                
                if isSandbox {
                    return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
                }
                
                return self.requestDeviceCheck(on: request, chainingTo: next, isSandbox: true)
        }
    }
}
