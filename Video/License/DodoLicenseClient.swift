import Foundation

enum DodoLicenseError: LocalizedError {
    case notFound
    case inactive
    case activationLimit
    case invalid
    case malformedKey
    case server
    case network
    case unexpected

    var errorDescription: String? {
        switch self {
        case .notFound:
            "That license key was not found."
        case .inactive:
            "This license is inactive."
        case .activationLimit:
            "This key is already used on the maximum number of Macs. Buy a 2 or 4 PC license to add devices."
        case .invalid:
            "This license key is not valid."
        case .malformedKey:
            "Use a key like \(LicenseConfig.keyPlaceholder)."
        case .server:
            "The license server had a problem. Try again in a moment."
        case .network:
            "Couldn't reach the license server. Check your connection and try again."
        case .unexpected:
            "Something went wrong while checking the license."
        }
    }
}

enum DodoLicenseClient {
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }()

    static func activate(licenseKey: String, deviceName: String) async throws -> String {
        do {
            return try await activate(licenseKey: licenseKey, deviceName: deviceName, on: LicenseConfig.environment)
        } catch DodoLicenseError.notFound {
            return try await activate(licenseKey: licenseKey, deviceName: deviceName, on: LicenseConfig.environment.fallback)
        }
    }

    static func validate(licenseKey: String, instanceID: String?) async throws -> Bool {
        if try await validate(licenseKey: licenseKey, instanceID: instanceID, on: LicenseConfig.environment) {
            return true
        }
        return try await validate(
            licenseKey: licenseKey,
            instanceID: instanceID,
            on: LicenseConfig.environment.fallback
        )
    }

    private static func activate(
        licenseKey: String,
        deviceName: String,
        on environment: LicenseConfig.Environment
    ) async throws -> String {
        let body = ActivateRequest(license_key: licenseKey, name: deviceName)
        let (data, status) = try await post(path: "licenses/activate", body: body, on: environment)
        switch status {
        case 201:
            guard let response = try? JSONDecoder().decode(ActivateResponse.self, from: data),
                  !response.id.isEmpty
            else {
                throw DodoLicenseError.unexpected
            }
            return response.id
        case 403:
            throw DodoLicenseError.inactive
        case 404:
            throw DodoLicenseError.notFound
        case 422:
            throw DodoLicenseError.activationLimit
        case 500...599:
            throw DodoLicenseError.server
        default:
            throw DodoLicenseError.unexpected
        }
    }

    private static func validate(
        licenseKey: String,
        instanceID: String?,
        on environment: LicenseConfig.Environment
    ) async throws -> Bool {
        let body = ValidateRequest(
            license_key: licenseKey,
            license_key_instance_id: instanceID
        )
        let (data, status) = try await post(path: "licenses/validate", body: body, on: environment)
        switch status {
        case 200:
            guard let response = try? JSONDecoder().decode(ValidateResponse.self, from: data) else {
                throw DodoLicenseError.unexpected
            }
            return response.valid
        case 404:
            return false
        case 422:
            throw DodoLicenseError.invalid
        case 500...599:
            throw DodoLicenseError.server
        default:
            throw DodoLicenseError.unexpected
        }
    }

    private static func post<Body: Encodable>(
        path: String,
        body: Body,
        on environment: LicenseConfig.Environment
    ) async throws -> (Data, Int) {
        let url = environment.apiRoot.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw DodoLicenseError.unexpected
            }
            return (data, http.statusCode)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as DodoLicenseError {
            throw error
        } catch {
            throw DodoLicenseError.network
        }
    }
}

private struct ActivateRequest: Encodable {
    var license_key: String
    var name: String
}

private struct ActivateResponse: Decodable {
    var id: String
}

private struct ValidateRequest: Encodable {
    var license_key: String
    var license_key_instance_id: String?

    private enum CodingKeys: String, CodingKey {
        case license_key
        case license_key_instance_id
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(license_key, forKey: .license_key)
        if let license_key_instance_id {
            try container.encode(license_key_instance_id, forKey: .license_key_instance_id)
        }
    }
}

private struct ValidateResponse: Decodable {
    var valid: Bool
}
