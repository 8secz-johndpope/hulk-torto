/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!
    @IBOutlet weak var messageLabel: MessageLabel!
    
    
    let hulkScale: SIMD3<Float> = [0.05, 0.05, 0.05]
    let charScale: SIMD3<Float> = [1, 1, 1]
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    var characterJointTree: RKJointTree?
    
    var characterModel: ModelEntity?
    var characterModelJointTree: RKJointTree?
    
    let characterModelOffset: SIMD3<Float> = [-1, 0, 0]
    let characterTrackedOffset: SIMD3<Float> = [1, 0, 0]
    
    // Hulks
    let hulkModelName = "hulk_agora_vai"
    
    var hulk: BodyTrackedEntity?
    var hulkJointTree: RKJointTree?
    
    var hulkModel: ModelEntity?
    var hulkModelJointTree: RKJointTree?
    
    let hulkModelOffset: SIMD3<Float> = [-1, 0, 0]
    let hulkTrackedOffset: SIMD3<Float> = [1, 0, 0] // Offset the character by one meter to the left
    
    // A tracked raycast which is used to place the character accurately
    // in the scene wherever the user taps.
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    
    let characterAnchor = AnchorEntity()
    
    let jointsToPrint = ["root", "root/hips_joint", "root/hips_joint/right_upLeg_joint", "root/hips_joint/left_upLeg_joint", "root/hips_joint/spine_1_joint", "root/hips_joint/spine_1_joint/spine_2_joint/spine_3_joint/spine_4_joint/spine_5_joint/spine_6_joint/spine_7_joint/left_shoulder_1_joint", "root/hips_joint/spine_1_joint/spine_2_joint/spine_3_joint/spine_4_joint/spine_5_joint/spine_6_joint/spine_7_joint/right_shoulder_1_joint"]
    
    var hasCreatedUpdate = false
    
    var globalBodyPosition: SIMD3<Float>?
    var globalBodyAnchor: ARBodyAnchor?
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        
        arView.scene.addAnchor(characterAnchor)
        
        loadHulkModel()
        //loadHulkBodyTracked()
    }
    
    func loadRobotBodyTracked() {
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                //Tamanho do boneco em relacão a humanos
                character.scale = self.charScale
                self.character = character
                character.name = "Robot Tracked"
                
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    
    func loadRobotModel() {
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadModelAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? ModelEntity {
                //Tamanho do boneco em relacão a humanos
                character.scale = self.charScale
                print("Created character model...")
                self.characterModel = character
                character.name = "Robot Model"
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as ModelEntity")
            }
        })
    }
    
    func loadHulkBodyTracked() {
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/" + hulkModelName).sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (hulk: Entity) in
            if let hulk = hulk as? BodyTrackedEntity {
                
                //Tamanho do boneco em relacão a humanos
                hulk.scale = self.hulkScale
                hulk.name = "Hulk Tracked"
            
                self.hulk = hulk
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }

    
    func loadHulkModel() {
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadModelAsync(named: "character/" + hulkModelName).sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (hulk: Entity) in
            if let hulk = hulk as? ModelEntity {
                //Tamanho do boneco em relacão a humanos
                hulk.scale = self.hulkScale
                //                character.jointNames.map({m in return print(m)}
                hulk.name = "Hulk Model"
                self.hulkModel = hulk
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as ModelEntity")
            }
        })
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
            // Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            self.globalBodyPosition = bodyPosition
            
            self.globalBodyAnchor = bodyAnchor
            //TodoL pegar joint names de um jeito bonito let jointNames = ARSkeleton
        }
        
        
        if !hasCreatedUpdate {
            let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            timer.fire()
            
            hasCreatedUpdate = true
        }
    }
    
    @objc func update() {
        
        if let bodyPosition = globalBodyPosition, let bodyAnchor = globalBodyAnchor {
            
            characterAnchor.position = bodyPosition
            
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
            
            if let hulk = hulk, hulk.parent == nil, hulk.immutableJoints.count != 0 {
                hulk.position = hulkTrackedOffset
                characterAnchor.addChild(hulk)
                
                let jointModelTransforms = bodyAnchor.skeleton.jointModelTransforms.map( { Transform(matrix: $0) })
                let jointNames = hulk.jointNames
                
                let joints = Array(zip(jointNames, jointModelTransforms))
                
                self.hulkJointTree = RKJointTree(from: joints, usingAbsoluteTranslation: true)
                print("\(hulk.name) animations:", hulk.availableAnimations)
            }
            
            if let character = character, character.parent == nil, character.immutableJoints.count != 0 {
                character.position = characterTrackedOffset
                characterAnchor.addChild(character)
                
                let jointModelTransforms = bodyAnchor.skeleton.jointModelTransforms.map( { Transform(matrix: $0) })
                let jointNames = character.jointNames
                
                let joints = Array(zip(jointNames, jointModelTransforms))
                
                self.characterJointTree = RKJointTree(from: joints, usingAbsoluteTranslation: true)
            }
            
            if let hulkModel = hulkModel {
                
                if hulkModel.parent == nil {
                    hulkModel.position = hulkModelOffset
                    characterAnchor.addChild(hulkModel)
                    
                    let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (_) in
                        hulkModel.playAnimation(hulkModel.availableAnimations[0])
                    }
                    
                    timer.fire()
                    
                    print("\(hulkModel.name) animations:", hulkModel.availableAnimations)
                }
                
                print("\n\n\nHulk joints: \(hulkModel.immutableJoints)")
                
            }
            
            if let characterModel = characterModel, characterModel.parent == nil, characterModel.immutableJoints.count != 0 {
                characterModel.position = characterModelOffset
                characterAnchor.addChild(characterModel)
                self.characterModelJointTree = RKJointTree(from: characterModel.immutableJoints, usingAbsoluteTranslation: false)
            }
            
            if hulkJointTree != nil {
                print("\nPrinting Hulk BodyTracked Tree")
                
                let jointModelTransforms = bodyAnchor.skeleton.jointModelTransforms.map( { Transform(matrix: $0) })
                let jointNames = hulk!.jointNames
                
                let joints = Array(zip(jointNames, jointModelTransforms))
                
                hulkJointTree!.updateJoints(from: joints, usingAbsoluteTranslation: true)
                hulkJointTree!.printJointsBFS()
            }
            
            if characterJointTree != nil {
                print("\nPrinting Character BodyTracked Tree. Total joints: \(String(describing: characterJointTree!.treeSize))")
                
                let jointModelTransforms = bodyAnchor.skeleton.jointModelTransforms.map( { Transform(matrix: $0) })
                let jointNames = character!.jointNames
                
                let joints = Array(zip(jointNames, jointModelTransforms))
                
                characterJointTree!.updateJoints(from: joints, usingAbsoluteTranslation: true)
                characterJointTree!.printJointsBFS()
            }
            
            if hulkModelJointTree != nil {
                print("\nPrinting Hulk Model Tree")
                hulkModelJointTree!.printJointsBFS()
            }
            
            if characterModelJointTree != nil {
                print("\nPrinting Character Model Tree")
                characterModelJointTree!.printJointsBFS()
            }
        }
         
    }
    
