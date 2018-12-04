import Cocoa
// A bunch of functions that read from weird system APIs

struct CocoaHelper {
    
    static func setWindowPosition(element: AXUIElement, attribute: NSAccessibility.Attribute, value: NSPoint) {
        let pointer = UnsafeMutablePointer<NSPoint>.allocate(capacity: 1)
        pointer.pointee = value
        guard let axValue = AXValueCreate(.cgPoint, pointer) else { return }
        AXUIElementSetAttributeValue(element, NSAccessibility.Attribute.position.rawValue as CFString, axValue)
    }
    
    static func getWindowAt(point: NSPoint) -> AXUIElement? {
        guard let element = getElementAtPosition(point: point) else { return nil }
        guard let elementRole = getAttribute(element: element, attribute: NSAccessibility.Attribute.role) as? String else { return nil }
        if elementRole == NSAccessibility.Role.window.rawValue {
            // The element is a window, so return that
            return element
        } else {
            // The element is not a window. Let's find it's parent window
            let attributeValueMaybe = getAttribute(element: element, attribute: NSAccessibility.Attribute.window)
            guard let attributeValue = attributeValueMaybe else { return nil }
            let window = attributeValue as! AXUIElement
            return window
        }
    }
    
    static func getWindowPosition(window: AXUIElement) -> NSPoint? {
        guard let positionValue = getAttribute(element: window, attribute: NSAccessibility.Attribute.position, type: .cgPoint) else {
            return nil
        }
        
        var position = CGPoint()
        AXValueGetValue(positionValue, .cgPoint, &position)
        return position
    }
    
    static func getMousePosition() -> NSPoint {
        var mousePosition = NSEvent.mouseLocation
        // flip Y coordinate, because it's different for window for some reason.
        mousePosition.y = NSScreen.main!.frame.height - mousePosition.y
        return mousePosition
    }
    
    private static func getElementAtPosition(point: NSPoint) -> AXUIElement? {
        var elementMaybe: AXUIElement?
        let getElementResult = AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), Float(point.x), Float(point.y), &elementMaybe)
        guard getElementResult == .success else { return nil }
        return elementMaybe
    }
    
    private static func getAttribute(element: AXUIElement, attribute: NSAccessibility.Attribute) -> AnyObject? {
        var valueMaybe: AnyObject?
        let getAttributeResult = AXUIElementCopyAttributeValue(element, attribute.rawValue as CFString, &valueMaybe)
        guard getAttributeResult == .success else { return nil }
        return valueMaybe
    }
    
    private static func getAttribute(element: AXUIElement, attribute: NSAccessibility.Attribute, type: AXValueType) -> AXValue? {
        guard CFGetTypeID(element) == AXUIElementGetTypeID() else {
            return nil
        }
        
        var result: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &result) == .success else {
            return nil
        }
        
        let value = result as! AXValue
        guard AXValueGetType(value) == type else {
            return nil
        }
        
        return value
    }
}
