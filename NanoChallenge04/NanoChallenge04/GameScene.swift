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
let laneXCoord : [CGFloat] = [-360, 14, 395]
let initialSpeed : CGFloat = 8
let initialObstacleFrequency : Double = 1.5
let initialSpeedUpFrequency : Double = 15
let obstaclePathPoints : [[CGPoint]] =
    [
        [CGPoint(x: -20, y: -71), CGPoint(x: 20, y: -71), CGPoint(x: 50, y: -71)],
        [CGPoint(x: -360, y: -1400), CGPoint(x: 14, y: -1400), CGPoint(x: 395, y: -1400)]
    ]
let dyMax = obstaclePathPoints[1][0].y - obstaclePathPoints[0][0].y


import SpriteKit
import GameplayKit

enum Direction {
    case left
    case right
}

enum CollisionType: UInt32 {
    case player = 1
    case obstacle = 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastLaneSpawnTime : TimeInterval = 0
    private var lastObstacleSpawnTime : TimeInterval = 0
    private var lastUpdateTime : TimeInterval = 0
    private var lastSpeedUp : TimeInterval = 0
    private var spinnyNode : SKShapeNode?
    private var start : CGPoint?
    private var startTime : TimeInterval?
    private var currentLane : Int = 1
    private var queuedLaneChange : Bool = false
    private var isAlive : Bool = true
    private var obstacleSpeed = initialSpeed
    private var obstacleFrequency = initialObstacleFrequency
    private var speedUpFrequency = initialSpeedUpFrequency
    
    override func sceneDidLoad() {
        
        self.lastUpdateTime = 0
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
        
        if let selta = childNode(withName: "selta") {
            selta.position.x = laneXCoord[currentLane]
            selta.physicsBody?.categoryBitMask = CollisionType.player.rawValue
            selta.physicsBody?.contactTestBitMask = CollisionType.obstacle.rawValue
            selta.physicsBody?.collisionBitMask = 0
        }
        
        let lblMarcha = SKLabelNode(text: "Mete marcha!")
        lblMarcha.position = CGPoint(x: frame.midX, y: frame.midY + frame.midY / 2)
        lblMarcha.name = "lblMarcha"
        lblMarcha.fontSize = 100
        addChild(lblMarcha)
        
        physicsWorld.contactDelegate = self
    }
    
