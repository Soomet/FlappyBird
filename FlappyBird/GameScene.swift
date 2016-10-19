//
//  GameScene.swift
//  FlappyBird
//
//  Created by Sumit Joshi on 10/12/16.
//  Copyright © 2016 soomet. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate, AVAudioPlayerDelegate{
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var cherryNode:SKNode!
    
    //音データの読み込み
    let playSoundAction = SKAction.playSoundFileNamed("bird.mp3", waitForCompletion: false)
    
    //衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       //0...00001
    let groundCategory: UInt32 = 1 << 1     //0...00010
    let wallCategory: UInt32 = 1 << 2       //0...00100
    let scoreCategory: UInt32 = 1 << 3      //0...01000
    let cherryCategory: UInt32 = 1 << 4     //0...10000
    
    //スコア
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    //アイテムスコア
    var bonusScore = 0
    var bonusScoreLabelNode:SKLabelNode!
    
    //SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMoveToView(view: SKView) {
        
        //重力を設定する
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        
        //背景色を設定
        backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //チェリー用のノード
        cherryNode = SKNode()
        scrollNode.addChild(cherryNode)
        
        //各種スプライトを生成する処理をメソッドに分割
        setupCherry()
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
    }
    
    func setupGround() {
    
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        //必要な枚数を計算
        let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveByX(-groundTexture.size().width, y: 0, duration: 5.0)
        
        //元の位置に戻すアクション
        let resetGround = SKAction.moveByX(groundTexture.size().width, y: 0, duration: 0.0)
        
        //左にスクロース　→　元の位置　→　左にスクロールと無限に繰り替えるアクション
        let repeatScrollGround = SKAction.repeatActionForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのスプライトを配置する
        CGFloat(0).stride(to: needNumber, by: 1.0).forEach { i in
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(x: i * sprite.size.width / 2, y : groundTexture.size().height / 2)
            
            //スプライトにアクションを設定する
            sprite.runAction(repeatScrollGround)
            
            //スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOfSize: groundTexture.size())
            
            //衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //衝突の時に動かないように設定する
            sprite.physicsBody?.dynamic = false
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        //必要な枚数を計算
        let needCloudNumber = 2.0 + (frame.size.width / cloudTexture.size().width)
        
        //スクロールするアクションを作成
        //左方向に画像を一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveByX(-cloudTexture.size().width, y: 0, duration: 20.0)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveByX(cloudTexture.size().width, y: 0, duration: 0.0)
        
        //左にスクロール　→　元の位置　→　左にスクロールと無限に繰り替えるアクション
        let repeatScrollCloud = SKAction.repeatActionForever(SKAction.sequence([moveCloud, resetCloud]))
        
        //スプライトを配置する
        CGFloat(0).stride(to: needCloudNumber, by: 1.0).forEach { i in
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(x: i * sprite.size.width, y: size.height - cloudTexture.size().height / 2)
            
            //スプライトにアニメーションを設定する
            sprite.runAction(repeatScrollCloud)
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCherry() {
        
        //アイテムの画像を読み込む
        let cherryTexture = SKTexture(imageNamed: "cherry")
        cherryTexture.filteringMode = .Linear
        print (cherryTexture.size())
        
        
        //必要な個数を計算
        let cherryMovingDistance = CGFloat(self.frame.size.width + cherryTexture.size().width * 3.5)
        
        //画面外まで移動するアクションを作成
        let moveCherry = SKAction.moveByX(-cherryMovingDistance, y: 0, duration: 2.0)
        
        //自身を取り除くアクションを作成
        let removeCherry = SKAction.removeFromParent()
        
        //２つアニメーションを順に実行するアクションを生成
        let cherryAnimation = SKAction.sequence([moveCherry, removeCherry])
        
        //チェリーを生成するアクションを生成
        let createCherryAnimation = SKAction.runBlock({
            
            //チェリー関連のノードを乗せるノードを作成
            let cherry = SKNode()
            cherry.position = CGPoint(x: self.frame.size.width + cherryTexture.size().width * 3.5, y: 0.0)
            cherry.zPosition = -10.0 //雲より手前、地面より奥
            
            //画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            //アイテムのY座標をランダムにさせる時の最大値
            let random_y_range = self.frame.size.height / 3
            //アイテムのY軸の下限
            let cherry_lowest_y = UInt32(center_y - random_y_range / 2)
            //1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform(UInt32(random_y_range))
            //y軸の下限にランダムな値を足して、アイテムのy座標を設定
            let cherry_y = CGFloat(cherry_lowest_y + random_y)
            
            //チェリーを作成
            let cherrySprite = SKSpriteNode(texture: cherryTexture)
            cherrySprite.position = CGPoint(x: 0.0, y: cherry_y + cherryTexture.size().height)
            
            //スプライトに物理演算を設定する
            cherrySprite.physicsBody = SKPhysicsBody(rectangleOfSize: cherryTexture.size())
            cherrySprite.physicsBody?.categoryBitMask = self.cherryCategory
            cherrySprite.physicsBody?.contactTestBitMask = self.birdCategory
            
            cherry.addChild(cherrySprite)
            
            //衝突の時に動かないように設定する
            cherrySprite.physicsBody?.dynamic = false
            
            cherry.runAction(cherryAnimation)
            
            self.cherryNode.addChild(cherry)
            
        })
        //次のcherry作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.waitForDuration(2)
        
        //cherryを作成　→　待ち時間　→　cherryの作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatActionForever(SKAction.sequence([createCherryAnimation, waitAnimation]))
        
        cherryNode.runAction(repeatForeverAnimation)
    }
    
    func setupWall() {
        
        //壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .Linear
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveByX(-movingDistance, y: 0, duration: 4.0)
        
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //２つアニメーションを順に実行するアクションを生成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.runBlock({
            
            //壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x : self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0 //雲より手前、地面より奥
            
            //画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            //壁のY座標を上下ランダムにさせる時の最大値
            let random_y_range = self.frame.size.height / 4
            //下の壁のY軸の下限
            let under_wall_lowest_y = UInt32(center_y - wallTexture.size().height / 2 - random_y_range / 2)
            //1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform(UInt32(random_y_range))
            //y軸の下限にランダムな値を足して、下の壁のy座標を設定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            //キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 3
        
            //下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            wall.addChild(under)
            
            //スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOfSize: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突の時に動かないように設定する
            under.physicsBody?.dynamic = false
        
            //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOfSize: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突の時に動かないように設定する
            upper.physicsBody?.dynamic = false
            
            wall.addChild(upper)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.dynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.runAction(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        //次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.waitForDuration(2)
        
        //壁を作成　→　待ち時間　→　壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatActionForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.runAction(repeatForeverAnimation)
    }
    
    func setupBird() {
        //鳥の画像を２種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = SKTextureFilteringMode.Linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = SKTextureFilteringMode.Linear
        
        //２種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animateWithTextures([birdTextureA, birdTextureB], timePerFrame: 0.1)
        let flap = SKAction.repeatActionForever(texturesAnimation)
        
        //スプライトを生成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | cherryCategory
        
        //アニメーションを設定
        bird.runAction(flap)
        
        addChild(bird)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if scrollNode.speed > 0{
            //鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            
            //鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 13))
        } else if bird.speed == 0 {
            restart()
        }

    }
    
    //SKPhysicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBeginContact(contact: SKPhysicsContact) {
        //ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //スコア用の物体と衝突した
            print("Score Up")
            score += 10
            scoreLabelNode.text = "Score: \(score)"
            
            //ベストスコア更新か確認する
            var bestScore = userDefaults.integerForKey("BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score: \(bestScore)"
                userDefaults.setInteger(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        } else if (contact.bodyA.categoryBitMask & cherryCategory) == cherryCategory || (contact.bodyB.categoryBitMask & cherryCategory) == cherryCategory{
            
            //アイテムと衝突した
            
            //音を鳴らす
            runAction(playSoundAction)
            
            if (contact.bodyA.categoryBitMask == cherryCategory) {
                contact.bodyA.node?.removeFromParent()
            } else {
                contact.bodyB.node?.removeFromParent()
            }
            
            print("BONUS!!!!")
            score += 50
            bonusScore += 50
            scoreLabelNode.text = "Score: \(score)"
            bonusScoreLabelNode.text = "Bonus: \(bonusScore)"
            
            //ベストスコア更新か確認する
            var bestScore = userDefaults.integerForKey("BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score: \(bestScore)"
                userDefaults.setInteger(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }

        }else {
            //壁か地面と衝突した
            print ("GameOver")
            
            //スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotateByAngle(CGFloat(M_PI) + CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.runAction(roll, completion: {
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        score = 0
        bonusScore = 0
        scoreLabelNode.text = String("Score: \(score)")
        bonusScoreLabelNode.text = String("Bonus: \(bonusScore)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        cherryNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.blackColor()
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100 //一番手前に表示するため
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        scoreLabelNode.text = "Score: \(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.blackColor()
        bestScoreLabelNode.position = CGPoint(x: 10, y : self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 //一番手前に表示するため
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        
        let bestScore = userDefaults.integerForKey("BEST")
        bestScoreLabelNode.text = "Best Score: \(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        bonusScore = 0
        bonusScoreLabelNode = SKLabelNode()
        bonusScoreLabelNode.fontColor = UIColor.blueColor()
        bonusScoreLabelNode.position = CGPoint(x: 10, y : self.frame.size.height - 60)
        bonusScoreLabelNode.zPosition = 100
        bonusScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        bonusScoreLabelNode.text = "Bonus: \(bonusScore)"
        self.addChild(bonusScoreLabelNode)
    }
}
