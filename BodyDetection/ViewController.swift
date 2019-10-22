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
        
        loadRobotModel()
        loadRobotBodyTracked()
        
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
                self.characterModel = character
                character.name = "Robot Model"
                
                print("charjoints", character.joints)
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
            
            characterAnchor.position = bodyPosition
          
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
   
            if let hulk = hulk, hulk.parent == nil, hulk.joints.count != 0 {
                hulk.position = hulkTrackedOffset
                characterAnchor.addChild(hulk)
                self.hulkJointTree = RKJointTree(from: hulk.joints)
            }
            
            if let character = character, character.parent == nil, character.joints.count != 0 {
                character.position = characterTrackedOffset
                characterAnchor.addChild(character)
                self.characterJointTree = RKJointTree(from: character.joints)
            }
            
             if let hulkModel = hulkModel, hulkModel.parent == nil, hulkModel.joints.count != 0 {
                 hulkModel.position = hulkModelOffset
                characterAnchor.addChild(hulkModel)
                self.hulkModelJointTree = RKJointTree(from: hulkModel.joints)
             }
             
             if let characterModel = characterModel, characterModel.parent == nil, characterModel.joints.count != 0 {
                 characterModel.position = characterModelOffset
                 characterAnchor.addChild(characterModel)
                 self.characterModelJointTree = RKJointTree(from: characterModel.joints)
             }
        
//®
            if hulkJointTree != nil {
                print("\nPrinting Hulk BodyTracked Tree")
                hulkJointTree!.updateJoints(from: hulk?.joints ?? [])
                hulkJointTree!.printJoints()
            }
            if characterJointTree != nil {
                print("\nPrinting Character BodyTracked Tree")
                characterJointTree!.updateJoints(from: character?.joints ?? [])
                characterJointTree!.printJoints()
            }
            if hulkModelJointTree != nil {
                print("\nPrinting Hulk Model Tree")
                hulkModelJointTree!.updateJoints(from: hulkModel?.joints ?? [])
                hulkModelJointTree!.printJoints()
            }
            if characterModelJointTree != nil {
                print("\nPrinting Character Model Tree")
                characterModelJointTree!.updateJoints(from: characterModel?.joints ?? [])
                characterModelJointTree!.printJoints()
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


extension ModelEntity {
    var joints: [(String, Transform)] {
        get {
            return Array(zip(self.jointNames, self.jointTransforms)) ?? []
        }
    }
}


extension BodyTrackedEntity {
    var joints: [(String, Transform)] {
        get {
            return Array(zip(self.jointNames, self.jointTransforms)) ?? []
        }
    }
}