    func resetGameParameters() {
        obstacleSpeed = initialSpeed
        isAlive = true
        queuedLaneChange = false
        lastObstacleSpawnTime = 0
        lastUpdateTime = 0
        lastSpeedUp = 0
        currentLane = 1
        
        if let selta = childNode(withName: "selta") {
            selta.run(SKAction.rotate(toAngle: 0, duration: 0))
            selta.position.x = laneXCoord[currentLane]
        }
        if let lblLost = childNode(withName: "lblLost") {
            lblLost.removeFromParent()
        }
    }
    

    
    func didBegin(_ contact: SKPhysicsContact) {
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        
        if nodeA?.name == "obstacle" {
            nodeA?.removeFromParent()
        }
        else if nodeB?.name == "obstacle" {
            nodeB?.removeFromParent()
        }
        
        let lblLost = SKLabelNode(text: "Ihhhh capotou o selta")
        lblLost.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        lblLost.name = "lblLost"
        lblLost.fontSize = 100
        addChild(lblLost)
        
        let retryButton = SKSpriteNode(imageNamed: "play")
        retryButton.position = CGPoint(x: frame.midX, y: frame.midY)
        retryButton.scale(to: CGSize(width: 200, height: 200))
        retryButton.name = "retry"
        self.addChild(retryButton)
        
        print("capotou")
        isAlive = false
        if let selta = childNode(withName: "selta") {
            selta.run(SKAction.rotate(toAngle: .pi*3/4 + CGFloat(currentLane) * .pi/4, duration: 0))
        }
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
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Avoid multi-touch gestures (optional) */
        if touches.count > 1 {
            return;
        }
        
        // Save start location and time
        start = touches.first?.location(in: self);
        startTime = touches.first?.timestamp;
        
        if let retrybutton = childNode(withName: "retry") {
            let node = self.atPoint(start!)
            if node == retrybutton {
                resetGameParameters()
                retrybutton.removeFromParent()
            }
        }
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Determine distance from the starting point
        if isAlive {
            
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
        }
        
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
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
    
    func spawnObstacle() {
        var generatedNumbers = Set<Int>()
        let quantity = Int.random(in: 0...1)
        var lane : Int = -1
        
        generatedNumbers.insert(lane)
        
        for _ in 0...quantity {
            let obstacle = SKSpriteNode.init(color: .green, size: CGSize.init(width: 80, height: 80))
            
            while generatedNumbers.contains(lane) {
                lane = Int.random(in: 0...2)
            }
            
            let obstaclePath = UIBezierPath()
            
            obstaclePath.move(to: obstaclePathPoints[0][lane])
            obstaclePath.addLine(to: obstaclePathPoints[1][lane])
            
            obstacle.name = "obstacle"
            obstacle.physicsBody = .init(rectangleOf: CGSize.init(width: 100, height: 100), center: CGPoint(x: 0.5, y: 0.5))
            
            obstacle.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            obstacle.zPosition = 1
            obstacle.physicsBody?.categoryBitMask = CollisionType.obstacle.rawValue
            obstacle.physicsBody?.contactTestBitMask = CollisionType.player.rawValue
            obstacle.physicsBody?.collisionBitMask = 0
            
            obstacle.physicsBody?.affectedByGravity = false
            generatedNumbers.insert(lane)
            addChild(obstacle)
            
            let movement = SKAction.follow(obstaclePath.cgPath, asOffset: true, orientToPath: false, speed: 500)
            let sequence = SKAction.sequence([movement, .removeFromParent()])
            obstacle.run(sequence)
        }
    }
    
    func spawnLaneNodes() {
        let leftPath = UIBezierPath()
//        let rightPath = UIBezierPath()
        
        leftPath.move(to: CGPoint(x: 0, y: -30))
        leftPath.addLine(to: CGPoint(x: -262, y: -1458))
        
        let leftLane = SKSpriteNode(imageNamed: "retangulinho2")
        leftLane.zPosition = 1
        leftLane.size = CGSize(width: 90, height: 229)
        leftLane.name = "leftLane"
        addChild(leftLane)
        
        let movement = SKAction.follow(leftPath.cgPath, asOffset: true, orientToPath: false, speed: 500)
        let sequence = SKAction.sequence([movement, .removeFromParent()])
        leftLane.run(sequence)
    }
    
    func configureMovement(_ moveStraight: Bool) {
        let path = UIBezierPath()

        path.move(to: .zero)

        path.addLine(to: CGPoint(x: -10000, y: 0))

        let movement = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: obstacleSpeed)
        let sequence = SKAction.sequence([movement, .removeFromParent()])
        run(sequence)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        if isAlive {
            if currentTime - lastObstacleSpawnTime > obstacleFrequency {
                spawnObstacle()
                lastObstacleSpawnTime = currentTime
            }
            
            if currentTime - lastLaneSpawnTime > obstacleFrequency / 2 {
                spawnLaneNodes()
                lastLaneSpawnTime = currentTime
            }
            
            if currentTime - lastSpeedUp > speedUpFrequency {
                obstacleSpeed = obstacleSpeed * 1.25
                lastSpeedUp = currentTime
                print("METE MARCHA")
                
                if let lblMarcha = childNode(withName: "lblMarcha") {
                    lblMarcha.run(SKAction(named: "Marcha")!)
                }
            }
            
        }
        
        enumerateChildNodes(withName: "obstacle") {
            node, _ in
            
            if !self.isAlive {
                node.removeFromParent()
            }
            print("node: \(node.position.y)")
            print("constant: \(obstaclePathPoints[0][0].y)")
            let dyObstacle = node.position.y - obstaclePathPoints[0][0].y
            print("dy: \(dyObstacle)")
            print("dyMax: \(dyMax)")
            var scale = dyObstacle / dyMax
            print(scale)
            if scale < 0.15 {
                scale = 0.15
            }
//            scale = scale * 2
    
            node.setScale(scale)
        }
        
        enumerateChildNodes(withName: "leftLane") {
            node, _ in
            
            let dyObstacle = node.position.y - -30
            var scale = dyObstacle / (-1458 - -30)
            if scale < 0.15 {
                scale = 0.15
            }
//            scale = scale * 2
            node.setScale(scale)

        }
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        if let selta = childNode(withName: "selta") {
            if queuedLaneChange {
                print("laneChange")
                selta.position.x = laneXCoord[currentLane]
                queuedLaneChange = false
            }
        }
        
        self.lastUpdateTime = currentTime
    }
}
