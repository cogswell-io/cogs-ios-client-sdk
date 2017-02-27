//
//  HandlersCache.swift
//


import Foundation

public typealias CompletionHandler = (_ json: JSON?, _ error: PubSubErrorResponse?) -> ()

class Handler {
    
    public var closure: CompletionHandler?
    
    public var timer: (() -> ())?

    public var completed: Bool = false
    
    public var isAlive: Bool = true
    
    public init(_ closure: @escaping CompletionHandler) {
        self.closure = closure
    }
}

class HandlersCache {
    
    private var cache:[String : Handler] = [String : Handler]()
    
    public var countLimit: Int = 10000
    
    public var objectAge: Int  = 10 //seconds
    
    public var dispose: ((_ handler: Handler, _ sequence: String) -> ())?
    
    public init() { }
    
    public func object(forKey key: Int) -> Handler? {
        
        //check is the handler still alive
        if let object = cache[String(key)] {
            if object.isAlive {
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
        
        //set handler's live timer
        obj.timer = {
            let deadlineTime = DispatchTime.now() + .seconds(self.objectAge)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
                obj.isAlive = false
                self.dispose?(obj, String(key))
                self.removeObject(forKey: key)
                print("OBJECT LIVE EXPIRED.")
            })
        }
        
        cache[String(key)] = obj
        obj.timer?()
    }
    
    public func removeObject(forKey key: Int) -> Handler? {
        return cache.removeValue(forKey: String(key))
    }
    
    public func removeAllObjects() {
        cache.removeAll()
    }
}
