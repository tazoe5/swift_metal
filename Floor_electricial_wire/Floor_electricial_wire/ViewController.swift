//
//  ViewController.swift
//  ARKit-Template
//
//  Created by Kouhei Tazoe on 2019/01/21.
//  Copyright © 2019年 Kouhei Tazoe. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var firstFloor: SCNVector3!
    var secondFloor: SCNVector3!
    var ceilling = SCNNode()
    var floor = SCNNode()
    @IBOutlet var sceneView: ARSCNView!
    
    @IBAction func singleTapped(_ sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
        
        if let hitResult = hitTestResult.first {
            let transform = hitResult.worldTransform.columns.3
            firstFloor = SCNVector3(transform.x, transform.y, transform.z)
            //addLine()
            addBox(position: firstFloor, color: UIColor.blue)
        }
    }
    @IBAction func doubleTapped(_ sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
        
        if let hitResult = hitTestResult.first {
            let transform = hitResult.worldTransform.columns.3
            secondFloor = SCNVector3(transform.x, transform.y, transform.z)
            //addLine()
            addBox(position: secondFloor, color: UIColor.red)
        }
    }
   
    func addBox(position: SCNVector3, color: UIColor) {
        let node = SCNNode()
        let geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        geometry.firstMaterial?.diffuse.contents = color
        node.geometry = geometry
        node.position = position
        sceneView.scene.rootNode.addChildNode(node)
    }
    /*
    func addLine() {
        print("addLine")
        if firstFloor == nil || secondFloor == nil { return }
        print("firstFloor and secondFloor are not nil.")
        print(firstFloor)
        print(secondFloor)
        func getPoint (vector: SCNVector3) -> (above: SCNVector3, below: SCNVector3) {
            let vec1 = SCNVector3Make(vector.x - 0.2, vector.y, vector.z - 0.2)
            let vec2 = SCNVector3Make(vector.x + 0.2, vector.y, vector.z - 0.2)
            return (vec1, vec2)
        }
        let vec1 = getPoint(vector: firstFloor)
        let vec2 = getPoint(vector: secondFloor)
        let vertices: [SCNVector3] = [vec1.above, vec1.below, vec2.above, vec2.below]
        print(vertices)
        let verticesSource = SCNGeometrySource(vertices: vertices)
        let lineSource = SCNGeometryElement(indices: [1, 0, 3, 2], primitiveType: .triangleStrip)
        let customGeometry = SCNGeometry(sources: [verticesSource], elements: [lineSource])
        customGeometry.firstMaterial?.diffuse.contents = UIColor.green
        let line = SCNNode(geometry: customGeometry)
        print("line")
        sceneView.scene.rootNode.addChildNode(line)
    } */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false //true
        
        // Create a new scene
        let scene = SCNScene() // named: "art.scnassets/ship.scn")!
        // Set the scene to the view
        sceneView.scene = scene
        
        let floorGeometry = SCNPlane()
        floor.eulerAngles.x = -Float.pi/2
        floorGeometry.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/shin_nihon.png")
        floor.geometry = floorGeometry
        floor.renderingOrder = 0
        sceneView.scene.rootNode.addChildNode(floor)
        
        let ceillingGeometry = SCNPlane()
        ceilling.eulerAngles.x = Float.pi/2
        ceillingGeometry.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/shin_nihon.png")
        ceilling.geometry = ceillingGeometry
        ceilling.renderingOrder = 0
        sceneView.scene.rootNode.addChildNode(ceilling)
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }
    
    func createFloor(planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        let geometry = SCNPlane(width:
            CGFloat(planeAnchor.extent.x), height:
            CGFloat(planeAnchor.extent.z))

        geometry.firstMaterial?.diffuse.contents = UIColor.clear
        let node = SCNNode()
        node.geometry = geometry
        
        node.eulerAngles.x = -Float.pi/2
        node.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        node.renderingOrder = -1
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        let floor = createFloor(planeAnchor: planeAnchor)
        node.addChildNode(floor)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor
            else{return}
        for node in node.childNodes {
            node.position = SCNVector3(planeAnchor.center.x, node.position.y, planeAnchor.center.z)
            if let plane = node.geometry as? SCNPlane {
                plane.width = CGFloat(planeAnchor.extent.x)
                plane.height = CGFloat(planeAnchor.extent.z)
                
                if node.worldPosition.y < floor.worldPosition.y {
                    print("move floor plane.")
                    floor.worldPosition = node.worldPosition
                    let floorPlane = floor.geometry as! SCNPlane
                    // ポスター用
                    floorPlane.width = plane.width
                    floorPlane.height = plane.width*1.4
                }
                if node.worldPosition.y > ceilling.worldPosition.y {
                    print("move cailling plane.")
                    ceilling.worldPosition = node.worldPosition
                    let ceillingPlane = floor.geometry as! SCNPlane
                    ceillingPlane.width = plane.width
                    ceillingPlane.height = plane.height*1.4
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = [.horizontal]
        // Run the view's session
        sceneView.session.run(configuration)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

