//
//  ViewController.swift
//  escape_room
//
//  Created by 周舒意 on 2020/1/18.
//  Copyright © 2020 周舒意. All rights reserved.
//

import UIKit
import RealityKit
import ARKit
import SceneKit

class ViewController: UIViewController , ARSessionDelegate{
    @IBOutlet weak var OK: UIButton! /// The button to confirm the plane
    @IBOutlet weak var arView: ARView!
    @IBOutlet var longTap: UILongPressGestureRecognizer!

    var gameAnchor : ARPlaneAnchor?
    var gameAnchorEntity = AnchorEntity(world: [0,0,0])
    var planeMapping: [ARPlaneAnchor:AnchorEntity] = [:]
    
    var origin: SIMD3<Float> = SIMD3(0, 0, 0)
    var Width: Float = 0.5
    var Length: Float = 0.5
    
    var telephoneObj = Telephone()
    var foodObj = Food()
    var keyBoxObj = KeyBox()

    var positions : [SIMD3<Float>] = []
    let anchorWorld = AnchorEntity(world: [0, 0, 0])
    
    var tapEntity: Entity?
    var tapDelta: simd_float4x4?
    
    
    func transitionToState(toState state: State) {
        func trainsitionToLoad(){
            
            /// the postions to place the scenes
            positions.append(gameAnchor!.center - SIMD3(Length * 0.2, 0, Width * 0.2))
            positions.append(gameAnchor!.center)
            positions.append(gameAnchor!.center + SIMD3(Length * 0.2, 0, Width * 0.2))
            
            arView.scene.addAnchor(telephoneObj.getRealityKitObject(where: positions[0], relativeTo: anchorWorld))
            arView.scene.addAnchor(foodObj.getRealityKitObject(where: positions[1], relativeTo: anchorWorld))
            arView.scene.addAnchor(keyBoxObj.getRealityKitObject(where: positions[2], relativeTo: anchorWorld))
            
            /// after loading, start the games
            transitionToState(toState: .game)
        }
        func transitionToGame() {
            telephoneObj.getInput()
            /// once the food scene is correct, let the state go to end.
            foodObj.getInput{(state) in
                self.transitionToState(toState: state)
            }
        }
        func transitionToEnd(){
            keyBoxObj.getInput()
        }
        switch state {
        case .load:
            trainsitionToLoad()
        case .game:
            transitionToGame()
        case .end:
            transitionToEnd()
        default:
            ()
        }
    }
    
    @IBAction func ok(_ sender: Any) {
        /// hidden the states
        OK.isHidden = true
        
        /// save the data
        Length = gameAnchorEntity.scale.x
        Width = gameAnchorEntity.scale.z
        origin = gameAnchorEntity.position
        
        /// remove the place
        arView.scene.removeAnchor(gameAnchorEntity)
        
        /// load the game scenes
        transitionToState(toState: .load)
    }
    
    override func viewDidLoad() {
        arView.addGestureRecognizer(longTap)
        
        arView.session.delegate = self
        // Set the tracking configuration to horizontal surfaces (tables, etc.)
        let arConfiguration = ARWorldTrackingConfiguration()
        arConfiguration.planeDetection = .horizontal
        arView.session.run(arConfiguration)
        
    }
    
    func updateAnchor(anchor: ARPlaneAnchor) {
        // Creating Anchors
        
        if (planeMapping[anchor] == nil) {
            // restriction to only have one plane
            if (planeMapping.count >= 1) {return}
            let anchorEntity = AnchorEntity(anchor: anchor)
            planeMapping[anchor] = anchorEntity
            //create Plane arround the anchorEntity and attach it to the scene
            anchorEntity.setPlane()
            arView.scene.addAnchor(anchorEntity)
            gameAnchor = anchor
            gameAnchorEntity = anchorEntity
        }
        
        // Updating Anchors
        
        let anchorEntity = planeMapping[anchor]!
        // To set the orientation of the plane to the orientation of the updated anchor
        anchorEntity.move(to: anchor.transform, relativeTo: anchorWorld)
        // Set the position to the center of the updated anchor
        anchorEntity.position = anchor.center
        // Scale the plane shape according to the extend of the plane detected
        anchorEntity.setScale(SIMD3(Float(anchor.extent.x), 1,Float(anchor.extent.z)), relativeTo: nil)
    }
    // Executed, when Anchor is updated
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Safe all updated anchors that are PlaneAnchors and not nil
        let planeAnchors = anchors
            .map({anchor in anchor as? ARPlaneAnchor})
            .filter({anchor in anchor != nil})
            .map({anchor in anchor!})
            
        for planeAnchor in planeAnchors {
            updateAnchor(anchor: planeAnchor)
        }
}

    /// The following two functions are to make the objects move when they are being long tapped. They will move according to the movement of camera.
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let tapEntity = self.tapEntity, let tapDelta = self.tapDelta else {
            return
        }
        /// Add the current camera transform information.
        tapEntity.setTransformMatrix(arView.cameraTransform.matrix * tapDelta, relativeTo: nil)
    }
    
    @IBAction func moveEntity(_ gestureRecognizer: UILongPressGestureRecognizer) {
        /// if long tap begins, set the tapEntity and tapDelta.
        if gestureRecognizer.state == .began {
            let tapPoint = gestureRecognizer.location(in: view)
            let _foundEntity = arView.entity(at: tapPoint) /// find the entity that tapped
            
            if let foundEntity = _foundEntity {
                tapEntity = foundEntity
                /// exclude the current cameraTransform from the transform of entity
                tapDelta = arView.cameraTransform.matrix.inverse * foundEntity.transformMatrix(relativeTo: nil)
            }
        }
        /// if long tap begins, set the tapEntity and tapDelta back to nil.
        else if gestureRecognizer.state == .ended {
            tapEntity = nil
            tapDelta = nil
        }
    }
}

