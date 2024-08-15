import UIKit
import MapKit

class ViewController: UIViewController {
    @IBOutlet private weak var VehicleDetailView: UIView!
    @IBOutlet private weak var VehicleCollectionView: UICollectionView!
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var cabDetailViewHeight: NSLayoutConstraint!
    private var viewModel: VehichleMapViewModel = VehichleMapViewModel()
    private var selectedAnnotation: MKAnnotation? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpCollectionView()
        self.setUpMapView()
        self.viewModel.fetchVehicles()
        self.addVehicleAnnotations()
        self.setUpView()
    }
    
    @IBAction private func cancelButton(_ sender: UIButton) {
        self.cabDetailViewHeight.constant = 0
        UIView.animate(withDuration: 1) {
            self.view.layoutIfNeeded()
        }
        self.mapView.deselectAnnotation(self.selectedAnnotation, animated: true)
    }
    
    // MARK :- METHODS
    
    private func setUpCollectionView() {
        self.VehicleCollectionView.dataSource = self
        self.VehicleCollectionView.delegate = self
        self.VehicleCollectionView.register(UINib(nibName: "VehicleCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "VehicleCollectionViewCell")
    }
    
    private func zoomToVehicleLocation(vehicle: VehichleModel) {
        guard let latitude = vehicle.lat, let longitude = vehicle.lng else { return }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    private func setUpMapView() {
        self.mapView.delegate = self
    }
    
    private func setUpView() {
        if let firstVehicle = viewModel.getVehicles().first {
                zoomToVehicleLocation(vehicle: firstVehicle)
            }
        self.cabDetailViewHeight.constant = 0
        UIView.animate(withDuration: 1) {
            self.view.layoutIfNeeded()
        }
        self.VehicleCollectionView.isPagingEnabled = true
    }
    
    private func addVehicleAnnotations() {
        for vehicle in viewModel.getVehicles() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: vehicle.lat ?? 0, longitude: vehicle.lng ?? 0)
            annotation.title = vehicle.licensePlateNumber
            mapView.addAnnotation(annotation)
        }
    }
    
}

// MARK :- CollectionView Data Source and delegates

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.vehicles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VehicleCollectionViewCell", for: indexPath) as? VehicleCollectionViewCell else {return UICollectionViewCell() }
        if let url = URL(string: viewModel.vehicles[indexPath.item].vehiclePicAbsoluteURL) {
            cell.cabImageView.image = nil
            self.viewModel.downloadImage(from: url) { image in
            cell.cabImageView.image = image
        }
        }
        cell.carNameLabel.text = self.viewModel.vehicles[indexPath.item].vehicleType
        cell.vehicleNumber.text = self.viewModel.vehicles[indexPath.item].licensePlateNumber
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.bounds.width, height: 250)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vehicle = viewModel.vehicles[indexPath.item]
        zoomToVehicleLocation(vehicle: vehicle)
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: vehicle.lat ?? 0, longitude: vehicle.lng ?? 0)
        annotation.title = vehicle.licensePlateNumber
        self.mapView.selectedAnnotations = [annotation]
    }
}

// MARK :- MapKit Delegate
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        self.selectedAnnotation = annotation
        if let vehicle = viewModel.getVehicle(for: annotation) {
            self.cabDetailViewHeight.constant = 250
            UIView.animate(withDuration: 1) {
                self.view.layoutIfNeeded()
            }
            for (index,selectedVehiclee) in viewModel.vehicles.enumerated() {
                if selectedVehiclee.lat == vehicle.lat && selectedVehiclee.lng == vehicle.lng {
                    self.VehicleCollectionView.isPagingEnabled = false
                    self.VehicleCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
                    self.VehicleCollectionView.isPagingEnabled = true
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let identifier = "VehicleAnnotationView"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.image = UIImage(named: "taxiLocation")?.withRenderingMode(.alwaysTemplate)
            annotationView?.contentMode = .scaleAspectFit
            annotationView?.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
}
