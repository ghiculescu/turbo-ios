import Foundation

public typealias PathProperties = [String: AnyHashable]

public protocol PathConfigurationDelegate: class {
    /// Notifies delegate when a path configuration has been updated with new data
    func pathConfigurationDidUpdate()
}

public final class PathConfiguration {
    public weak var delegate: PathConfigurationDelegate?
    
    /// Returns top-level settings
    public private(set) var settings: [String: AnyHashable] = [:]
    
    /// The list of rules from the configuration
    public private(set) var rules: [PathRule] = []
    
    /// Sources for this configuration, setting it will
    /// cause the configuration to be loaded from the new sources
    public var sources: [Source] = [] {
        didSet {
            load()
        }
    }
    
    /// Multiple sources will be loaded in order
    /// Remote sources should be last since they're loaded async
    public init(sources: [Source] = []) {
        self.sources = sources
        load()
    }
    
    /// Convenience method for getting properties
    /// configuration["/path"]
    public subscript(path: String) -> PathProperties {
        properties(for: path)
    }
    
    /// Returns a merged dictionary containing all the properties
    /// that match this url, currently only looks at path, not query
    public func properties(for url: URL) -> PathProperties {
        properties(for: url.path)
    }
    
    /// Returns a merged dictionary containing all the properties
    /// that match this path
    public func properties(for path: String) -> PathProperties {
        var properties: PathProperties = [:]
        
        for rule in rules where rule.match(path: path) {
            properties.merge(rule.properties) { _, new in new }
        }
        
        return properties
    }
    
    // MARK: - Loading

    private var loader: PathConfigurationLoader?

    private func load() {
        loader = PathConfigurationLoader(sources: sources)
        loader?.load { [weak self] config in
            self?.update(with: config)
        }
    }
    
    private func update(with config: PathConfigurationDecoder) {
        // Update our internal state with the config from the loader
        settings = config.settings
        rules = config.rules
        delegate?.pathConfigurationDidUpdate()
    }
}

extension PathConfiguration: Equatable {
    public static func == (lhs: PathConfiguration, rhs: PathConfiguration) -> Bool {
        lhs.settings == lhs.settings && lhs.rules == rhs.rules
    }
}

extension PathConfiguration {
    public enum Source: Equatable {
        case data(Data)
        case file(URL)
        case server(URL)
    }
}
