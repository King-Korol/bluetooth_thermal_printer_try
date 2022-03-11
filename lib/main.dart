// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  bool connected = false;
  List? availableBluetoothDevices = [];

  Future<void> getBluetooth() async {
    final bluetoothDevices = await BluetoothThermalPrinter.getBluetooths;
    print("Print $bluetoothDevices");
    setState(() {
      availableBluetoothDevices = bluetoothDevices;
    });
  }

  Future<void> setConnect(String mac) async {
    final result = await BluetoothThermalPrinter.connect(mac);
    print("state connected $result");
    if (result == "true") {
      setState(() {
        connected = true;
      });
    }
  }

  Future<void> printTicket() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      List<int> bytes = await getTicket();
      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      print("Print $result");
    } else {
      //Had Not Connected Sen
    }
  }

  Future<void> printGraphics() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      List<int> bytes = await getGraphicsTicket();
      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      print("Print $result");
    } else {
      //nle Not Connected rio
    }
  }

  Future<List<int>> getGraphicsTicket() async {
    List<int> bytes = [];

    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    // Print QR Code using native function
    bytes += generator.qrcode(
      'example.com',
      size: QRSize.Size6,
    );

    bytes += generator.hr();

    // Print Barcode using native function
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    bytes += generator.barcode(Barcode.upcA(barData));

    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> getTicket() async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    String charset = 'Cp1251';
    final image = decodeImage(base64Decode(
        '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'));
    bytes += generator.rawBytes([27, 116, 73]);
    if (image != null) {
      bytes += generator.image(image);
    }

    Uint8List ukraine = await CharsetConverter.encode(charset, "Україна");
    bytes += generator.textEncoded(ukraine,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    Uint8List someLiters = await CharsetConverter.encode(
        charset, "Ю ю Є є Ї ї І і Я я Ы ы Э э Ё ё Ъ ъ");
    bytes += generator.textEncoded(someLiters,
        styles: const PosStyles(
          align: PosAlign.center,
        ));

    bytes += generator.text('Phone number: +380938013476',
        styles: const PosStyles(
          align: PosAlign.center,
        ));
    Uint8List enCodeText =
        await CharsetConverter.encode(charset, "Телефон: +380938013476");
    bytes += generator.textEncoded(enCodeText,
        styles: const PosStyles(
          align: PosAlign.center,
        ));

    // bytes += generator.hr();
    // bytes += generator.row([
    //   PosColumn(
    //       text: 'No',
    //       width: 1,
    //       styles: PosStyles(
    //         align: PosAlign.left,
    //         bold: true,
    //         codeTable: charset,
    //       )),
    //   PosColumn(
    //       text: 'Назва',
    //       width: 5,
    //       styles: PosStyles(
    //         align: PosAlign.left,
    //         bold: true,
    //         codeTable: charset,
    //       )),
    //   PosColumn(
    //       text: 'Ціна',
    //       width: 2,
    //       styles: PosStyles(
    //         align: PosAlign.center,
    //         bold: true,
    //         codeTable: charset,
    //       )),
    //   PosColumn(
    //       text: 'Кількість',
    //       width: 2,
    //       styles: PosStyles(
    //         align: PosAlign.center,
    //         bold: true,
    //         codeTable: charset,
    //       )),
    //   PosColumn(
    //       text: 'Сума',
    //       width: 2,
    //       styles: PosStyles(
    //         align: PosAlign.right,
    //         bold: true,
    //         codeTable: charset,
    //       )),
    // ]);

    // bytes += generator.row([
    //   PosColumn(text: "1", width: 1),
    //   PosColumn(
    //       text: "Чай із пліснявою",
    //       width: 5,
    //       styles: PosStyles(
    //         align: PosAlign.left,
    //       )),
    //   PosColumn(
    //       text: "10",
    //       width: 2,
    //       styles: PosStyles(
    //         align: PosAlign.center,
    //       )),
    //   PosColumn(
    //       text: "1",
    //       width: 2,
    //       styles: PosStyles(
    //         align: PosAlign.center,
    //       )),
    //   PosColumn(
    //       text: "10",
    //       width: 2,
    //       styles: PosStyles(
    //         align: PosAlign.right,
    //       )),
    // ]);

    // bytes += generator.row([
    //   PosColumn(text: "2", width: 1),
    //   PosColumn(
    //       text: "Сода вчорашня",
    //       width: 5,
    //       styles: PosStyles(
    //         align: PosAlign.left,
    //       )),
    //   PosColumn(
    //       text: "30",
    //       width: 2,
    //       styles: PosStyles(
    //         align: PosAlign.center,
    //       )),
    //   PosColumn(
    //       text: "1",
    //       width: 2,
    //       styles: PosStyles(
    //         align: PosAlign.center,
    //       )),
    //   PosColumn(
    //       text: "30",
    //       width: 2,
    //       styles: PosStyles(
    //         align: PosAlign.right,
    //       )),
    // ]);

    // bytes += generator.row([
    //   PosColumn(text: "3", width: 1),
    //   PosColumn(
    //       text: "Masala Dose",
    //       width: 5,
    //       styles: const PosStyles(
    //         align: PosAlign.left,
    //       codeTable: 'Cp855',
    //       )),
    //   PosColumn(
    //       text: "50",
    //       width: 2,
    //       styles: const PosStyles(
    //         align: PosAlign.center,
    //       codeTable: 'Cp855',
    //       )),
    //   PosColumn(
    //       text: "1", width: 2, styles: const PosStyles(align: PosAlign.center,
    //       codeTable: 'Cp855',)),
    //   PosColumn(
    //       text: "50", width: 2, styles: const PosStyles(align: PosAlign.right,
    //       codeTable: 'Cp855',)),
    // ]);
    // bytes += generator.row([
    //   PosColumn(text: "4", width: 1),
    //   PosColumn(
    //       text: "Rov Doa",
    //       width: 5,
    //       styles: const PosStyles(
    //         align: PosAlign.left,
    //       codeTable: 'Cp855',
    //       )),
    //   PosColumn(
    //       text: "70",
    //       width: 2,
    //       styles: const PosStyles(
    //         align: PosAlign.center,
    //       codeTable: 'Cp855',
    //       )),
    //   PosColumn(
    //       text: "1", width: 2, styles: const PosStyles(align: PosAlign.center,
    //       codeTable: 'Cp855',)),
    //   PosColumn(
    //       text: "70", width: 2, styles: const PosStyles(align: PosAlign.right,
    //       codeTable: 'Cp855',)),
    // ]);

    // bytes += generator.hr();

    // bytes += generator.row([
    //   PosColumn(
    //       text: 'Всього',
    //       width: 6,
    //       styles: PosStyles(
    //         align: PosAlign.left,
    //         height: PosTextSize.size4,
    //         width: PosTextSize.size4,
    //       )),
    //   PosColumn(
    //       text: "40",
    //       width: 6,
    //       styles: PosStyles(
    //         align: PosAlign.right,
    //         height: PosTextSize.size4,
    //         width: PosTextSize.size4,
    //       )),
    // ]);

    // bytes += generator.hr(ch: '=', linesAfter: 1);

    // // ticket.feed(2);
    // bytes += generator.text('Щиро дякуємо!',
    //     styles: PosStyles(
    //       align: PosAlign.center,
    //       bold: true,
    //     ));

    // bytes += generator.text("26-11-2020 15:22:45",
    //     styles: PosStyles(
    //       align: PosAlign.center,
    //     ),
    //     linesAfter: 1);

    // bytes += generator.text(
    //     'Компанія не несе відповідальності за прострочений товар який ви купили',
    //     styles: PosStyles(
    //       align: PosAlign.center,
    //     ));
    bytes += generator.cut();
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bluetooth Thermal Printer Demo'),
        ),
        body: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Search Paired Bluetooth"),
              TextButton(
                onPressed: () {
                  getBluetooth();
                },
                child: const Text("Search"),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: (availableBluetoothDevices?.length ?? 0) > 0
                      ? availableBluetoothDevices?.length
                      : 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        String select = availableBluetoothDevices?[index];
                        List list = select.split("#");
                        // String name = list[0];
                        String mac = list[1];
                        setConnect(mac);
                      },
                      title: Text('${availableBluetoothDevices?[index]}'),
                      subtitle: const Text("Click to connect"),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: connected ? printGraphics : null,
                child: const Text("Print"),
              ),
              TextButton(
                onPressed: connected ? printTicket : null,
                child: const Text("Print Ticket"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
