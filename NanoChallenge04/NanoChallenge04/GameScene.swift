//
//  GameScene.swift
//  NanoChallenge04
//
//  Created by Felipe Nishino on 01/06/20.
//  Copyright © 2020 Grupo14. All rights reserved.
//


let kMinDistance = 25
let kMinDuration = 0.1
let kMinSpeed = 100
let kMaxSpeed = 7000
let lanesPosX : [CGFloat] = [-320, 0, 320]

import SpriteKit
import GameplayKit

enum Direction {
    case left
    case right
}

class GameScene: SKScene {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    private var start : CGPoint?
    private var startTime : TimeInterval?
    private var currentLane : Int = 1
    private var queuedLaneChange : Bool = false
    
    override func sceneDidLoad() {
        
        self.lastUpdateTime = 0
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        if let selta = childNode(withName: "selta") {
            selta.position.x = lanesPosX[currentLane]
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }
    
    func flick(dir: Direction) {
        print("entered flick")
        
        switch (dir) {
        case .left:
            if currentLane > 0 {
                currentLane -= 1
                queuedLaneChange = true
            }
        case .right:
            if currentLane < 2 {
                currentLane += 1
                queuedLaneChange = true
            }
        }
        print(currentLane)
        
    }
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
        
        if let celta = childNode(withName: "celta") {
            celta.position = CGPoint(x: pos.x, y: pos.y)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        /* Avoid multi-touch gestures (optional) */
        if touches.count > 1 {
            return;
        }
        
        // Save start location and time
        start = touches.first?.location(in: self);
        startTime = touches.first?.timestamp;
        
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Determine distance from the starting point
        var dx = CGFloat((touches.first?.location(in: self).x)! - start!.x);
        var dy = CGFloat((touches.first?.location(in: self).y)! - start!.y);
        
        let magnitude = CGFloat(sqrt(dx*dx+dy*dy));
        
        if magnitude >= CGFloat(kMinDistance) {
            // Determine time difference from start of the gesture
            let dt = CGFloat(touches.first!.timestamp - startTime!);
            if (dt > CGFloat(kMinDuration)) {
                // Determine gesture speed in points/sec
                let speed = magnitude / dt;
                if speed >= CGFloat(kMinSpeed) && speed <= CGFloat(kMaxSpeed) {
                    // Calculate normalized direction of the swipe
                    dx = dx / magnitude;
                    dy = dy / magnitude;
                    print("Swipe detected with speed = \(speed) and direction (\(dx), \(dy)")
                    flick(dir: (dx > 0 ? Direction.right : Direction.left))
                }
                else {
                    print("Invalid speed, \(speed)")
                }
            }
            else {
                print("Insufficient duration")
            }
        }
        else {
            print("Insufficient magnitude")
        }
        
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        if let selta = childNode(withName: "selta") {
            if queuedLaneChange {
                print("laneChange")
                selta.position.x = lanesPosX[currentLane]
                queuedLaneChange = false
            }
        }
        
        self.lastUpdateTime = currentTime
    }
}
