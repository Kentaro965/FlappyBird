//
//  GameScene.swift
//  FlappyBird
//
//  Created by ShibayamaKentaro on 2020/02/06.
//  Copyright © 2020 KKK. All rights reserved.
//

import AVFoundation
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    // level調節用
    var timelevel: Double = 4
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var pointNode: SKNode!
    var bird: SKSpriteNode!
    // 再生するサウンドのインスタンス
    var audioPlayerInstance: AVAudioPlayer!
    var audioPlayerInstance2: AVAudioPlayer!
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0 // 0...00001
    let groundCategory: UInt32 = 1 << 1 // 0...00010
    let wallCategory: UInt32 = 1 << 2 // 0...00100
    let scoreCategory: UInt32 = 1 << 3 // 0...01000
    let pointCategory: UInt32 = 1 << 4
    // スコア用
    var score = 0
    var scoreLabelNode: SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    let userDefaults: UserDefaults = UserDefaults.standard
    // ポイントスコア用
    var pointscore = 0
    var pointLabelNode: SKLabelNode!
    var bestPointLabelNode: SKLabelNode!
    
    // テクスチャアトラスからボタン作成
    // let button = SKSpriteNode(texture: SKTextureAtlas(named: "bird_a").textureNamed("button"))
    // イメージからそのままの場合は
    let button = SKSpriteNode(imageNamed: "IMG_7698")
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        button.size = CGSize(width: frame.size.width / 2, height: self.frame.size.height / 2)
        button.position = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
        button.zPosition = 1
        button.name = "button"
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        
        physicsWorld.contactDelegate = self
        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のノード
        if wallNode == nil {
            wallNode = SKNode()
            scrollNode.addChild(wallNode)
        }
        pointNode = SKNode()
        scrollNode.addChild(pointNode)
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupPoint()
        
        setupScoreLabel()
        setupPointLabel()
        
        // サウンドファイルのパスを生成(今回のファイルに導入した画像ファイル名を書きます)
        let soundFilePath = Bundle.main.path(forResource: "explosion3", ofType: "mp3")!
        let sound: URL = URL(fileURLWithPath: soundFilePath)
        // AVAudioPlayerのインスタンスを作成,ファイルの読み込み
        do {
            audioPlayerInstance = try AVAudioPlayer(contentsOf: sound, fileTypeHint: nil)
        } catch {
            print("AVAudioPlayerインスタンス作成でエラー")
        }
        // 再生準備
        audioPlayerInstance.prepareToPlay()
        // サウンドファイルのパスを生成(今回のファイルに導入した画像ファイル名を書きます)
        let soundFilePath2 = Bundle.main.path(forResource: "wave1", ofType: "mp3")!
        let sound2: URL = URL(fileURLWithPath: soundFilePath2)
        // AVAudioPlayerのインスタンスを作成,ファイルの読み込み
        do {
            audioPlayerInstance2 = try AVAudioPlayer(contentsOf: sound2, fileTypeHint: nil)
        } catch {
            print("AVAudioPlayerインスタンス作成でエラー")
        }
        // 再生準備
        audioPlayerInstance2.prepareToPlay()
        audioPlayerInstance2.currentTime = 0 // 再生箇所を頭に移す
        audioPlayerInstance2.play() // 再生する
        audioPlayerInstance2.numberOfLoops = -1 // 永遠ループ
    }
    
    func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            // スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: timelevel)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        // 鳥が通り抜ける隙間の長さを鳥のサイズの3倍とする
        let slit_length = birdSize.height * 3
        
        // 隙間位置の上下の振れ幅を鳥のサイズの3倍とする
        let random_y_range = birdSize.height * 3
        
        // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run {
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            
            // 0〜random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            wall.addChild(under)
            
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            
            under.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            wall.addChild(upper)
            // スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            
            upper.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            // スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            /* // Pointスコアアップ用のノード
             let pointNode = SKNode()
             //ランダム値生成
             let random_p_range=self.frame.size.height
             let random_po_range=self.frame.size.width
             // 0〜random_y_rangeまでのランダム値を生成
             let random_p = CGFloat.random(in: 0..<random_p_range)
             let random_po=CGFloat.random(in: 0..<random_po_range)
             // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
             pointNode.position = CGPoint(x:  random_po, y: random_p)
             pointNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width/40, height: self.frame.size.height/30))
             scoreNode.physicsBody?.isDynamic = false
             scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
             scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
             
             wall.addChild(pointNode) */
            wall.addChild(scoreNode)
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        }
        
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory | pointCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加する
        addChild(bird)
    }
    
    func setupPoint() {
        // pointの画像を読み込む
       // let pointTexture = SKTexture()
       //pointTexture.filteringMode = .linear
      

        
        // wallTextureを取得
        let wallTexture = SKTexture(imageNamed: "wall")
        
        // 秒数計算
        var second: Double = Double(round((frame.size.width * 3) / ((frame.size.width + wallTexture.size().width) / 4) * 1000000000000000))
        second = second / 1000000000000000
        second = second + 4
        print(second)
        
        // 移動する距離を計算
        let movingDistance = CGFloat(frame.size.width + wallTexture.size().width + frame.size.width * 3)
        
        // 画面外まで移動するアクションを作成
        let movepoint = SKAction.moveBy(x: -movingDistance, y: 0, duration: second)
        
        // 自身を取り除くアクションを作成
        let removepoint = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let pointAnimation = SKAction.sequence([movepoint, removepoint])
        
        // pointを生成するアクションを作成
        let createpointAnimation = SKAction.run {
            // pointのノードを乗せるノードを作成
            let point = SKNode()
            point.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            
            point.zPosition = 100 // 雲より手前、地面より奥
            // ランダムレンジ作成
            let random_p_range = self.frame.size.height
            let random_po_range = self.frame.size.width
            // 0〜random rangeまでのランダム値を生成
            let random_p = CGFloat.random(in: 0..<random_p_range)
            let random_po = CGFloat.random(in: 0..<random_po_range)
            
            // pointを作成
            let points = SKSpriteNode(imageNamed: "IMG_AD2A5466ACF7-1")
            points.position = CGPoint(x: random_po, y: random_p)
            points.size=CGSize(width: points.size.width/8, height: points.size.height/8)
            
            point.addChild(points)
            
            // スプライトに物理演算を設定する
            points.physicsBody = SKPhysicsBody(rectangleOf: points.size)
            
            points.physicsBody?.categoryBitMask = self.pointCategory
            points.physicsBody?.contactTestBitMask = self.birdCategory
            // 衝突の時に動かないように設定する
            points.physicsBody?.isDynamic = false
            
            // スコアアップ用のノード
            /* let scoreNode = SKNode()
             scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
             scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
             scoreNode.physicsBody?.isDynamic = false
             scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
             scoreNode.physicsBody?.contactTestBitMask = self.birdCategory*/
            
            point.run(pointAnimation)
            
            self.pointNode.addChild(point)
        }
        
        // 次のpoint作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // pointを作成->時間待ち->pointを作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createpointAnimation, waitAnimation]))
        
        pointNode.run(repeatForeverAnimation)
    }
    
    func restart() {
        score = 0
        pointscore = 0
        scoreLabelNode.text = "Score:\(score)"
        pointLabelNode.text = "Point:\(pointscore)"
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        if wallNode != nil {
            wallNode.removeAllChildren()
            wallNode.removeAllActions()
        }
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        setupWall()
        button.removeFromParent()
        
        pointNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first as UITouch? {
            let location = touch.location(in: self)
            if self.atPoint(location).name == "button" {
                print("button tapped")
                if timelevel==4{
                timelevel = 1
                }else{
                    timelevel=4
                }
                print(timelevel)
            } else
            if scrollNode.speed > 0 {
                // 鳥の速度をゼロにする
                bird.physicsBody?.velocity = CGVector.zero
                
                // 鳥に縦方向の力を与える
                bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            } else if bird.speed == 0 {
                restart()
            }
        }
    }
    
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if contact.bodyA.categoryBitMask == scoreCategory || contact.bodyB.categoryBitMask == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            // ベストスコア更新か確認する --- ここから ---
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            } // --- ここまで追加---
            
        } else if (contact.bodyA.categoryBitMask & pointCategory) == pointCategory {
            // point用の物体と衝突した
            print("PointUp")
            pointscore += 1
            pointLabelNode.text = "Point:\(pointscore)"
            contact.bodyA.node!.removeFromParent()
            // 音がなるようにする
            audioPlayerInstance.currentTime = 0 // 再生箇所を頭に移す
            audioPlayerInstance.play() // 再生する
            // ベストpoint更新か確認する --- ここから ---
            var bestPoint = userDefaults.integer(forKey: "BestPoint")
            if pointscore > bestPoint {
                bestPoint = pointscore
                bestPointLabelNode.text = "Best Score:\(bestPoint)"
                userDefaults.set(bestPoint, forKey: "BestPoint")
                userDefaults.synchronize()
            }
            
        } else if (contact.bodyB.categoryBitMask & pointCategory) == pointCategory {
            // point用の物体と衝突した
            print("PointUp")
            pointscore += 1
            pointLabelNode.text = "Point:\(pointscore)"
            contact.bodyB.node!.removeFromParent()
            // 音がなるようにする
            audioPlayerInstance.currentTime = 0 // 再生箇所を頭に移す
            audioPlayerInstance.play() // 再生する
            // ベストpoint更新か確認する --- ここから ---
            var bestPoint = userDefaults.integer(forKey: "BestPoint")
            if pointscore > bestPoint {
                bestPoint = pointscore
                bestPointLabelNode.text = "Best Score:\(bestPoint)"
                userDefaults.set(bestPoint, forKey: "BestPoint")
                userDefaults.synchronize()
            }
        } else {
            // 壁か地面と衝突した
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(
                roll,
                completion: {
                    self.bird.speed = 0
                }
            )
            addChild(button)
        }
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    
    func setupPointLabel() {
        pointscore = 0
        pointLabelNode = SKLabelNode()
        pointLabelNode.fontColor = UIColor.black
        pointLabelNode.position = CGPoint(x: frame.size.width - 200, y: self.frame.size.height - 60)
        pointLabelNode.zPosition = 100 // 一番手前に表示する
        pointLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        pointLabelNode.text = "Point:\(pointscore)"
        self.addChild(pointLabelNode)
        
        bestPointLabelNode = SKLabelNode()
        bestPointLabelNode.fontColor = UIColor.black
        bestPointLabelNode.position = CGPoint(x: frame.size.width - 200, y: self.frame.size.height - 90)
        bestPointLabelNode.zPosition = 100 // 一番手前に表示する
        bestPointLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestpoint = userDefaults.integer(forKey: "BestPoint")
        bestPointLabelNode.text = "Best Point:\(bestpoint)"
        self.addChild(bestPointLabelNode)
    }
}

/*
 // MARK: - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
 // Get the new view controller using segue.destination.
 // Pass the selected object to the new view controller.
 }
 */
