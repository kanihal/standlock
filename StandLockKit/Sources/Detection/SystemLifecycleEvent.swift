import Foundation

/// Login names and other accounting data are discarded by the reader.
public struct SystemLifecycleEvent: Sendable {
    public enum Kind: Sendable { case boot, shutdown, clockChange }
    public var kind: Kind
    public var date: Date

    public init(kind: Kind, date: Date) {
        self.kind = kind
        self.date = date
    }
}
