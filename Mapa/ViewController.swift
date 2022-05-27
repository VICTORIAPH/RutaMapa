//
//  ViewController.swift
//  Mapa
//
//  Created by Victoria on 24/05/22.
//

import UIKit
import MapKit
import CoreLocation
class ViewController: UIViewController, UISearchBarDelegate, MKMapViewDelegate {
    
    
    @IBOutlet weak var buscadorSB: UISearchBar!
    
    @IBOutlet weak var MapaMK: MKMapView!
    
    var latitud: CLLocationDegrees?
    var longitud: CLLocationDegrees?
    var altitud: Double?
    
    //manager para hacer uso del gps
    var manager = CLLocationManager()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
          manager.delegate = self
          manager.requestWhenInUseAuthorization()
          manager.requestLocation()
        buscadorSB.delegate = self
        MapaMK.delegate = self
          
          //mejorar la precision de la ubicacion
          manager.desiredAccuracy = kCLLocationAccuracyBest
          
          //monitorear en todo momento la ubicaciuon
          manager.startUpdatingLocation()
          
          
      }

    
// trazar la ruta
    func trazarRuta(coordenasDestino: CLLocationCoordinate2D)  {
        guard let coordOrigen = manager.location?.coordinate else{
            return }
        //crear un lugar de origen - destino
        let origenPlaceMark = MKPlacemark(coordinate: coordOrigen)
        let destinoPlaceMark = MKPlacemark(coordinate: coordenasDestino)
        // crear
        let origenItem = MKMapItem(placemark: origenPlaceMark)
        let destinoItem = MKMapItem(placemark: destinoPlaceMark)
        
        //SOLICITUD DE RUTA
        let solicitudDestino = MKDirections.Request()
        solicitudDestino.source = origenItem
        solicitudDestino.destination = destinoItem
        
        //COMO DE VA TRANSLADAR EL USUARIO
        solicitudDestino.transportType = .automobile
        solicitudDestino.requestsAlternateRoutes = true
        
        let direcciones = MKDirections(request: solicitudDestino)
        direcciones.calculate {(respuesta, error) in
            guard let respuestaSegura = respuesta else {
                if let error = error {
                    print("error al calcular la ruta \(error.localizedDescription)")
                    //alerta
                    let alerta = UIAlertController(title: "Error", message: "Lugar no encontrado", preferredStyle: .alert)
                    let accionAceptar = UIAlertAction(title: "Aceptar<", style: .default, handler: nil)
                    alerta.addAction(accionAceptar)
                    self.present(alerta, animated: true)
                }
                return
            }
            
            //si todo good
            print(respuestaSegura.routes.count)
            let ruta = respuestaSegura.routes.first
            let overlays = self.MapaMK.overlays
            self.MapaMK.removeOverlays(overlays)
            // agregar al map una superposision
            self.MapaMK.addOverlay(ruta!.polyline)
            self.MapaMK.setVisibleMapRect(ruta!.polyline.boundingMapRect, animated: true)
            
        }
 
    }
    //poder agregar la superposison al map
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderizado = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderizado.strokeColor = .red
        return renderizado
    }
    


    @IBAction func ubicacionButton(_ sender: UIBarButtonItem) {
        // guard  let alt = altitud else{
          //   return
         //}
         //crear alerta
         let alerta = UIAlertController(title: "Ubicacion", message: "Las coordenas son: \(latitud ?? 0) \(longitud ?? 0) \(altitud ?? 0)", preferredStyle: .alert)
         //ponerle una accion
         let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
         //agregarle la accion creada
         alerta.addAction(accionAceptar)
         //mostrsr alert
         present(alerta, animated: true)
         
         
         //crear ubicacion del usuario
         let localizacion = CLLocationCoordinate2D(latitude: latitud!, longitude: longitud!)
         let spanMap = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
         
         let region = MKCoordinateRegion(center: localizacion, span: spanMap)
         
         MapaMK.setRegion(region, animated: true)
         //mostrat ubi del usuario
         MapaMK.showsUserLocation = true
     
    }

    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Ubicacion encontrada")
        //metodo para ocultar el teclado
        buscadorSB.resignFirstResponder()
        
        let geocoder = CLGeocoder()
        //direccion del usuario
        if let direccion = buscadorSB.text{
            geocoder.geocodeAddressString(direccion) { (places: [CLPlacemark]?, error: Error?) in
                //crear destino
                guard let destinoRuta = places?.first?.location else {return}
                
                
                if error == nil{
                    let lugar = places?.first
                    let anotacion = MKPointAnnotation()
                    anotacion.coordinate = (lugar?.location?.coordinate)!
                    anotacion.title = direccion
                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    
                    let region = MKCoordinateRegion(center: anotacion.coordinate, span: span)
                    //ir al mapa a asignarle una region
                    self.MapaMK.setRegion(region, animated: true)
                    self.MapaMK.addAnnotation(anotacion)
                    self.MapaMK.selectAnnotation(anotacion, animated: true)
                    //mandar llamar
                    self.trazarRuta(coordenasDestino: destinoRuta.coordinate)
                    
                    
                }else{
                    
                    print("Error al encontrar la direccion ")
                }
                //
            }
        }
        
    }
    
    @IBAction func deleteRuta(_ sender: UIBarButtonItem) {
    }
}
extension ViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Numero de ubicaciones \(locations.count)")
        
        guard let ubicacion = locations.first else{
            return
        }
        latitud = ubicacion.coordinate.latitude
        longitud = ubicacion.coordinate.longitude
        altitud = ubicacion.altitude
        
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener ubicacion \(error.localizedDescription)")
        //alerta
        let alerta = UIAlertController(title: "Error", message: "Lugar no encontrado", preferredStyle: .alert)
        let accionAceptar = UIAlertAction(title: "Aceptar<", style: .default)
        alerta.addAction(accionAceptar)
        present(alerta, animated: true)
    }
  
}
