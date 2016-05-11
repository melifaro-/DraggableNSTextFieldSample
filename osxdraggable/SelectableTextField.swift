import Foundation
import Cocoa

typealias TextFieldDidSelect = (textField: SelectableTextField) -> Void

class SelectableTextField: NSTextField {
    
    var didSelected: (TextFieldDidSelect)?
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        didSelected?(textField: self)
    }
}
