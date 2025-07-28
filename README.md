# 📱 VaporDeviceCheck

A Vapor 4 Middleware implementing the Apple DeviceCheck API.

## 🛠 Using the Middleware

First add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/Bearologics/VaporDeviceCheck", from: "1.0.1")
```

Then configure your Vapor `Application` and make sure to set up the JWT credentials to authenticate against the DeviceCheck API, in this example we're using environment variables which are prefixed `APPLE_JWT_` and install the Middleware with this setup function:

```swift
import Vapor
import JWTKit
import VaporDeviceCheck

enum ConfigurationError: Error {
    case noAppleJwtPrivateKey, noAppleJwtKid, noAppleJwtIss
}

// configures your application
public func configureDeviceCheck(_ app: Application) async throws {
    guard let jwtPrivateKeyStringEscaped = Environment.get("APPLE_JWT_PRIVATE_KEY") else {
        throw ConfigurationError.noAppleJwtPrivateKey
    }
    let jwtPrivateKeyString = jwtPrivateKeyStringEscaped.replacingOccurrences(of: "\\n", with: "\n")
    
    guard let jwtKidString = Environment.get("APPLE_JWT_KID") else {
        throw ConfigurationError.noAppleJwtKid
    }
    guard let jwtIss = Environment.get("APPLE_JWT_ISS") else {
        throw ConfigurationError.noAppleJwtIss
    }
    
    let jwtBypassToken = Environment.get("APPLE_JWT_BYPASS_TOKEN")

    let kid = JWKIdentifier(string: jwtKidString)
    let privateKey = try ES256PrivateKey(pem: Data(jwtPrivateKeyString.utf8))

    // Add ECDSA key with JWKIdentifier
    await app.jwt.keys.add(ecdsa: privateKey, kid: kid)

    app.middleware.use(DeviceCheck(
        jwkKid: kid,
        jwkIss: jwtIss,
        excludes: [["health"]],
        bypassTokens: jwtBypassToken == nil ? [] : [jwtBypassToken!]
    ))
}
```

Then you call it from configure:

```swift
public func configure(_ app: Application) async throws {
    try await configureDeviceCheck(app)
    ...
}
```

That's basically it, from now on, every request that'll pass the Middleware will require a valid `X-Apple-Device-Token` header to be set, otherwise it will be rejected.

> **Note:** You can pass in the private key either multilined or single-lined separated by `\n` and it will parse the key correctly. 

## 🔑 Setting up your App / Retrieving a DeviceCheck Token

You'll need to import Apple's `DeviceCheck` Framework to retrieve a token for your device.

```swift
import DeviceCheck

DCDevice.current.generateToken { data, error in 
	guard 
		error == nil,
		let data = data
	else {
		// handle error
		return
	}
	
	let xAppleDeviceCheckToken = data.base64EncodedString()
}

```

The `xAppleDeviceCheckToken` base64 string will be your `X-Apple-Device-Token` header value.

## 📗 How it works

Under the hood the Middleware will call `api(.development).devicecheck.apple.com`, authenticate using the JWT provided and check if the value of the `X-Apple-Device-Token` header is a valid DeviceCheck Token.

The Middleware will first try to validate the token against Apple's production environment, if this fails it will try the sandbox environment, if both fail it will bail out with an appropriate error response.

## 👩‍💼 License

[See here.](LICENSE.md)
