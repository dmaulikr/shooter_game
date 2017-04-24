import SpriteKit
import CoreMotion

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Monster   : UInt32 = 0b1       // 1
    static let Projectile: UInt32 = 0b10      // 2
}


func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var viewController: GameViewController!
    var score = 0
    var motionManager: CMMotionManager?
    var playerScalar: Double?
    var destX:CGFloat  = 0.0
    // 1
    let player = SKSpriteNode(imageNamed: "player")
    
    // UI Lifecycle ::::::::::::::::::::::::::::::::::::::::::
    
    override func didMove(to view: SKView) {
        
        motionManager = CMMotionManager()
        
        if let manager = motionManager {
            print("We have a motion manager")
            if !manager.isDeviceMotionAvailable {
                // This will print if running on simulator
                print("We cannot detect device motion using the simulator")
            }
            else {
                // This will print if running on iPhone
                print("We can detect device motion")
                
                // Make a custom queue in order to stay off the main queue
                let myq = OperationQueue()
                
                // Customize the update interval (seconds)
                manager.deviceMotionUpdateInterval = 0.1
                
                
                // Now we can start our updates, send it to our custom queue, and define a completion handler
                manager.startDeviceMotionUpdates(to: myq, withHandler: { (motionData: CMDeviceMotion?, error: Error?) in
                    
                    if let data = motionData {
                        
                        // We access motion data via the "attitude" property
                        let attitude = data.attitude
//                        print("pitch: \(attitude.pitch) ----- roll: \(attitude.roll) ----- yaw: \(attitude.yaw)")
                        self.playerScalar = attitude.pitch
                        print(self.playerScalar!)
                        var currentX = self.player.position.x
                        
                        // 3
                        if attitude.pitch < 0 {
                            self.destX = currentX - CGFloat(attitude.pitch * 1000)
                        }
                            
                        else if attitude.pitch > 0 {
                            self.destX = currentX - CGFloat(attitude.pitch * 1000)
                        }
                    }
                    
                })
                
            }
            
            
        } else {
            print("No manager")
        }
        
        // 2
        backgroundColor = SKColor.white
        // 3
        player.position = CGPoint(x: size.width * 0.5, y: size.height * 0.1)
        // 4
        addChild(player)
        
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addMonster),
                SKAction.wait(forDuration: 3.0)
                ])
        ))
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        var action = SKAction.moveTo(x: destX, duration: 1)
        self.player.run(action)
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        
        // Create sprite
        let monster = SKSpriteNode(imageNamed: "monster")
//        
        // Determine where to spawn the monster along the X axis
        let actualX = random(min: monster.size.width/2, max: size.width - monster.size.width/2)
        
        // Position the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
//        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        monster.position = CGPoint(x: actualX, y: size.height)
        
        // Add the monster to the scene
        addChild(monster)
        
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) // 1
        monster.physicsBody?.isDynamic = true // 2
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster // 3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        let actionMove = SKAction.move(to: CGPoint(x: actualX, y: 0), duration: TimeInterval(2.0))
        let actionMoveDone = SKAction.removeFromParent()
        monster.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // 1 - Choose one of the touches to work with
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        
        // 2 - Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        addChild(projectile)
        let actionMove = SKAction.move(to: CGPoint(x: projectile.position.x, y: size.height), duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        score += 1
        print(score)
        self.viewController.updateScore(newScore: score)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
            if let monster = firstBody.node as? SKSpriteNode, let
                projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster)
            }
        }
        
    }
}