//    func printJoints(jointsToPrint: [String], model: ModelEntity, otherModel: BodyTrackedEntity) {
//
//        let modelTotalJoints = model.joints.count
//        let bodyTotalJoints = otherModel.joints.count
//
//        print("    Total model joints", modelTotalJoints)
//        print("    Total body joints", bodyTotalJoints)
//
//        for i in 0..<min(modelTotalJoints, bodyTotalJoints) {
//            let jointName = model.joints[i].0
//            if jointsToPrint.contains(jointName) {
//                print(model.joints[i], "\n", otherModel.joints[i], "\n")
//            }
//        }
//    }
//
//    func printJoints(model: ModelEntity, otherModel: ModelEntity) {
//
//        let modelTotalJoints = model.joints.count
//        let bodyTotalJoints = otherModel.joints.count
//
//        print("    Total model joints", modelTotalJoints)
//        print("    Total body joints", bodyTotalJoints)
//
//        for i in 0..<min(modelTotalJoints, bodyTotalJoints) {
//            print(model.joints[i], "\n", otherModel.joints[i], "\n")
//        }
//    }
//
//    func printJoints(model: ModelEntity) {
//        print("\nPrinting", model.name)
//        model.joints.map( { print($0) } )
//    }
//
//    func printJoints(model: BodyTrackedEntity) {
//        print("\nPrinting", model.name)
//        model.joints.map( { print($0) } )
//    }
}


extension HasModel {
    var immutableJoints: [(String, Transform)] {
        get {
            print("From \(self.name) jointNames: \(self.jointNames.count), jointTransforms: \(self.jointTransforms.count)")
            return Array(zip(self.jointNames, self.jointTransforms))
        }
    }
}

