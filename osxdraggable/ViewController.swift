import Cocoa

class ViewController: NSViewController {

    let textFieldWidth: CGFloat = 100
    let textFieldHeight: CGFloat = 30
    
    var currentTextField: SelectableTextField!
    var didTextFieldSelectCallback: TextFieldDidSelect!

    override func viewDidLoad() {
        super.viewDidLoad()

        didTextFieldSelectCallback = { (textField) in
            self.currentTextField = textField
        }
        
        addTextFieldAtRandomePlace()
        addTextFieldAtRandomePlace()
        
//        didTextFieldSelectCallback(textField: addTextFieldAtRandomePlace())
    }

    override func mouseDragged(theEvent: NSEvent) {
        
        NSCursor.closedHandCursor().set()
        guard let textField = currentTextField else {
            return
        }
        
        textField.frame.origin.x += theEvent.deltaX
        textField.frame.origin.y -= theEvent.deltaY
    }
    
    private func addTextFieldAtRandomePlace() -> NSButton {
        
        let viewWidth = self.view.bounds.size.width
        let viewHeight = self.view.bounds.size.height
        
        let x = CGFloat(rand() % Int32((viewWidth - textFieldWidth)))
        let y = CGFloat(rand() % Int32((viewHeight - textFieldHeight)))
        
        let button = NSButton(frame: CGRectMake(x, y, textFieldWidth, textFieldHeight))
        button.alignment = NSCenterTextAlignment
        button.bezelStyle = NSBezelStyle.RoundedBezelStyle
        self.view.addSubview(button)
        
        return button
    }
}

