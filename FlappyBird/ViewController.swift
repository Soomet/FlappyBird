//
//  ViewController.swift
//  FlappyBird
//
//  Created by Sumit Joshi on 10/11/16.
//  Copyright © 2016 soomet. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     
        //change the style to the SKView
        let skView = self.view as! SKView
        
        //display the FPS
        skView.showsFPS = true
        
        //display the number of the nodes
        skView.showsNodeCount = true
        
        //create the scene with same size as view
        let scene = GameScene(size:skView.frame.size)
        
        //display the scene on the view
        skView.presentScene(scene)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //ステータスバーを消すーーーーここからーーーー
    override func prefersStatusBarHidden() -> Bool {
        return true
    }  
}

