//
//  GlobeView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/12/26.
//

import SwiftUI
import SceneKit

struct GlobeView: View {
    let textureImage: String
    let horizontalRotation: Double
    let verticalRotation: Double
    var body: some View {
        SceneView(
            scene: createScene(),
            options: [.allowsCameraControl]
        )
        .background(Color.clear)
    }
    func createScene() -> SCNScene {
        let scene = SCNScene()
        
        scene.background.contents = UIColor(red: 0.094, green: 0.094, blue: 0.094, alpha: 1.0)
        
        // 1. The Globe (Handles Spin)
        let sphere = SCNSphere(radius: 5)
        let globeNode = SCNNode(geometry: sphere)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: textureImage)
        sphere.materials = [material]
        
        // 2. The Tilt Node (Handles Pole position)
        let tiltNode = SCNNode()
        tiltNode.addChildNode(globeNode)

        // 3. Set Angles & Animation
        let tiltAngle = Float(verticalRotation * .pi / 180)
        let targetSpin = Float(horizontalRotation * .pi / 180)
        let startSpin = Float((horizontalRotation - 10) * .pi / 180)

        tiltNode.eulerAngles.x = tiltAngle
        globeNode.eulerAngles.y = startSpin

        let spinAction = SCNAction.rotateTo(
            x: 0,
            y: CGFloat(targetSpin),
            z: 0,
            duration: 1.0,
            usesShortestUnitArc: true
        )
        spinAction.timingMode = .easeOut
        globeNode.runAction(spinAction)
        
        // 4. THE CRITICAL STEP: Add the hierarchy to the root
        scene.rootNode.addChildNode(tiltNode) 
        
        // takes up full container
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 5 // increase to 5.5 or 6 for more padding
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 20)
        scene.rootNode.addChildNode(cameraNode)
        
        // light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 1000
        scene.rootNode.addChildNode(ambientLight)
        
        //shadow
        let omniLight = SCNNode()
        omniLight.light = SCNLight()
        omniLight.light?.type = .omni
        omniLight.position = SCNVector3(x: 20, y: 20, z: 20)
        scene.rootNode.addChildNode(omniLight)
        
        return scene
    }
}
