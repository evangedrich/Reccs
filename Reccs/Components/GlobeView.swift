//
//  GlobeView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/12/26.
//

import SwiftUI
import SceneKit

struct GlobeView: UIViewRepresentable {
    @State private var store = MovieStore()
    let textureImage: String
    let horizontalRotation: Double
    let verticalRotation: Double
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
        // 1. Handle Dot Color Updates
        // This runs whenever focusID changes, but DOES NOT reset the scene
        guard let globeNode = scnView.scene?.rootNode.childNode(withName: "GlobeNode", recursively: true) else { return }
        
        globeNode.enumerateChildNodes { (node, _) in
            if let dotName = node.name {
                node.geometry?.firstMaterial?.diffuse.contents = (dotName == focusID) ? UIColor.red : getColor(for: dotName)
            }
        }
    }

    func createScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor(red: 0.094, green: 0.094, blue: 0.094, alpha: 1.0)
        
        let sphere = SCNSphere(radius: 5)
        let globeNode = SCNNode(geometry: sphere)
        globeNode.name = "GlobeNode" // Named so updateUIView can find it
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: textureImage)
        sphere.materials = [material]
        
        // Add dots (initially all white)
        for film in store.films {
            let disk = SCNCylinder(radius: 0.07, height: 0.01)
            disk.firstMaterial?.diffuse.contents = getColor(for: film.id)
            let dotNode = SCNNode(geometry: disk)
            dotNode.name = film.id
            let pos = coordToVector(lat: film.location.y, lon: film.location.x)
            dotNode.position = pos
            dotNode.look(at: SCNVector3(pos.x * 2, pos.y * 2, pos.z * 2))
            dotNode.eulerAngles.x += .pi / 2
            
            globeNode.addChildNode(dotNode)
        }
        
        let tiltNode = SCNNode()
        tiltNode.addChildNode(globeNode)

        let tiltAngle = Float(verticalRotation * .pi / 180)
        let targetSpin = Float(horizontalRotation * .pi / 180)
        let startSpin = Float((horizontalRotation - 10) * .pi / 180)

        tiltNode.eulerAngles.x = tiltAngle
        
        // Always play the animation on creation
        globeNode.eulerAngles.y = startSpin
        let spinAction = SCNAction.rotateTo(x: 0, y: CGFloat(targetSpin), z: 0, duration: 1.0, usesShortestUnitArc: true)
        spinAction.timingMode = .easeOut
        globeNode.runAction(spinAction)
        
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

func getColor(for id: String) -> UIColor {
    let subregion = String(id.prefix(4)).uppercased()
    let swiftUIColor: Color
    
    switch true {
    case ["AMNO", "AFSO", "ASSO"].contains(subregion):
        swiftUIColor = Color(hex: "#7152c0") //purple
    case ["ASHI", "OCML", "OCMD", "AFNO", "AMIN", "AMCR", "AMSO"].contains(subregion):
        swiftUIColor = Color(hex: "#d86563") //red
    case ["WEEU", "AMCE", "AFEA", "OCAU", "ASEA"].contains(subregion):
        swiftUIColor = Color(hex: "#efab79") //orange
    case ["AMNW", "ASNO", "AMLO", "ASWE", "OCMC"].contains(subregion):
        swiftUIColor = Color(hex: "#7d9ee0") //blue
    case ["ASSE", "ASIN", "EUEA", "AFWE", "AMHI", "AMSW"].contains(subregion):
        swiftUIColor = Color(hex: "#ffdb94") //yellow
    case ["ASCE", "AMEA", "OCPL", "AFCE"].contains(subregion):
        swiftUIColor = Color(hex: "#6ec79b") //green
    default: swiftUIColor = .white
    }
    
    // Convert SwiftUI Color to UIKit's UIColor
    return UIColor(swiftUIColor)
}
