public class TrainingContext {
    @RemoteResource public var zoneSystem: ZoneSystem?
    
    internal func setZoneSystem(_ zoneSystem: RemoteResource<ZoneSystem>) {
        self._zoneSystem = zoneSystem
    }
}

extension CodingUserInfoKey {
    static let trainingContext = CodingUserInfoKey(rawValue: "trainingContext")!
}
