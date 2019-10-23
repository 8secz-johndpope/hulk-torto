/**
//  RKJoint.swift
//  BodyDetection
//
//  Created by Enzo Maruffa Moreira on 22/10/19.
//  Copyright © 2019 Apple. All rights reserved.
*/

import RealityKit

/// A class representing a single joint
class RKJoint {
    
    /// A String with the joint's name
    let name: String
    
    /// A SIMD3<Float> with the joint's position relative to it's parent
    var relativeTranslation: SIMD3<Float>
//    {
//        didSet {
//            self.absoluteTranslation = absoluteTranslation - oldValue + relativeTranslation
//        }
//    }
    
    /**
        A computed  SIMD3<Float> property recursevely calculated with the joint's absolute position (relative to the scene anchor). 
        - TODO: Optimize to use stored properties instead of recursively calculating it each time
     */
    var absoluteTranslation: SIMD3<Float> {
        get {
            var defaultTranslation = SIMD3<Float>(0, 0, 0)
            if let parent = parent {
                defaultTranslation = parent.absoluteTranslation
            }
            return defaultTranslation + relativeTranslation
        }
    }
    
    /// A list of the joint's childreni
    var childrenJoints: [RKJoint]
    
    /// An optional parent  joint
    var parent: RKJoint?
//    {
//        didSet {
//            if let parent = self.parent {
//                self.absoluteTranslation = parent.absoluteTranslation + self.relativeTranslation
//            }
//        }
//    }
    
    /// The amount of descendants this joint has, recursevely calculated by each children.
    var descendantCount: Int {
        // Start with a count of 0 then sum each child descendantCount. Then, add the  total children joints this joint has to the sum.
        return childrenJoints.reduce(0, { $0 + $1.descendantCount }) + childrenJoints.count
    }
    
    /// Initializes a joint using it's name and translation
    /// - Parameter name: The  joint's name
    /// - Parameter translation: The joint's translation
    /// - TODO: Update to use every joint property
    init(name: String, translation: SIMD3<Float>) {
        self.name = name
        self.relativeTranslation = translation
        childrenJoints = []
    }
    
    
    /// Initializes a joint using it's name and transform as a tuple
    /// - Parameter joint: A tuple with the joint's name and translation
    /// - TODO: Update to use every joint property
    convenience init(joint: (String, Transform)) {
        self.init(name: joint.0, translation: joint.1.translation)
    }
    
    /// Creates and adds a joint as a child based on it's name and translation
    /// - Parameter name: The name of the joint
    /// - Parameter translation: The joint's relative translation
    func addChild(name: String, translation: SIMD3<Float>) {
        let newJoint = RKJoint(name: name, translation: translation)
        childrenJoints.append(newJoint)
        newJoint.parent = self
    }
    
    /// Creates and adds a joint as a child based on a tuple of a String and a Transform
    /// - Parameter joint: A tuple with the joint's name and translation
    /// - TODO: Store every Transform property instead of just the translation
    func addChild(joint: (String, Transform)) {
        let newJoint = RKJoint(joint: joint)
        childrenJoints.append(newJoint)
        newJoint.parent = self
    }
    
    /// Creates and adds a joint as a child based on it's name and translation
    /// - Parameter joint: An RKJoint with the to be children joint
    func addChild(joint: RKJoint) {
        // Checks if the joint to be added already has a parent
        if let oldParent = joint.parent {
            oldParent.childrenJoints.removeAll(where: { $0.name == joint.name} )
        }
        
        childrenJoints.append(joint)
        joint.parent = self
    }

    /// Searchs for a joint on this joint's children by name
    /// - Parameter name: The searched joint's name
    /// - Returns: The searched joint if it was found. nil if no proper joint was found.
    func findChildrenBy(name: String) -> RKJoint? {
        return self.childrenJoints.filter( {$0.name == name} ).first
    }
    
    /// Searchs for a joint on this joint's descendants by name
    /// - Parameter name: The searched joint's name
    /// - Returns: The searched joint if it was found. nil if no proper joint was found.
    func findDescendantBy(name: String) -> RKJoint? {
        // If it's a direct children, instantly returns it
        if let joint = self.findChildrenBy(name: name) {
            return joint
        }
        
        // Searches for a descentand in our children, find the first non nil and return it
        let returnJoint = childrenJoints.map( { $0.findDescendantBy(name: name)} ).filter( {$0 != nil} ).first
        return returnJoint ?? nil //TODO: Entender esse RKJoint??
        
    }
    
    /// Searchs for a joint on this joint's descendants by name, but also checks if this joint is the searched one
    /// - Parameter name: The searched joint's name
    /// - Returns: The searched joint if it was found. nil if no proper joint was found.
    func findSelfOrDescendantBy(name: String) -> RKJoint? {
        if name == self.name {
            return self
        }
        
        return findDescendantBy(name: name)
    }
    
    /// Checks the equivalence between two joints
    /// - Returns: a Bool with the comparison result
    func isEquivalent(to other: RKJoint) -> Bool {
        
        // If children count is different, instantly return as false
        if childrenJoints.count != other.childrenJoints.count {
            return false
        }
        
        for child in childrenJoints {
            // For each child, we check if the other joint contains a child with the same name. If so, we go down it's tree checking the same thing
            if let otherJoint = other.childrenJoints.filter( {$0.name == name} ).first {
                if !child.isEquivalent(to: otherJoint) {
                    return false
                }
            } else {
                return false
            }
        }
        
        return true
    }
    
    /// Copies a joint
    /// - Parameter withChildren: A boolean describing if it should copy children
    /// - Returns: The joint's copy
    func copyJoint(withChildren: Bool) -> RKJoint {
        // Copies the original joint
        let newJoint = RKJoint(name: self.name, translation: self.relativeTranslation)
        
        if !withChildren {
            return newJoint
        }
        
        // Recursevely copies each children
        for child in childrenJoints {
            newJoint.addChild(joint: child.copyJoint(withChildren: true))
        }
        
        return newJoint
    }
}


extension RKJoint: CustomStringConvertible {
    var description: String {
        return "\(name) | absolute: \(absoluteTranslation)"
    }
}
