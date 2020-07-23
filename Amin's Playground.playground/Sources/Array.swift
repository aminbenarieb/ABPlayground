import Foundation

public extension Array {
    
    static func array_double(from file: String, delimeter: String = ",") throws -> [Double] {
        let fileURL = Bundle.main.url(forResource: file, withExtension: nil)
        let content = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
        let text = content.components(separatedBy: delimeter)
        let numbers = text.compactMap { Double($0) }
        return numbers
    }
    
    static func array_complex_double(from file: String, delimeter: String = ",") throws -> ([Double], [Double]) {
        let fileURL = Bundle.main.url(forResource: file, withExtension: nil)
        let content = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
        let text = content.components(separatedBy: delimeter)
        var realParts = [Double]()
        var imagParts = [Double]()
        text.forEach {
            let cmpx = $0.components(separatedBy: " ")
            guard let real = Double(cmpx[0]), let imag =  Double(cmpx[1]) else {
                return
            }
            realParts.append(real)
            imagParts.append(imag)
        }
        
        return (realParts, imagParts)
    }
    
}
