import 'package:flutter/material.dart';
import 'package:brilliant_ble/brilliant_ble.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brilliant Ble Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Brilliant Ble Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late String _dataReceived="";
  TextEditingController _controller = TextEditingController();
  late BrilliantBle? ble;
  late String _connected="Disconnected";
  Future<void> _initBle() async {
    
    ble = await BrilliantBle.create();
    ble!.onConnected = () {
      _connected = "Connected";
      setState(() {
        
      });
    };
    ble!.onDisconnected = () {
      _connected = "Disconnected";
      setState(() {
        
      });
    };
    ble!.onData = (data) {
      _dataReceived = _dataReceived+String.fromCharCodes(data);
      setState(() {
        
      });
    };
    await ble!.setup();
    print(ble!.device!.advName);

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(widget.title),
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: SingleChildScrollView(
          child: Column(
        
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  // color: Colors.grey[300],
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: SingleChildScrollView(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text( _dataReceived,
                        style: const TextStyle(fontSize: 15.0, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  controller: _controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Type and send',
                ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row( 
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    ElevatedButton(
                       style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      onPressed: () async {
                        if (_connected=="Connected"){
                          await ble!.disconnect();
                        }else{
                          await ble!.connect();
                        }
                      },
                      child:  _connected=='Connected'?const Icon(Icons.bluetooth_connected_sharp, color: Colors.green,):const Icon(Icons.bluetooth_disabled_sharp, color: Colors.red,)
                    ),
                    ElevatedButton(
                       style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      onPressed: ()async {
                        await _initBle();
                      }, 
                      child: const Icon(Icons.refresh_sharp, color: Colors.white,)
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      onPressed: (){  
                        _dataReceived="";
                        setState(() {
                          
                        });

                    }, child: const Icon(Icons.delete_sharp, color: Colors.white,),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      onPressed: () async {
                        
                        if (ble !=null && await ble!.isConnected()){
                          var data = await ble!.sendData("${_controller.text}\n\r");
                          print(data);
                          _controller.clear();
                        }
                        
                      },
                      
                      child: const Icon(
                        Icons.upload_sharp,
                        color: Colors.white,
                      )
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
