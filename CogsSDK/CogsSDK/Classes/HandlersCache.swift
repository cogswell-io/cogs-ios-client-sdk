//
//  HandlersCache.swift
//


import Foundation

typealias OperationHandler = (_ result: PubSubResponse?, _ error: PubSubErrorResponse?) -> ()

class Handler {
    
    public var closure: OperationHandler?
    
    public var timer: (() -> ())?

    public var completed: Bool = false
    
    public var isAlive: Bool = true
    
    public var disposable: Bool = true
    
    public init(_ closure: @escaping OperationHandler) {
        self.closure = closure
    }
    
    public init(_ failure: @escaping (PubSubErrorResponse?) -> ()) {
        self.disposable = false
        self.closure = { (_ result: PubSubResponse?, _ error: PubSubErrorResponse?) -> () in
            failure(error)
        }
    }
}

class HandlersCache {
    
    private var cache:[String : Handler] = [String : Handler]()
    
    private var timerQueue = DispatchQueue(label: "TimerQueue")
    
    public var countLimit: Int = 10000
    
    public var objectAge: Int  = 60 //seconds
    
    public var dispose: ((_ handler: Handler, _ sequence: String) -> ())?
    
    public init() { }
    
    public func object(forKey key: Int) -> Handler? {
        
        //check is the handler still alive
        if let object = cache[String(key)] {
            if object.isAlive {
                return cache[String(key)]
            }
            else {
                _ = self.removeObject(forKey: key)
            }
        }
        
        return nil
    }
    
    public func setObject(_ obj: Handler, forKey key: Int) {
        guard cache.count < countLimit  else { return }
        
        //set handler's live timer
        obj.timer = {
            let deadlineTime = DispatchTime.now() + .seconds(self.objectAge)
            self.timerQueue.asyncAfter(deadline: deadlineTime, execute: {
                obj.isAlive = false
                self.dispose?(obj, String(key))
                _ = self.removeObject(forKey: key)
                print("\(key) OBJECT LIVE EXPIRED.")
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
