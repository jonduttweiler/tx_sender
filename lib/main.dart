import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tx_sender/contexts/app_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: ChangeNotifierProvider(
        create: (_) => AppController(),
        child: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
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
  bool loading = false;
  double? balance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeModal();
    });
  }

  _initializeModal() async {
    final AppController appController = Provider.of<AppController>(context, listen: false);
    await appController.initializeModal(context);
    /* Set local state */
  }

  @override
  Widget build(BuildContext context) {
    final AppController appController = Provider.of<AppController>(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                await appController.connectWallet(context); //Ya debe estar conectado
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900], // Background color
                foregroundColor: Colors.white, // Text (and icon) color
              ),
              child: Text("Connect wallet"),
            ),
            SizedBox(height: 20),
            Text("Connected account: ${appController.account}", textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                var result = await appController.sendReadTransaction();
                setState(() {
                  balance = result;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900], // Background color
                foregroundColor: Colors.white, // Text (and icon) color
              ),
              child: Text("Send read transaction"),
            ),

            if(balance != null)
            Text("Balance: ${balance} USDC"),
            ElevatedButton(
              onPressed: () async {
                await appController.sendWriteTransaction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900], // Background color
                foregroundColor: Colors.white, // Text (and icon) color
              ),
              child: Text("Send write transaction"),
            ),
          ],
        ),
      ),
    );
  }
}
