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
    let translation: SIMD3<Float>
    let childrenJoints: [RKJoint]
    
    init(name: String, translation: SIMD3<Float>) {
        self.name = name
        self.translation = translation
        childrenJoints = []
    }
    
}
