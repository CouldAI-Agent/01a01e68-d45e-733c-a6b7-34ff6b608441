import 'package:flutter/material.dart';

void main() {
  runApp(const Marc21App());
}

class Marc21App extends StatelessWidget {
  const Marc21App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MARC 21 Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Marc21HomePage(),
      },
    );
  }
}

class Marc21HomePage extends StatefulWidget {
  const Marc21HomePage({super.key});

  @override
  State<Marc21HomePage> createState() => _Marc21HomePageState();
}

class _Marc21HomePageState extends State<Marc21HomePage> {
  // A sample dummy MARC21 string (simulated structure for demonstration).
  // In a real scenario, this would be loaded from a .mrc file or Z39.50 server.
  final String sampleMarc = "00716cam a2200205 a 4500001001300000003000600013005001700019008004100036020002500077020002500102040001800127050002400145082001800169100003200187245008700219260003800306300003500344\x1Eocm12345678\x1EOCoLC\x1E20010101000000.0\x1E000101s2000    nyu           000 0 eng  \x1E  \x1Fa0123456789\x1E  \x1Fa0123456780 (pbk.)\x1E  \x1FaDLC\x1FcDLC\x1E 0\x1FaPR9199.3.M3855\x1FbO64 2000\x1E00\x1Fa813/.54\x1F221\x1E1 \x1FaMartel, Yann.\x1E10\x1FaLife of Pi : \x1Fba novel / \x1FcYann Martel.\x1E  \x1FaNew York : \x1FbHarcourt, \x1Fc2000.\x1E  \x1Fa356 p. ; \x1Fc24 cm.\x1D";

  List<MarcField> parsedFields = [];
  String leader = "";

  @override
  void initState() {
    super.initState();
    _parseMarcData(sampleMarc);
  }

  void _parseMarcData(String marcData) {
    if (marcData.length < 24) return;
    
    leader = marcData.substring(0, 24);
    int length = int.tryParse(leader.substring(0, 5)) ?? 0;
    int baseAddress = int.tryParse(leader.substring(12, 17)) ?? 0;

    if (baseAddress == 0 || marcData.length < baseAddress) return;

    String directory = marcData.substring(24, baseAddress - 1);
    String data = marcData.substring(baseAddress);

    List<MarcField> fields = [];

    // Parse directory
    for (int i = 0; i < directory.length; i += 12) {
      if (i + 12 > directory.length) break;
      String tag = directory.substring(i, i + 3);
      int fieldLength = int.tryParse(directory.substring(i + 3, i + 7)) ?? 0;
      int startingPosition = int.tryParse(directory.substring(i + 7, i + 12)) ?? 0;

      if (startingPosition + fieldLength <= data.length) {
        String fieldData = data.substring(startingPosition, startingPosition + fieldLength - 1); // remove field terminator
        
        if (tag.startsWith('00')) {
          // Control field
          fields.add(MarcField(tag: tag, value: fieldData));
        } else {
          // Data field
          if (fieldData.length >= 2) {
            String ind1 = fieldData[0];
            String ind2 = fieldData[1];
            String subfieldsData = fieldData.substring(2);
            List<String> subfieldParts = subfieldsData.split('\x1F');
            List<MarcSubfield> subfields = [];
            
            for (String sf in subfieldParts) {
              if (sf.isNotEmpty) {
                subfields.add(MarcSubfield(code: sf[0], value: sf.substring(1)));
              }
            }
            fields.add(MarcField(
              tag: tag, 
              ind1: ind1, 
              ind2: ind2, 
              subfields: subfields
            ));
          }
        }
      }
    }

    setState(() {
      parsedFields = fields;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MARC 21 Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600;
          
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 800 : double.infinity),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Leader', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(leader, style: const TextStyle(fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Data Fields', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...parsedFields.map((field) => _buildFieldCard(field, context)),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildFieldCard(MarcField field, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 50,
              child: Text(
                field.tag,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
            ),
            if (!field.tag.startsWith('00')) ...[
              SizedBox(
                width: 30,
                child: Text('${field.ind1}${field.ind2}', style: const TextStyle(fontFamily: 'monospace', color: Colors.grey)),
              ),
            ],
            Expanded(
              child: field.tag.startsWith('00')
                  ? Text(field.value ?? '')
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: field.subfields.map((sf) => Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '\$${sf.code} ',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                            ),
                            TextSpan(text: sf.value),
                          ]
                        )
                      )).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarcField {
  final String tag;
  final String ind1;
  final String ind2;
  final String? value;
  final List<MarcSubfield> subfields;

  MarcField({
    required this.tag,
    this.ind1 = ' ',
    this.ind2 = ' ',
    this.value,
    this.subfields = const [],
  });
}

class MarcSubfield {
  final String code;
  final String value;

  MarcSubfield({required this.code, required this.value});
}
