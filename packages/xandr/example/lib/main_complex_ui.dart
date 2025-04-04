import 'package:flutter/material.dart';
import 'package:xandr/ad_banner.dart';
import 'package:xandr/ad_size.dart' show AdSize;
import 'package:xandr/load_mode.dart';
import 'package:xandr/xandr.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _XandrComplexUiExample(),
    );
  }
}

class _XandrComplexUiExample extends StatefulWidget {
  const _XandrComplexUiExample({super.key});

  @override
  State<_XandrComplexUiExample> createState() => _XandrComplexUiExampleState();
}

class _XandrComplexUiExampleState extends State<_XandrComplexUiExample> {
  final XandrController _controller = XandrController();
  late final MultiAdRequestController _multiAdRequestController;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _controller.resetController();
    _multiAdRequestController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _multiAdRequestController = MultiAdRequestController(
      controller: _controller,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async {
        // Load ads after initializing controllers
        await Future<void>.delayed(const Duration(seconds: 5));
        await _loadAds();
      },
    );
  }

  Future<bool> _initializeControllers() async {
    final result = await _controller.init(9517, testMode: true);
    debugPrint('GIAN-LOG $result');
    final result2 = await _multiAdRequestController.initWhenXandrIsReady();
    debugPrint('GIAN-LOG multi-controller: $result2');
    return true;
  }

  Future<bool> _loadAds() async {
    return _multiAdRequestController.loadAds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xandr Example - Complex UI'),
      ),
      body: FutureBuilder(
        future: _initializeControllers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CustomScrollView(
              slivers: List.generate(
                100,
                (index) {
                  if (index.isOdd) {
                    return SliverToBoxAdapter(
                      child: AdBanner(
                        controller: _controller,
                        multiAdRequestController: _multiAdRequestController,
                        loadsInBackground: true,
                        loadMode: LoadWhenCreated(),
                        key: ValueKey(index),
                        resizeWhenLoaded: true,
                        resizeAdToFitContainer: true,
                        inventoryCode: 'bunte_webdesktop_home_homepage_hor_1',
                        adSizes: const [
                          AdSize(728, 90),
                          AdSize(300, 250),
                          AdSize(300, 600),
                          AdSize(320, 480),
                        ],
                        customKeywords: const {
                          'kw': ['test-kw', 'demoads'],
                        },
                      ),
                    );
                  } else {
                    return SliverList.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return ColoredBox(
                          color: index.isEven
                              ? Colors.blueGrey
                              : Colors.grey.shade200,
                          child: ListTile(
                            title: Text(
                              'Item $index -- Lorem ipsum dolor sit amet '
                              'consectetur adipiscing elit, sed do eiusmod tempor '
                              'incididunt ut labore et dolore magna aliqua.',
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
