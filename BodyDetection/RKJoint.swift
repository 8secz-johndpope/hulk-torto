//
//  RKJoint.swift
//  BodyDetection
//
//  Created by Enzo Maruffa Moreira on 22/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import RealityKit

class RKJoint {
    
    let name: String
    var relativeTranslation: SIMD3<Float>
//    {
//        didSet {
//            self.absoluteTranslation = absoluteTranslation - oldValue + relativeTranslation
//        }
//    }
    
    // TODO: Optimize to use stored properties
    var absoluteTranslation: SIMD3<Float> {
        get {
            var defaultTranslation = SIMD3<Float>(0, 0, 0)
            if let parent = parent {
                defaultTranslation = parent.absoluteTranslation
            }
            return defaultTranslation + relativeTranslation
        }
    }
    var childrenJoints: [RKJoint]
    var parent: RKJoint?
//    {
//        didSet {
//            if let parent = self.parent {
//                self.absoluteTranslation = parent.absoluteTranslation + self.relativeTranslation
//            }
//        }
//    }
    
    init(name: String, translation: SIMD3<Float>) {
        self.name = name
        self.relativeTranslation = translation
        childrenJoints = []
    }
    
    convenience init(joint: (String, Transform)) {
        self.init(name: joint.0, translation: joint.1.translation)
    }
    
    func addChild(name: String, translation: SIMD3<Float>) {
        let newJoint = RKJoint(name: name, translation: translation)
        childrenJoints.append(newJoint)
        newJoint.parent = self
    }
    
    func addChild(joint: (String, Transform)) {
        let newJoint = RKJoint(joint: joint)
        childrenJoints.append(newJoint)
        newJoint.parent = self
    }
    
    func findChildrenBy(name: String) -> RKJoint? {
        return self.childrenJoints.filter( {$0.name == name} ).first
    }
    
    func findDescendantBy(name: String) -> RKJoint? {
        // If it's a direct children, instantly returns it
        if let joint = self.findChildrenBy(name: name) {
            return joint
        }
        
        // Searches for a descentand in our children, find the first non nil and return it
        let returnJoint = childrenJoints.map( { $0.findDescendantBy(name: name)} ).filter( {$0 != nil} ).first
        return returnJoint ?? nil //TODO: Entender esse RKJoint??
        
    }
    
    func findSelfOrDescendantBy(name: String) -> RKJoint? {
        if name == self.name {
            return self
        }
        
        return findDescendantBy(name: name)
        
    }
}
