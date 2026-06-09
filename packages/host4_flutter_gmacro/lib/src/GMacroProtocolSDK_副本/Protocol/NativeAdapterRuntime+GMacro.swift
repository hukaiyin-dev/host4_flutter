import Foundation
import BluetoothKit

public extension NativeAdapterRuntime {

    /// 将 GMacroProtocolSession 绑定到已连接的 transport，返回 session 对象。
    @discardableResult
    func attachGMacroProtocol(transportSessionId: String,
                              onceByteLimit: Int = 20,
                              onEvent: @escaping (GMacroProtocolEvent) -> Void) -> GMacroProtocolSession? {
        guard let transport = TransportSessionRegistry.shared.getSession(transportSessionId) else {
            return nil
        }
        let session = GMacroProtocolSession(sessionId: UUID().uuidString, transport: transport)
        session.onceByteLimit = onceByteLimit
        session.onEvent = onEvent
        ProtocolSessionRegistry.shared.register(
            session.sessionId,
            protocolSession: session,
            transportSessionId: transportSessionId,
            closeHandler: { [weak session] in session?.close() }
        )
        return session
    }
}
