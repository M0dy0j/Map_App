import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class Home_Screen extends StatefulWidget {
  @override
  State<Home_Screen> createState() => _Home_ScreenState();
}

class _Home_ScreenState extends State<Home_Screen> {
  // start Polyline
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = "AIzaSyBrNumUznzvo_bHnYPhcJjy0T9b7AG7C7k";
  // End Polyline

  LatLng? _center;
  LatLng? dest;
  GoogleMapController? gmc;
  Set<Marker>? myMarkers;
  MarkerId? _selectedMarker;
  StreamSubscription<Position>? positionStream;

  Future getPermission() async {
    bool services;
    LocationPermission permission;
    services = await Geolocator.isLocationServiceEnabled();
    if (!services) {
      AwesomeDialog(
              context: context,
              title: "Services",
              desc: 'ss',
              body: const Text("Services Not Enabled"))
          .show();
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
      myMarkers = {
        Marker(
          markerId: const MarkerId('current-location'),
          position: _center!,
          infoWindow: const InfoWindow(
            title: 'Current Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      };
    });
  }

  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  @override
  void initState() {
    super.initState();
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position? position) {
      changeMarker(position!.latitude, position.longitude);
    });
    _getPolyline();
    getPermission();
    _getCurrentLocation();
  }

  changeMarker(newlat, newlong) {
    _center = LatLng(newlat, newlong);
    myMarkers!.remove(Marker(markerId: MarkerId('current-location')));
    myMarkers!.add(Marker(
      markerId: MarkerId('current-location'),
      position: LatLng(newlat, newlong),
      infoWindow: const InfoWindow(
        title: 'Current Location',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      ),
    ));
    gmc!.animateCamera(CameraUpdate.newLatLng(LatLng(newlat, newlong)));
    setState(() {});
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
              child: Stack(
                children: [
                  GoogleMap(
                    // myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _center!,
                      zoom: 15,
                    ),
                    onMapCreated: (GoogleMapController controller) =>
                        gmc = controller,
                    onTap: (LatLng latLng) async {
                      dest = latLng;
                      setState(() {
                        if (_selectedMarker != null) {
                          myMarkers = myMarkers!.map((marker) {
                            if (marker.markerId == _selectedMarker) {
                              return marker.copyWith(
                                positionParam:
                                    LatLng(latLng.latitude, latLng.longitude),
                              );
                            } else {
                              return marker;
                            }
                          }).toSet();
                          _selectedMarker = null;
                        } else {
                          Marker marker = Marker(
                            markerId: const MarkerId('destination'),
                            position: latLng,
                            infoWindow: const InfoWindow(
                              title: 'Destination',
                              snippet: 'Marker snippet',
                            ),
                            icon: BitmapDescriptor.defaultMarker,
                          );
                          myMarkers!.add(marker);
                        }
                      });
                      List<Placemark> placemarks =
                          await placemarkFromCoordinates(
                              latLng.latitude, latLng.longitude);
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.noHeader,
                        animType: AnimType.leftSlide,
                        autoHide: const Duration(seconds: 5),
                        headerAnimationLoop: false,
                        body: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Country : ${placemarks[0].country}\n'
                              'AdministrativeArea : ${placemarks[0].administrativeArea}\n'
                              'Locality : ${placemarks[0].locality}\n'
                              'Street : ${placemarks[0].street}\n'),
                        ),
                      ).show();
                    },
                    markers: myMarkers!,
                    polylines: Set<Polyline>.of(polylines.values),
                  ),
                  Container(
                    alignment: AlignmentDirectional.topEnd,
                    margin: const EdgeInsets.only(
                      right: 20,
                    ),
                    padding: const EdgeInsets.all(7),
                    child: MaterialButton(
                      onPressed: () async {
                        gmc!.animateCamera(CameraUpdate.newLatLng(_center!));
                      },
                      color: Colors.black.withGreen(60).withOpacity(0.6),
                      child: const Text(
                        'My location',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Container(
                    alignment: AlignmentDirectional.topEnd,
                    margin: EdgeInsets.only(top: 40, right: 10),
                    padding: const EdgeInsets.all(7),
                    child: MaterialButton(
                      onPressed: () async {
                        LatLng latLong = LatLng(50.85045, 4.34878);
                        gmc!.animateCamera(
                            CameraUpdate.newCameraPosition(CameraPosition(
                          target: latLong,
                          zoom: 12,
                        )));
                      },
                      color: Colors.black.withGreen(60).withOpacity(0.6),
                      child: const Text(
                        'Go to Bruxelles',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.red, points: polylineCoordinates,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey,
        PointLatLng(_center!.latitude, _center!.longitude),
        PointLatLng(dest!.latitude, dest!.longitude),
        travelMode: TravelMode.driving,
        wayPoints: [PolylineWayPoint(location: "Sabo, Yaba Lagos Nigeria")]);
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    _addPolyLine();
  }

}
