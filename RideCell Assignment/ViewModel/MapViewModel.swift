import Foundation
import MapKit
import CoreLocation

class VehichleMapViewModel {
    var vehicles: [VehichleModel] = []
    
    func fetchVehicles() {
        guard let url = Bundle.main.url(forResource: "VehiclesData", withExtension: "json") else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            vehicles = try decoder.decode([VehichleModel].self, from: data)
        } catch {
            print("Error decoding JSON: \(error)")
        }
    }
    
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to download image: \(String(describing: error))")
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                completion(image)
            }
        }
        task.resume()
    }
    
    func getVehicles() -> [VehichleModel] {
        return vehicles
    }
    
    func getVehicle(for annotation: MKAnnotation) -> VehichleModel? {
        return vehicles.first { $0.lat == annotation.coordinate.latitude && $0.lng == annotation.coordinate.longitude }
    }
    
}
