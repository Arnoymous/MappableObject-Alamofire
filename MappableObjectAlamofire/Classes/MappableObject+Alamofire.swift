//
//  MappableObject+Alamofire.swift
//  Pods
//
//  Created by Arnaud Dorgans on 01/09/2017.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2017 Arnaud Dorgans
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import RealmSwift
import Alamofire
import ObjectMapper
import MappableObject

extension DataRequest {
    
    enum ErrorCode: Int {
        case noData = 1
        case dataSerializationFailed = 2
    }
    
    internal static func newError(_ code: ErrorCode, failureReason: String) -> NSError {
        let errorDomain = "com.alamofireobjectmapper.error"
        
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        let returnError = NSError(domain: errorDomain, code: code.rawValue, userInfo: userInfo)
        
        return returnError
    }
    
    /// Utility function for checking for errors in response
    internal static func checkResponseForError(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) -> Error? {
        if let error = error {
            return error
        }
        guard let _ = data else {
            let failureReason = "Data could not be serialized. Input data was nil."
            let error = newError(.noData, failureReason: failureReason)
            return error
        }
        return nil
    }
    
    /// Utility function for extracting JSON from response
    internal static func processResponse(request: URLRequest?, response: HTTPURLResponse?, data: Data?, keyPath: String?) -> Any? {
        let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
        let result = jsonResponseSerializer.serializeResponse(request, response, data, nil)
        
        let JSON: Any?
        if let keyPath = keyPath , keyPath.isEmpty == false {
            JSON = (result.value as AnyObject?)?.value(forKeyPath: keyPath)
        } else {
            JSON = result.value
        }
        
        return JSON
    }
    
    /// MappableObject Object Serializer
    internal static func ObjectMapperSerializer<T: MappableObject>(_ keyPath: String?, mapToObject object: T? = nil, context: RealmMapContext? = nil, realm: Realm?, options: RealmMapOptions?) -> DataResponseSerializer<T> {
        return DataResponseSerializer { request, response, data, error in
            if let error = checkResponseForError(request: request, response: response, data: data, error: error){
                return .failure(error)
            }
            
            let JSONObject = processResponse(request: request, response: response, data: data, keyPath: keyPath)
            let context = RealmMapContext.from(context: context, realm: realm, options: options, object: object)
            let mapper = Mapper<T>(context: context, shouldIncludeNilValues: false)
            let realm = try! mapper.realm ?? Realm()
            
            if var object = object {
                try! realm.write {
                    object = mapper.map(JSONObject: JSONObject, toObject: object)
                }
                return .success(object)
            } else {
                var parsedObject: T?
                try! realm.write {
                    parsedObject = mapper.map(JSONObject: JSONObject)
                }
                if let parsedObject = parsedObject {
                    return .success(parsedObject)
                }
            }
            let failureReason = "ObjectMapper failed to serialize response."
            let error = newError(.dataSerializationFailed, failureReason: failureReason)
            return .failure(error)
        }
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter queue:             The queue on which the completion handler is dispatched.
     - parameter keyPath:           The key path where object mapping should be performed
     - parameter object:            An object to perform the mapping on to
     - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
     
     - returns: The request.
     */
    
    @discardableResult
    public func responseObject<T: MappableObject>(queue: DispatchQueue? = nil, keyPath: String? = nil, mapToObject object: T? = nil, context: RealmMapContext? = nil, realm: Realm?, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return responseObject(queue: queue, keyPath: keyPath, mapToObject: object, context: context, realm: realm, options: nil, completionHandler: completionHandler)
    }
    
    @discardableResult
    public func responseObject<T: MappableObject>(queue: DispatchQueue? = nil, keyPath: String? = nil, mapToObject object: T? = nil, context: RealmMapContext? = nil, realm: Realm? = nil, options: RealmMapOptions, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return responseObject(queue: queue, keyPath: keyPath, mapToObject: object, context: context, realm: realm, options: options as RealmMapOptions?, completionHandler: completionHandler)
    }
    
    @discardableResult
    internal func responseObject<T: MappableObject>(queue: DispatchQueue?, keyPath: String?, mapToObject object: T?, context: RealmMapContext?, realm: Realm?, options: RealmMapOptions?, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.ObjectMapperSerializer(keyPath, mapToObject: object, context: context, realm: realm, options: options), completionHandler: completionHandler)
    }
    
    /// MappableObject Array Serializer
    internal static func ObjectMapperArraySerializer<T: MappableObject>(_ keyPath: String?, context: RealmMapContext? = nil, realm: Realm?, options: RealmMapOptions?) -> DataResponseSerializer<[T]> {
        return DataResponseSerializer { request, response, data, error in
            if let error = checkResponseForError(request: request, response: response, data: data, error: error){
                return .failure(error)
            }
            
            let JSONObject = processResponse(request: request, response: response, data: data, keyPath: keyPath)
            let context = RealmMapContext.from(context: context, realm: realm, options: options)
            let mapper = Mapper<T>(context: context, shouldIncludeNilValues: false)
            let realm = try! mapper.realm ?? Realm()
            
            var parsedObject: [T]?
            try! realm.write {
                parsedObject = mapper.mapArray(JSONObject: JSONObject)
            }
            if let parsedObject = parsedObject {
                return .success(parsedObject)
            }
            
            let failureReason = "ObjectMapper failed to serialize response."
            let error = newError(.dataSerializationFailed, failureReason: failureReason)
            return .failure(error)
        }
    }
    
    /**
     Adds a handler to be called once the request has finished. T: MappableObject
     
     - parameter queue: The queue on which the completion handler is dispatched.
     - parameter keyPath: The key path where object mapping should be performed
     - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
     
     - returns: The request.
     */
    
    @discardableResult
    public func responseArray<T: MappableObject>(queue: DispatchQueue? = nil, keyPath: String? = nil, context: RealmMapContext? = nil, realm: Realm?, completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        return responseArray(queue: queue, keyPath: keyPath, context: context, realm: realm, options: nil, completionHandler: completionHandler)
    }
    
    @discardableResult
    public func responseArray<T: MappableObject>(queue: DispatchQueue? = nil, keyPath: String? = nil, context: RealmMapContext? = nil, realm: Realm? = nil, options: RealmMapOptions, completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        return responseArray(queue: queue, keyPath: keyPath, context: context, realm: realm, options: options as RealmMapOptions?, completionHandler: completionHandler)
    }
    
    @discardableResult
    internal func responseArray<T: MappableObject>(queue: DispatchQueue?, keyPath: String?, context: RealmMapContext?, realm: Realm?, options: RealmMapOptions?, completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        let responseSerializer: DataResponseSerializer<[T]> = DataRequest.ObjectMapperArraySerializer(keyPath, context: context, realm: realm, options: options)
        return response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}
