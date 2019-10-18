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
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [-1, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    
    var hulk: ModelEntity?
    let hulkOffset: SIMD3<Float> = [3, 0, 0] // Offset the character by one meter to the left
    
    // A tracked raycast which is used to place the character accurately
    // in the scene wherever the user taps.
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    
    let charScale: SIMD3<Float> = [0.05, 0.05, 0.05]
    
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
        
        loadBodyTracked()
        loadHulk()
    }
    
    func loadBodyTracked() {
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/hulk_agora_vai").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                //Tamanho do boneco em relacão a humanos
                character.scale = self.charScale
                //                character.jointNames.map({m in return print(m)})
                self.character = character
                character.name = "Controllable"
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    func loadHulk() {
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadModelAsync(named: "character/hulk_agora_vai").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (hulk: Entity) in
            if let hulk = hulk as? ModelEntity {
                //Tamanho do boneco em relacão a humanos
                hulk.scale = self.charScale
                //                character.jointNames.map({m in return print(m)}
                hulk.name = "Hulk"
                self.hulk = hulk
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
            
            characterAnchor.position = bodyPosition + characterOffset
          
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
   
            if let hulk = hulk, hulk.parent == nil {
                hulk.position = hulkOffset
                characterAnchor.addChild(hulk)
            }
            
            if let character = character, character.parent == nil {
                print("Corpo ancora detectado ")
                characterAnchor.addChild(character)
            }
            
            
            if hulk != nil && character != nil {
//                print("\n\n\n------------------------ Printing joints -------------------------\n")
//                printJoints(model: hulk!)
//                printJoints(model: character!)
            }
        }
    }
    
    func printJoints(model: ModelEntity) {
        print("\nPrinting", model.name)
        model.joints.map( { print($0) } )
    }
    
    func printJoints(model: BodyTrackedEntity) {
        print("\nPrinting", model.name)
        model.joints.map( { print($0) } )
    }
}


extension ModelEntity {
    var joints: [(String, Transform)] {
        get {
            return Array(zip(self.jointNames, self.jointTransforms))
        }
    }
}


extension BodyTrackedEntity {
    var joints: [(String, Transform)] {
        get {
            return Array(zip(self.jointNames, self.jointTransforms))
        }
    }
}
