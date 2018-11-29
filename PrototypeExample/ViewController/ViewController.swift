//
//  ViewController.swift
//  PrototypeExample
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var toolbarViewController: NSView!
    @IBOutlet weak var canvasView: CanvasView!

    @IBOutlet weak var moveButton: NSButton!
    @IBOutlet weak var scaleButton: NSButton!
    @IBOutlet weak var extendButton: NSButton!
    @IBOutlet weak var pointButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var cloneButton: NSButton!
    

    @IBOutlet weak var toolbarStackView: NSStackView!

    @IBOutlet weak var shapePickerComboBox: NSComboBox!


    var selectedToolbarButton: NSButton?

    let shapeCache = ShapeCache.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        selectedToolbarButton = moveButton

        shapePickerComboBox.removeAllItems()
        let registeredShapeIDs = shapeCache.registeredShapeIDs()
        shapePickerComboBox.addItems(withObjectValues: registeredShapeIDs)

        canvasView.canvasTool = .move
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func addButtonPressed(_ sender: Any) {
        guard let shapeID = shapePickerComboBox.objectValueOfSelectedItem as? String else { return }

        if let newShape = shapeCache.newShape(id: shapeID) {
            canvasView.shapes.append(newShape)
            canvasView.setNeedsDisplay(canvasView.bounds)
        }

    }

    @IBAction func toolbarButtonPressed(_ sender: Any) {
        guard let button = sender as? NSButton else { return }
        guard selectedToolbarButton != button else { return }

        selectedToolbarButton?.state = .off
        selectedToolbarButton = button

        if selectedToolbarButton?.state == .on {
            canvasView.canvasTool = CanvasTool(rawValue: button.tag)
        }
    }
}

