//
//  RKJointTree.swift
//  BodyDetection
//
//  Created by Enzo Maruffa Moreira on 22/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import RealityKit

class RKJointTree {
    
    var rootJoint: RKJoint? 
    
    // Every joint must have a unique name
    init(from list: [(String, Transform)]) {
        
        // Separates our joint name in a list with it`s original hierarchy
        var hierachicalJoints = list.map( { ($0.0.components(separatedBy: "/"), $0.1)} )
        hierachicalJoints.sort(by: { $0.0.count < $1.0.count } )
        
        // Removes the root joint from  the list
        let rootJoint = hierachicalJoints.removeFirst()
        
        // Checks that the root joint exists
        guard let rootName = rootJoint.0.first else {
            return
        }
        
        // Creates the root joint in the tree
        self.rootJoint = RKJoint(name: rootName, translation: rootJoint.1.translation)
        
        for joint in hierachicalJoints {
            
            // If the joint has an ancestor, we get it's name
            let ancestorName = joint.0.count >= 2 ? joint.0[joint.0.count - 2] : rootName
            
            print(ancestorName)
            
            if let ancestorJoint = self.rootJoint?.findSelfOrDescendantBy(name: ancestorName) {

                let jointName = joint.0.last
                
                // If somehow a joint is repeated, we just update it's position
                if let existingJoint = ancestorJoint.childrenJoints.first(where: { $0.name == jointName} )  {
                    existingJoint.relativeTranslation = joint.1.translation
                    print("Repeated joint found with hierarchy \(joint.0)")
                } else {
                    ancestorJoint.addChild(name: jointName ?? "(nil)", translation: joint.1.translation)
                }
            } else {
                print("Error creating RKJointTree. Ancestor for joint with hierarchy \(joint.0) not found")
            }
        }
        
        print("RKJointTree created successfully!")
        
    }
    
    //TODO: Optimize since we already know where each joint is in the tree
    func updateJoints(from list: [(String, Transform)]) {
        
        // Separates our joint name in a list with it`s original hierarchy
        var hierachicalJoints = list.map( { ($0.0.components(separatedBy: "/"), $0.1)} )
        hierachicalJoints.sort(by: { $0.0.count < $1.0.count } )
        
        // Updates every joint
        for joint in hierachicalJoints {
            if let jointName = joint.0.last,
                let existingJoint = rootJoint?.findSelfOrDescendantBy(name: jointName) {
                existingJoint.relativeTranslation = joint.1.translation
            }
        }
    }
    
    func printJoints() {
        var jointQueue: [RKJoint] = []
        
        if let root = rootJoint {
            jointQueue.append(root)
        }
        
        while jointQueue.count > 0 {
            let joint = jointQueue.removeFirst()
            print(joint.description)
            jointQueue.append(contentsOf: joint.childrenJoints)
        }
        
    }
}

extension RKJoint: CustomStringConvertible {
    var description: String {
        return "\(name) | absolute: \(absoluteTranslation) | relative: \(relativeTranslation)"
    }
}
