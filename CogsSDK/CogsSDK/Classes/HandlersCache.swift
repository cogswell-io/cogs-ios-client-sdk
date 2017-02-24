//
//  HandlersCache.swift
//


import Foundation

public typealias CompletionHandler = (_ json: JSON?, _ error: PubSubResponseError?) -> ()

class Handler {
    
    public var closure: CompletionHandler?
    
    public var timestamp: TimeInterval
    
    public func isAlive(forTime: Int) -> Bool {
        let time_now = Date().timeIntervalSince1970
        let ttl = lround(time_now - timestamp)
        return ttl < forTime
    }
    
    public init(_ closure: @escaping CompletionHandler) {
        self.closure = closure
        self.timestamp = Date().timeIntervalSince1970
    }
}

class HandlersCache {
    
    private var cache:[String : Handler] = [String : Handler]()
    
    public var countLimit: Int = 10000
    
    public var objectAge: Int  = 60 //seconds
    
    public init() { }
    
    public func object(forKey key: Int) -> Handler? {
        
        //check is the handler still alive
        if let object = cache[String(key)] {
            if object.isAlive(forTime: objectAge) == true {
                return cache[String(key)]
            }
            else {
                self.removeObject(forKey: key)
            }
        }
        
        return nil
    }
    
    public func setObject(_ obj: Handler, forKey key: Int) {
        guard cache.count < countLimit  else { return }
        
        cache[String(key)] = obj
    }
    
    public func removeObject(forKey key: Int) -> Handler? {
        return cache.removeValue(forKey: String(key))
    }
    
    public func removeAllObjects() {
        cache.removeAll()
    }
    
}
