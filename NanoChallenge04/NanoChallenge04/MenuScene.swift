//
//  MenuScene.swift
//  NanoChallenge04
//
//  Created by Felipe Nishino on 02/06/20.
//  Copyright © 2020 Grupo14. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    
//    var playButton = SKSpriteNode()
//    var configButton = SKSpriteNode()
//    let playButtonTex = SKTexture(imageNamed: "play")
    
    override func didMove(to view: SKView) {
        
//        playButton = SKSpriteNode(texture: playButtonTex)
//        playButton.position = CGPoint(x: frame.midX, y: frame.midY)
//        self.addChild(playButton)
//
//        configButton = SKSpriteNode(texture: playButtonTex)
//        configButton.position = CGPoint(x: frame.midX, y: frame.midY)
//        self.addChild(playButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let pos = touch.location(in: self)
            let node = self.atPoint(pos)
            
            if node.name == "jogar" {
                if let view = view {
                    let scene = GameScene.init(fileNamed: "GameScene")!
                    scene.scaleMode = SKSceneScaleMode.aspectFill
                    view.presentScene(scene)
                }
            }
            
            if node.name == "config" {
                if let view = view {
                    let scene = GameScene.init(fileNamed: "GameScene")!
                    scene.scaleMode = SKSceneScaleMode.aspectFill
                    view.presentScene(scene)
                }
            }
            
        }
    }
}
