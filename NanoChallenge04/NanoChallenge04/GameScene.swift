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
let initialSpeed : CGFloat = 250
let initialObstacleFrequency : Double = 1.5
let initialSpeedUpFrequency : Double = 15
let obstaclePathPoints : [[CGPoint]] =
    [
        [CGPoint(x: -10, y: -10), CGPoint(x: 10, y: -10), CGPoint(x: 30, y: -10)],
        [CGPoint(x: -490, y: -1400), CGPoint(x: 10, y: -1400), CGPoint(x: 475, y: -1400)]
]
let dyMax = obstaclePathPoints[1][0].y - obstaclePathPoints[0][0].y


import SpriteKit
import GameplayKit

enum Direction {
    case left
    case right
}

enum CollisionType : UInt32 {
    case player = 1
    case obstacle = 2
}

enum NodeType {
    case obstacle
    case leftLane
    case rightLane
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastLaneSpawnTime : TimeInterval = 0
    private var lastObstacleSpawnTime : TimeInterval = 0
    private var lastUpdateTime : TimeInterval = 0
    private var lastSpeedUp : TimeInterval = 0
    private var start : CGPoint?
    private var startTime : TimeInterval?
    private var currentLane : Int = 1
    private var queuedLaneChange : Bool = false
    private var isAlive : Bool = true
    private var obstacleSpeed = initialSpeed
    private var obstacleFrequency = initialObstacleFrequency
    private var speedUpFrequency = initialSpeedUpFrequency
    private var obstacleCooldown : Bool = false
    private var startCountdown : Int = 3
    private var countdownTime : TimeInterval = 0
    private var playTime : TimeInterval = 0
    private var dados = Dados()
    private var fontColor = UIColor.black
    
