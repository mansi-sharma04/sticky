import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart'; // ⭐ IMPORTANT
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

void main(List<String> args) {
  final bool isNote = args.contains("note");

  runApp(MyApp(isNote: isNote));

  // ❗ Only apply window config on desktop
  if (!kIsWeb) {
    doWhenWindowReady(() {
      final win = appWindow;

      win.size = isNote ? Size(260, 260) : Size(200, 200);
      win.alignment = Alignment.center;
      win.title = "Smart Sticky";

      win.show();
    });
  }
}

class MyApp extends StatelessWidget {
  final bool isNote;

  const MyApp({super.key, required this.isNote});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🌐 WEB → single page UI
      // 💻 WINDOWS → old behavior
      home: kIsWeb
          ? WebNotesScreen()
          : (isNote ? NoteWindow() : MainApp()),
    );
  }
}

////////////////////////////////////////////////////////////
/// 🌐 WEB VERSION (Single Screen Notes)
////////////////////////////////////////////////////////////

class WebNotesScreen extends StatefulWidget {
  @override
  _WebNotesScreenState createState() => _WebNotesScreenState();
}

class _WebNotesScreenState extends State<WebNotesScreen> {
  List<Offset> positions = [];
  List<TextEditingController> controllers = [];

  void addNote() {
    setState(() {
      positions.add(Offset(100, 100));
      controllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        onPressed: addNote,
        child: Icon(Icons.add),
      ),
      body: Stack(
        children: List.generate(positions.length, (index) {
          return Positioned(
            left: positions[index].dx,
            top: positions[index].dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  positions[index] += details.delta;
                });
              },
              child: Container(
                width: 220,
                height: 220,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow[200],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 15,
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: TextField(
                  controller: controllers[index],
                  maxLines: null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Write note...",
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 💻 WINDOWS MAIN APP
////////////////////////////////////////////////////////////

class MainApp extends StatelessWidget {
  void openNote() {
    Process.start(
      Platform.resolvedExecutable,
      ['note'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurpleAccent,
        onPressed: openNote,
        child: Icon(Icons.add),
      ),
      body: Container(),
    );
  }
}

////////////////////////////////////////////////////////////
/// 💻 WINDOWS NOTE WINDOW (UNCHANGED)
////////////////////////////////////////////////////////////

class NoteWindow extends StatefulWidget {
  @override
  _NoteWindowState createState() => _NoteWindowState();
}

class _NoteWindowState extends State<NoteWindow>
    with TickerProviderStateMixin {
  double x = 50;
  double y = 50;

  TextEditingController controller = TextEditingController();

  late AnimationController popController;
  late Animation<double> popScale;

  late AnimationController deleteController;
  late Animation<double> scaleDown;
  late Animation<double> fadeOut;
  late Animation<double> rotate;

  bool isDeleting = false;
  bool isHovering = false;

  @override
  void initState() {
    super.initState();

    popController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    popScale = CurvedAnimation(
      parent: popController,
      curve: Curves.elasticOut,
    );

    popController.forward();

    deleteController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    scaleDown = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: deleteController, curve: Curves.easeInBack),
    );

    fadeOut = Tween(begin: 1.0, end: 0.0).animate(deleteController);

    rotate = Tween(begin: 0.0, end: 0.5).animate(deleteController);
  }

  @override
  void dispose() {
    popController.dispose();
    deleteController.dispose();
    super.dispose();
  }

  void deleteNote() async {
    setState(() => isDeleting = true);
    await deleteController.forward();
    appWindow.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            left: x,
            top: y,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  x += details.delta.dx;
                  y += details.delta.dy;
                });
              },
              child: ScaleTransition(
                scale: popScale,
                child: AnimatedBuilder(
                  animation: deleteController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: isDeleting ? fadeOut.value : 1,
                      child: Transform.rotate(
                        angle: isDeleting ? rotate.value : 0,
                        child: Transform.scale(
                          scale: isDeleting ? scaleDown.value : 1,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 230,
                    height: 230,
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text("✨ Note"),
                            GestureDetector(
                              onTap: deleteNote,
                              child: Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
