import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Simple HTTP Server

final class HTTPServer {
    private let port: UInt16
    private var serverSocket: Int32 = -1

    init(port: UInt16) {
        self.port = port
    }

    func start() throws {
        serverSocket = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        guard serverSocket >= 0 else {
            throw ServerError.socketCreationFailed
        }

        // Allow address reuse so restarts don't hit "address already in use"
        var reuse: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr.s_addr = INADDR_ANY

        let bindResult = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(serverSocket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else {
            throw ServerError.bindFailed
        }

        guard listen(serverSocket, 128) == 0 else {
            throw ServerError.listenFailed
        }

        print("✅ Server listening on port \(port)")
        fflush(stdout)

        while true {
            var clientAddress = sockaddr_in()
            var clientAddressLength = socklen_t(MemoryLayout<sockaddr_in>.size)
            let clientSocket = withUnsafeMutablePointer(to: &clientAddress) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    accept(serverSocket, $0, &clientAddressLength)
                }
            }
            guard clientSocket >= 0 else { continue }

            handleConnection(clientSocket: clientSocket)
        }
    }

    private func handleConnection(clientSocket: Int32) {
        defer { close(clientSocket) }

        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = recv(clientSocket, &buffer, buffer.count - 1, 0)
        guard bytesRead > 0 else { return }

        let requestString = String(bytes: buffer.prefix(bytesRead), encoding: .utf8) ?? ""
        let (statusCode, statusText, body) = route(request: requestString)

        let response =
            "HTTP/1.1 \(statusCode) \(statusText)\r\n" +
            "Content-Type: text/plain; charset=utf-8\r\n" +
            "Content-Length: \(body.utf8.count)\r\n" +
            "Connection: close\r\n" +
            "\r\n" +
            body

        response.withCString { ptr in
            _ = send(clientSocket, ptr, strlen(ptr), 0)
        }
    }

    // MARK: - Router

    private func route(request: String) -> (Int, String, String) {
        // Parse the first line: "METHOD /path HTTP/1.x"
        let firstLine = request.components(separatedBy: "\r\n").first ?? ""
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            return (400, "Bad Request", "Bad Request")
        }

        let method = parts[0]
        let path   = parts[1]

        switch (method, path) {
        case ("GET", "/"):
            return (200, "OK", "Hello from Swift on Railway!")
        case ("GET", "/health"):
            return (200, "OK", "OK")
        default:
            return (404, "Not Found", "Not Found")
        }
    }

    enum ServerError: Error {
        case socketCreationFailed
        case bindFailed
        case listenFailed
    }
}

// MARK: - Entry point

let server = HTTPServer(port: 8080)
do {
    try server.start()
} catch {
    print("❌ Failed to start server: \(error)")
    fflush(stdout)
    exit(1)
}