    override func sceneDidLoad() {
        
        if let selta = childNode(withName: "selta") {
            selta.position.x = laneXCoord[currentLane]
            selta.physicsBody?.categoryBitMask = CollisionType.player.rawValue
            selta.physicsBody?.contactTestBitMask = CollisionType.obstacle.rawValue
            selta.physicsBody?.collisionBitMask = 0
        }
        dados.carregarDados()
        
        let lblMarcha = SKLabelNode(text: "Mete marcha!")
        lblMarcha.position = CGPoint(x: 0, y: 130)
        lblMarcha.zPosition = 12
        lblMarcha.name = "lblMarcha"
        lblMarcha.fontSize = 100
        lblMarcha.fontName = "Skia-Bold"
        lblMarcha.fontColor = fontColor
        lblMarcha.run(SKAction.fadeOut(withDuration: 0))
        addChild(lblMarcha)
        
        let lblStart = SKLabelNode(text: "3")
        lblStart.position = CGPoint(x: 0, y: 100)
        lblStart.zPosition = 11
        lblStart.name = "lblStart"
        lblStart.fontSize = 100
        lblStart.fontName = "Skia-Bold"
        lblStart.fontColor = fontColor
        lblStart.run(SKAction(named: "Countdown")!)
        addChild(lblStart)
        
        let background = SKSpriteNode(texture: SKTexture(imageNamed: "dia"))
        background.position = CGPoint(x: 0, y: self.size.height / 4)
        background.zPosition = 10
        let hour = Calendar.current.component(.hour, from: Date())
        
        if  18 <= hour || hour < 6 {
            background.texture = SKTexture(imageNamed: "noite")
            fontColor = .white
        }
        
        addChild(background)
        
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
        startCountdown = 3
        
        if let selta = childNode(withName: "selta") {
            selta.run(SKAction.rotate(toAngle: 0, duration: 0))
            selta.position.x = laneXCoord[currentLane]
        }
        if let lblLost = childNode(withName: "lblLost") {
            lblLost.removeFromParent()
        }
        
        enumerateChildNodes(withName: "leftLane") {
            node, _ in
            
            
            node.removeFromParent()
        }
        
        enumerateChildNodes(withName: "rightLane") {
            node, _ in
            
            node.removeFromParent()
        }
        
        if let lblTime = childNode(withName: "lblTime") as? SKLabelNode {
            lblTime.removeFromParent()
        }
        
        if let lblStart = childNode(withName: "lblStart") as? SKLabelNode {
            lblStart.text = "3"
            lblStart.run(SKAction(named: "Countdown")!)
        }
        
        if let lblRecorde = childNode(withName: "lblRecorde") as? SKLabelNode {
            lblRecorde.removeFromParent()
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
        lblLost.fontColor = fontColor
        addChild(lblLost)
        
        let retryButton = SKSpriteNode(imageNamed: "play")
        retryButton.position = CGPoint(x: frame.midX, y: frame.midY)
        retryButton.name = "retry"
        retryButton.zPosition = 999
        self.addChild(retryButton)
        
        isAlive = false
        if let selta = childNode(withName: "selta") {
            selta.run(SKAction.rotate(toAngle: .pi*3/4 + CGFloat(currentLane) * .pi/4, duration: 0))
        }
        
         if let lblTime = childNode(withName: "lblTime") as? SKLabelNode {
            if playTime > dados.Recorde! {
                dados.Recorde = Double(lblTime.text!)
                dados.salvarDados()
            }
        }
        
        let lblRecorde = SKLabelNode(fontNamed: "Skia-Bold")
        lblRecorde.text = "Recorde: " + String(format: "%.2f", dados.Recorde!)
        lblRecorde.name = "lblRecorde"
        lblRecorde.fontSize = 100
        lblRecorde.fontColor = fontColor
        lblRecorde.zPosition = 11
        lblRecorde.position = CGPoint(x: 0, y: 580)
        addChild(lblRecorde)
        
    }
    
    func touchDown(atPoint pos : CGPoint) {
    }
    
    func touchMoved(toPoint pos : CGPoint) {
    }
    
    func touchUp(atPoint pos : CGPoint) {   
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
        if isAlive && startCountdown == 0{
            
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
                        //                        print("Swipe detected with speed = \(speed) and direction (\(dx), \(dy)")
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
    }
    
    func spawnObstacle() {
        var generatedNumbers = Set<Int>()
        let quantity = Int.random(in: 0...1)
        var lane : Int = -1
        var image : Int = 0
        
        generatedNumbers.insert(lane)
        
        for _ in 0...quantity {
            //            let obstacle = SKSpriteNode.init(color: .green, size: CGSize.init(width: 80, height: 80))
            
            while generatedNumbers.contains(lane) {
                lane = Int.random(in: 0...2)
            }
            
            image = Int.random(in: 0...1)
            
            var obstacle = SKSpriteNode()
            
            switch image {
            case 1:
                obstacle = SKSpriteNode(imageNamed: "cone")
            default:
                obstacle = SKSpriteNode(imageNamed: "pneu")
            }
            
            let obstaclePath = UIBezierPath()
            
            obstaclePath.move(to: obstaclePathPoints[0][lane])
            obstaclePath.addLine(to: obstaclePathPoints[1][lane])
            
            obstacle.name = "obstacle"
            obstacle.size = CGSize(width: 1.5 * obstacle.size.width, height: 1.5 * obstacle.size.height)
            obstacle.physicsBody = .init(rectangleOf: CGSize.init(width: 100, height: 100), center: CGPoint(x: 0.5, y: 0.5))
            
            obstacle.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            obstacle.zPosition = 1
            obstacle.physicsBody?.categoryBitMask = CollisionType.obstacle.rawValue
            obstacle.physicsBody?.contactTestBitMask = CollisionType.player.rawValue
            obstacle.physicsBody?.collisionBitMask = 0
            
            obstacle.physicsBody?.affectedByGravity = false
            generatedNumbers.insert(lane)
            addChild(obstacle)
            
            let movement = SKAction.follow(obstaclePath.cgPath, asOffset: true, orientToPath: false, speed: obstacleSpeed)
            movement.timingMode = .easeIn
            movement.timingFunction = {
                time in
                return powf(time, 5)
            }
            let sequence = SKAction.sequence([movement, .removeFromParent()])
            obstacle.run(sequence)
        }
    }
    
    func spawnLaneNodes() {
        let leftPath = UIBezierPath()
        let rightPath = UIBezierPath()
        
        leftPath.move(to: CGPoint(x: 0, y: -15))
        leftPath.addLine(to: CGPoint(x: -262, y: -1458))
        
        rightPath.move(to: CGPoint(x: 30, y: -15))
        rightPath.addLine(to: CGPoint(x: 306, y: -1458))
        
        let leftLane = SKSpriteNode(imageNamed: "retangulinho2")
        leftLane.zPosition = 1
        leftLane.size = CGSize(width: 90, height: 229)
        leftLane.name = "leftLane"
        addChild(leftLane)
        
        let rightLane = SKSpriteNode(imageNamed: "retangulinho-invertido")
        rightLane.zPosition = 1
        rightLane.size = CGSize(width: 90, height: 229)
        rightLane.name = "rightLane"
        addChild(rightLane)
        
        let leftMovement = SKAction.follow(leftPath.cgPath, asOffset: true, orientToPath: false, speed: obstacleSpeed)
        leftMovement.timingMode = .easeIn
        leftMovement.timingFunction = {
            time in
            return powf(time, 5)
        }
        
        let leftSequence = SKAction.sequence([leftMovement, .removeFromParent()])
        
        let rightMovement = SKAction.follow(rightPath.cgPath, asOffset: true, orientToPath: false, speed: obstacleSpeed)
        rightMovement.timingMode = .easeIn
        rightMovement.timingFunction = {
            time in
            return powf(time, 5)
        }
        
        let rightSequence = SKAction.sequence([rightMovement, .removeFromParent()])
        
        leftLane.run(leftSequence)
        rightLane.run(rightSequence)
    }
    
    func updateNodeScale(nodeType: NodeType) {
        var name = String()
        var dyObstacle = CGFloat()
        var scale = CGFloat()
        
        switch nodeType {
        case .leftLane:
            name = "leftLane"
        case .rightLane:
            name = "rightLane"
        default:
            name = "obstacle"
        }
        
        enumerateChildNodes(withName: name) {
            node, _ in
            
            if name == "obstacle" {
                if !self.isAlive {
                    node.removeFromParent()
                }
                
                dyObstacle = node.position.y - obstaclePathPoints[0][0].y
                scale = dyObstacle / dyMax
                scale = scale * 2
            }
            else {
                if !self.isAlive {
                    node.removeAllActions()
                }
                
                dyObstacle = node.position.y - -30
                scale = dyObstacle / (-1458 - -30)
            }
            
            node.setScale(scale)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if self.lastUpdateTime == 0 {
            self.lastUpdateTime = currentTime + 2
            self.lastSpeedUp = lastUpdateTime
            self.countdownTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        if isAlive {
            playTime = currentTime - countdownTime

            if let lblTime = childNode(withName: "lblTime") as? SKLabelNode {
                lblTime.text = String(format: "%.2f", playTime)
            }
            
            if currentTime - lastLaneSpawnTime > obstacleFrequency / 4 {
                spawnLaneNodes()
                lastLaneSpawnTime = currentTime
            }
            
            if !obstacleCooldown {
                
                if currentTime - lastObstacleSpawnTime > obstacleFrequency {
                    spawnObstacle()
                    lastObstacleSpawnTime = currentTime
                }
                
                if currentTime - lastSpeedUp > speedUpFrequency {
                    obstacleSpeed = obstacleSpeed * 1.15
                    lastSpeedUp = currentTime
                    print("METE MARCHA")
                    obstacleCooldown = true
                    
                    if let lblMarcha = childNode(withName: "lblMarcha") {
                        lblMarcha.run(SKAction(named: "Marcha")!)
                    }
                }
            }
        }
        
        if currentTime - countdownTime > 1 && startCountdown != 0 {
         
            countdownTime = currentTime
            startCountdown -= 1
            
            if let lblStart = childNode(withName: "lblStart") as? SKLabelNode {
                switch startCountdown {
                case 2:
                    lblStart.text = "2"
                case 1:
                    lblStart.text = "1"
                default:
                    lblStart.text = "Acelera!"
                    let lblTime = SKLabelNode(text: "0")
                    lblTime.position = CGPoint(x: 0, y: 480)
                    lblTime.zPosition = 11
                    lblTime.fontSize = 100
                    lblTime.fontName = "Skia-Bold"
                    lblTime.fontColor = fontColor
                    lblTime.name = "lblTime"
                    addChild(lblTime)
                }
            }
            
        }
        if currentTime - lastObstacleSpawnTime > 2.5 {
            obstacleCooldown = false
        }
        
        updateNodeScale(nodeType: .obstacle)
        updateNodeScale(nodeType: .leftLane)
        updateNodeScale(nodeType: .rightLane)
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        if let selta = childNode(withName: "selta") {
            if queuedLaneChange {
                selta.position.x = laneXCoord[currentLane]
                queuedLaneChange = false
            }
        }
        
        self.lastUpdateTime = currentTime
    }
}
