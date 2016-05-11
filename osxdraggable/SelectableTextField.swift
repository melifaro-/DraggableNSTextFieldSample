import Foundation
import Cocoa

typealias TextFieldDidSelect = (textField: SelectableTextField) -> Void

class SelectableTextField: NSTextField {
    
    var didSelectCallback: (TextFieldDidSelect)?
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        didSelectCallback?(textField: self)
    }
}
