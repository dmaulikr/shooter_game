import UIKit
import SpriteKit

class GameViewController: UIViewController {
    var counter = 30
    override func viewDidLoad() {
        super.viewDidLoad()
        var _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    func updateScore(newScore: Int){
        print(newScore)
        scoreLabel.text = String(newScore)
    }
    @IBAction func Start(_ sender: UIButton) {
        let scene = GameScene(size: view.bounds.size)
        scene.viewController = self
        let skView = view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        scoreLabel.text = "0"
        startButton.isHidden = true
    }
    func updateCounter() {
        if counter > 0 {
            counter -= 1
            timerLabel.text = String(counter)
        }
    }
}
