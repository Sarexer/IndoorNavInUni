import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
// ignore: avoid_web_libraries_in_flutter
//import 'dart:html';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geojson/geojson.dart';
import 'package:geopoint/geopoint.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{
    _MyHomePageState();
    final polygons = <Polygon>[];
    final polylines = <Polyline>[];
    GoogleMapController controller;
    LatLng center = LatLng(57.145537822618124,65.58033898299504);
    bool flag = true;


    void _onMapCreated(GoogleMapController controller) {
        this.controller = controller;
    }

    @override
    void initState() {
        super.initState();
        processData();
    }

    @override
    void dispose() {
        super.dispose();
    }

    Future<void> processData() async {
        polygons.clear();
        polylines.clear();
        final data = await rootBundle.loadString('assets/polygons.geojson');
        final features = await featuresFromGeoJson(data);
        for (var feature in features.collection) {
            var geometry = feature.geometry;
            GeoSerie geoSerie;
            if(geometry is GeoJsonPolygon){
                geoSerie = geometry.geoSeries[0];
            }else if(geometry is GeoJsonLine){
                geoSerie = geometry.geoSerie;
            }
            final type = geoSerie.type;
            final points = geoSerie.geoPoints;
            if(type == GeoSerieType.polygon){
                _createPolygon(points);
            }else if(type == GeoSerieType.line){
                _createPolyline(points);
            }
        }
        _animate();
    }

    void _createPolygon(List<GeoPoint> points){
        List<LatLng> list = <LatLng>[];
        for (var point in points) {
            list.add(LatLng(point.latitude, point.longitude));
        }
        var poly = Polygon(
            polygonId: PolygonId("poly ${polygons.length+1}"),
            points: list,
            fillColor: Colors.yellow[200],
            strokeWidth: 4
        );
        setState(() {
            polygons.add(poly);
        });
    }
    void _createPolyline(List<GeoPoint> points){
        List<LatLng> list = <LatLng>[];
        for (var point in points) {
            list.add(LatLng(point.latitude, point.longitude));
        }
        var poly = Polyline(
            polylineId: PolylineId("poly ${polylines.length+1}"),
            points: list,
            width: 5,
            color: Colors.black
        );
        setState(() {
            polylines.add(poly);
        });
    }

    Future sleep() {
        return new Future.delayed(const Duration(milliseconds: 40), () => "1");
    }
    void _changePosition(LatLng newCenter) async{
        center = newCenter;
        setState(() {

        });
    }

    void _animate() async {
        final points = polylines[0].points;
        if(flag){
            for (int i =0;i<points.length-1;i++) {
                var point = points[i];
                var nextPoint = points[i+1];
                double x = point.latitude;
                double y = point.longitude;
                double vx = nextPoint.latitude - x;
                double vy = nextPoint.longitude - y;
                for(double t = 0; t < 1; t+= 0.01){
                    double nextpointX = x + vx*t;
                    double nextpointY = y + vy*t;
                    _changePosition(LatLng(nextpointX, nextpointY));
                    await sleep();
                }
            }
            flag = false;
            _animate();
        }else{
            for (int i =points.length-1;i>0;i--) {
                var point = points[i];
                var nextPoint = points[i-1];
                double x = point.latitude;
                double y = point.longitude;
                double vx = nextPoint.latitude - x;
                double vy = nextPoint.longitude - y;
                for(double t = 0; t < 1; t+= 0.01){
                    double nextpointX = x + vx*t;
                    double nextpointY = y + vy*t;
                    _changePosition(LatLng(nextpointX, nextpointY));
                    await sleep();
                }
            }
            flag = true;
            _animate();
        }


    }


    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: Stack(
              children: <Widget>[
                  GoogleMap(
                      initialCameraPosition: const CameraPosition(
                          target: LatLng(57.144905, 65.580143),
                          zoom: 18,
                      ),
                      markers: Set.of([Marker(
                          markerId: MarkerId("1"),
                          icon: BitmapDescriptor.defaultMarker,
                          position: LatLng(65.58033898299504,
                              57.145537822618124),
                      )]),
                      circles: Set.of([
                          Circle(
                              circleId: CircleId("circle 1"),
                              consumeTapEvents: true,
                              fillColor: Colors.blue,
                              strokeWidth: 4,
                              center: center,
                              radius: 1,
                              onTap: () {
                                  print("tap");
                              },
                          )
                      ]),
                      polylines: Set.of(polylines),
                      polygons: Set.of(polygons),
                      onMapCreated: _onMapCreated,
                  ),
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: IconButton(onPressed: (){_showModalSheet();},icon: Icon(Icons.keyboard_arrow_up,size: 40)),
                  )
              ],
            )
        );
    }

    generateOrders(){
        List<Widget> orders = List<Widget>();

        orders.add(ListTile(title: Text('Построить маршрут'),leading: Icon(Icons.navigation, color: Colors.blue,),
            onTap: (){
                Navigator.pop(context);
            },));

        for(int i =0;i<1;i++){
            var order = ListTile(title: Text('Забрать детали с цеха А'), subtitle: Text('Нужно взять 10 шестерней и отвезти их в цех Е'),);
            var order1 = ListTile(title: Text('Забрать детали с цеха С'), subtitle: Text('Взять в цехе С 5 труб 5 профиля и отвезти в цех В'),);
            var order2 = ListTile(title: Text('Забрать детали с цеха С'), subtitle: Text('Взять в цехе С 10 труб 3 профиля и отвезти в цех D'),);
            var order3 = ListTile(title: Text('Заказ'), subtitle: Text('Отвези вот это вот туда'),);
            var order4 = ListTile(title: Text('Заказ'), subtitle: Text('Отвези вот это вот туда'),);
            var order5 = ListTile(title: Text('Заказ'), subtitle: Text('Отвези вот это вот туда'),);
            var order6 = ListTile(title: Text('Заказ'), subtitle: Text('Отвези вот это вот туда'),);
            var divider = Container(height: 1, width: 1000,color: Colors.grey,);

            orders.add(order);
            orders.add(divider);
            orders.add(order1);
            orders.add(divider);
            orders.add(order2);
            orders.add(divider);
        }

        return orders;
    }

    void _showModalSheet() {
        showModalBottomSheet(
            context: context,
            builder: (builder) {
                return Container(
                    child: ListView(
                        children: generateOrders(),
                    ),
                );
            });
    }

    LatLng _createLatLng(double lat, double lng) {
        return LatLng(lat, lng);
    }
}