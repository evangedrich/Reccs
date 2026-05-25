//
//  GlobeView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/12/26.
//

import SwiftUI
import SceneKit

struct GlobeView: UIViewRepresentable {
    @Environment(MovieStore.self) private var store
    let defaultTexture: String = "blue-marble-3"
    let textureImage: String
    let horizontalRotation: Double
    let verticalRotation: Double
    let subregionID: String
    let focusID: String?

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        // Create the scene only once
        scnView.scene = createScene()
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let globeNode = scnView.scene?.rootNode.childNode(withName: "GlobeNode", recursively: true) else { return }
        
        // remove the old pulse from anywhere it might be
        globeNode.enumerateChildNodes { (node, _) in
            if node.name == "SonarPulse" {
                node.removeFromParentNode()
            }
        }
        let currentFocus = focusID ?? "NONE"
        globeNode.enumerateChildNodes { (node, _) in
            guard let filmID = node.name, filmID != "SonarPulse" else { return }
            let isFocused = filmID == currentFocus
            node.geometry?.firstMaterial?.diffuse.contents = isFocused ? UIColor(Color(hex: "#d62b2b")) : UIColor.white
            if isFocused {
                let pulse = createSonarPulse(color: UIColor(Color(hex: "#d62b2b")))
                node.addChildNode(pulse)
            }
        }
    }

    func createScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor(red: 0.094, green: 0.094, blue: 0.094, alpha: 1.0)
        
        let bottomSphere = SCNSphere(radius: 4.99) // Slightly smaller so dots don't sink
        let bottomNode = SCNNode(geometry: bottomSphere)
        bottomSphere.firstMaterial?.diffuse.contents = UIImage(named: defaultTexture)
        
        let sphere = SCNSphere(radius: 5)
        let globeNode = SCNNode(geometry: sphere)
        globeNode.name = "GlobeNode" // Named so updateUIView can find it
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: textureImage)
        sphere.materials = [material]
        
        globeNode.opacity = 0
        
        // Add dots (initially all white)
        for film in store.films {
            let sphere = SCNSphere(radius: 0.08)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white
            material.transparency = film.id.hasPrefix(subregionID) ? 1.0 : 0.12
            sphere.materials = [material]
            let dotNode = SCNNode(geometry: sphere)
            dotNode.name = film.id
            dotNode.position = coordToVector(lat: film.location.y, lon: film.location.x)
            globeNode.addChildNode(dotNode)
        }
        
        let tiltNode = SCNNode()
        tiltNode.addChildNode(bottomNode)
        tiltNode.addChildNode(globeNode)

        let tiltAngle = Float(verticalRotation * .pi / 180)
        let targetSpin = Float(horizontalRotation * .pi / 180)
        let startSpin = Float((horizontalRotation - 10) * .pi / 180)

        tiltNode.eulerAngles.x = tiltAngle
        
        // Always play the animation on creation
        bottomNode.eulerAngles.y = startSpin
        globeNode.eulerAngles.y = startSpin
        let spinAction = SCNAction.rotateTo(x: 0, y: CGFloat(targetSpin), z: 0, duration: 1.0, usesShortestUnitArc: true)
        spinAction.timingMode = .easeOut
        
        let fadeIn = SCNAction.fadeIn(duration: 1.0)
        
        globeNode.runAction(spinAction)
        
        bottomNode.runAction(spinAction)
        globeNode.runAction(spinAction)
        globeNode.runAction(fadeIn)
        
        scene.rootNode.addChildNode(tiltNode)
        
        // --- Standard Camera & Lights ---
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 5.1
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 20)
        scene.rootNode.addChildNode(cameraNode)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 1000
        scene.rootNode.addChildNode(ambientLight)
        
        let omniLight = SCNNode()
        omniLight.light = SCNLight()
        omniLight.light?.type = .omni
        omniLight.position = SCNVector3(x: 20, y: 20, z: 20)
        scene.rootNode.addChildNode(omniLight)
        
        return scene
    }
}

func coordToVector(lat: Double, lon: Double, radius: Float = 5) -> SCNVector3 {
    let phi = lat * .pi / 180
    let theta = lon * .pi / 180
    
    let x = radius * Float(cos(phi) * sin(theta))
    let y = radius * Float(sin(phi))
    let z = radius * Float(cos(phi) * cos(theta))
    
    return SCNVector3(x, y, z)
}

//func getColor(for id: String) -> UIColor {
//    let subregion = String(id.prefix(4)).uppercased()
//    let swiftUIColor: Color
//    
//    switch true {
//    case ["AMNO", "AFSO", "ASSO"].contains(subregion):
//        swiftUIColor = Color(hex: "#7146e2") //purple
//    case ["ASHI", "OCML", "OCMD", "AFNO", "AMIN", "AMCR", "AMSO"].contains(subregion):
//        swiftUIColor = Color(hex: "#e85451") //red
//    case ["WEEU", "AMCE", "AFEA", "OCAU", "ASEA"].contains(subregion):
//        swiftUIColor = Color(hex: "#ff9d54") //orange
//    case ["AMNW", "ASNO", "AMNE", "ASWE", "OCMC"].contains(subregion):
//        swiftUIColor = Color(hex: "#6a95f0") //blue
//    case ["ASSE", "ASIN", "EUEA", "AFWE", "AMWE", "AMSW"].contains(subregion):
//        swiftUIColor = Color(hex: "#ffd070") //yellow
//    case ["ASCE", "AMEA", "OCPL", "AFCE"].contains(subregion):
//        swiftUIColor = Color(hex: "#50d895") //green
//    default: swiftUIColor = .white
//    }
//    
//    // Convert SwiftUI Color to UIKit's UIColor
//    return UIColor(swiftUIColor)
//}

private func createSonarPulse(color: UIColor) -> SCNNode {
    // Create a sphere slightly larger than your 0.08 dots
    let pulseSphere = SCNSphere(radius: 0.09)
    let material = SCNMaterial()
    material.diffuse.contents = color
    material.transparency = 0.5
    // Makes it look like it's "glowing"
    material.lightingModel = .constant
    pulseSphere.materials = [material]
    
    let pulseNode = SCNNode(geometry: pulseSphere)
    pulseNode.name = "SonarPulse"
    
    // Animation: Scale up to 3x size while fading to 0 opacity
    let scaleUp = SCNAction.scale(to: 3.0, duration: 1.5)
    let fadeOut = SCNAction.fadeOut(duration: 1.5)
    let group = SCNAction.group([scaleUp, fadeOut])
    
    // Reset: Instantly shrink and become visible again
    let reset = SCNAction.group([
        SCNAction.scale(to: 1.0, duration: 0),
        SCNAction.fadeIn(duration: 0)
    ])
    
    // Loop forever
    let sequence = SCNAction.sequence([group, reset])
    pulseNode.runAction(SCNAction.repeatForever(sequence))
    
    return pulseNode
}
