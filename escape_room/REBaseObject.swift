//
//  REBaseObject.swift
//  iOS_course_
//
//  Created by 周舒意 on 2020/1/17.
//  Copyright © 2020 周舒意. All rights reserved.
//

import RealityKit
import Foundation
import UIKit

public enum State{
    case start
    case load
    case game
    case end
}

extension Entity {
    
/// Set plane in an entity
    public func setPlane() {
        var material = SimpleMaterial()

        material.baseColor = MaterialColorParameter.color(.init(red: 0.0, green: 1.0, blue: 1.0, alpha: 0.5))
        material.roughness = MaterialScalarParameter(floatLiteral: 0.0)
        material.metallic = MaterialScalarParameter(floatLiteral: 1.0)

        let planeComponent = ModelComponent(mesh: .generatePlane(width: 1, depth: 1),
                                        materials: [material]) // Here width and depth are set to one so that we can use the scale directly as the extents of the plane.
        self.components[ModelComponent] = planeComponent
    }
    
/// Change the text in an extity
  public func setText(_ content: String){
    let textComponent: ModelComponent = ModelComponent(

        mesh: .generateText(content, extrusionDepth: 0.001, font: MeshResource.Font.systemFont(ofSize: 0.045, weight: .bold),
                          containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingHead),

        materials: [SimpleMaterial(color: .white, isMetallic: false)]
    )
     self.components[ModelComponent] = textComponent
  }

}


public class REBaseObject {
    public var myObject: HasAnchoring?
    /// All the entities in the scene are here so that all of them can be change position
    public var totalEntities: [Entity?]
    /// Entities are those to have collision boxes
    public var entities: [Entity?]
    
    init(){
        totalEntities = []
        entities = []
        myObject = nil
    }
    
    public func getRealityKitObject(where postion:SIMD3<Float>, relativeTo world: Entity) ->  HasAnchoring{
        for entity in totalEntities {
            /// Change the postion
            entity!.setPosition(postion + entity!.position, relativeTo: world)
        }
        for entity in entities{
            /// So that they can be interated with
            entity!.generateCollisionShapes(recursive: true)
        }
        return self.myObject!;
    }
    
    /// To test whether one object is on the other object
    public func onRightPlace(toCheck up: RealityKit.Entity, on base: RealityKit.Entity) -> Bool {
        let upBox = up.visualBounds(relativeTo: base)
        let baseBox = base.visualBounds(relativeTo: base)

        /// The center of the upper entity is not out of the upper entity. The upper entity is put upper of the down entity within an error of 5cm.
        if (abs(upBox.center.x - baseBox.center.x ) <=  baseBox.extents.x/2) && (abs(upBox.center.z - baseBox.center.z ) <=  baseBox.extents.z/2) && ((upBox.center.y - baseBox.center.y) -  (upBox.extents.y/2 + baseBox.extents.y/2) <= 0.05)  {
            return true
        }
        else {return false}
    }
    
    /// How the scene will interact with user
    public func getInput(){}
    
    /// The line breaks when there are 4 letters.
    public func restrictLine(_ text: String) -> String {
        var result = text
        if text.count>4 {
            let index = text.index(text.startIndex, offsetBy: 4)
            result.insert("\n", at: index)
        }
        else {
            result += "\n "
        }
        var i = 0
        while i < result.count{
            let index = result.index(text.startIndex, offsetBy: i)
            result.insert(" ", at: index)
            i += 2
        }
        return result
    }
}

public class Telephone: REBaseObject{
    private var telephone: Experience.Telephone = try! Experience.loadTelephone()
    
    override init() {
        super.init()
        myObject = telephone
        entities = [telephone.button0, telephone.button1, telephone.button2, telephone.button3, telephone.button4, telephone.button5, telephone.button6, telephone.button7, telephone.button8, telephone.button9, telephone.buttonOK, telephone.buttonDel]
        totalEntities = [telephone.tele, telephone.button0, telephone.button1, telephone.button2, telephone.button3, telephone.button4, telephone.button5, telephone.button6, telephone.button7, telephone.button8, telephone.button9, telephone.buttonOK, telephone.buttonDel, telephone.hintText, telephone.inputText, telephone.hints, telephone.error]
    }
    
    /// The notifications in telephone.actions.allActions are exactly in this order.
    private var buttons = ["ok", "0", "del", "9", "8", "7", "6", "5", "4", "3", "2", "1"]
    
    /// This can be changed, which is the key to show the hint
    private var key: String = "1234"
    /// Original input
    private var input: String = ""
    /// This cannot break line automatically
    private var hint: String = "Itly mnky\nJpn rbbt"
    
    override public func getInput() {
        
        for index in 0...11 {

            self.telephone.actions.allActions[index].onAction = { _ in
                switch index{
                case 0: /// ok button, test whether the input is right
                    if self.key == self.input {
                        self.telephone.hintText?.setText(self.hint)
                        self.telephone.notifications.hint.post()
                        self.input = ""
                        self.telephone.inputText?.setText(self.input)
                        return
                    }
                    else {
                        self.telephone.notifications.wrong.post()
                        self.input = ""
                        self.telephone.inputText?.setText(self.input)
                    }

                case 2: /// del button
                    if self.input.count > 0 {
                        self.input.removeLast()
                        self.telephone.inputText?.setText(self.restrictLine(self.input))
                    }
                default: /// other number button, the maximum input is 8 digits.
                    self.input += self.buttons[index]
                    if(self.input.count<9){                        self.telephone.inputText?.setText(self.restrictLine(self.input))
                    }
                }
            }
        }
        
    }
    
    
}

public class Food: REBaseObject{
    private var food: Experience.Food = try! Experience.loadFood()
    
    override init() {
        super.init()
        myObject = food
        totalEntities = [food.banana, food.carrot, food.donut, food.peach, food.pizza, food.potato, food.ramen, food.plateJapan, food.plateItaly, food.okButton, food.arrow]
        entities = [food.banana, food.carrot, food.donut, food.peach, food.pizza, food.potato, food.ramen, food.okButton]
    }
    
    private lazy var keys = [food.banana: food.plateItaly, food.carrot: food.plateJapan]
    private lazy var idInKey =  keys.keys
    
    /// closure will be executed once the key is inputed correctly.
    public func getInput(closure:@escaping (State) -> Void){
        self.food.actions.finish.onAction = { _ in /// get the notification
            var flag = true
            for entity in self.entities {
                if self.idInKey.contains(entity) {
                    if !self.onRightPlace(toCheck: entity!, on: self.keys[entity]!!){
                        flag = false
                            break
                    }
                }
                else {
                    for id in self.idInKey {
                        if self.onRightPlace(toCheck: entity!, on: self.keys[id]!!){
                            flag = false
                            break
                        }
                    }
                 }
            }
            if(flag){
                closure(State.end)
                return
            }
        }
    }
}

public class KeyBox: REBaseObject {
    private var keyBox: Experience.Keybox = try! Experience.loadKeybox()

    override init() {
        super.init()
        myObject = keyBox
        totalEntities = [keyBox.box, keyBox.key]
    }

    public override func getInput() {
        keyBox.notifications.gameOver.post()
    }
    
}


