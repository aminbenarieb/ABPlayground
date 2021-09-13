import Foundation

class Bird {

    // Generic Function

    func print<T>(_ v: T) { 
        print(v)
    }

    // Normal function
    final func favoriteBird() -> String {
        return "Sparrow"
    }
    
    // Functoin with @objc
    @objc func favoriteBirdObjc() -> String {
        return "Sparrow"
    }
    
    // Function with @objc & dynamic
    @objc dynamic func favoriteBirdObjcAndDynamic() -> String {
        return "Sparrow"
    }
}

extension Bird {

    @objc func someMethod() -> String {
        return "Bird: some method"
    }

}

class BirdChild: Bird {
    override func someMethod() -> String {
        return "BirdChild: some method"
    }
}

class Animal: NSObject {
    @objc func someAnimalMethod() -> String {
        return "Some string"
    }
}

let birdObj = Bird()
_ = birdObj.favoriteBird()
_ = birdObj.favoriteBirdObjc()
_ = birdObj.favoriteBirdObjcAndDynamic()
birdObj.print("S")
birdObj.print(1)

let birdChildObj = BirdChild()
print(birdChildObj.someMethod())

let animal = Animal()
print(animal.someAnimalMethod())
