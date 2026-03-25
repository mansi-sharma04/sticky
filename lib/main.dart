import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

void main(List<String> args) {
  final bool isNote = args.contains("note");

  runApp(MyApp(isNote: isNote));

  doWhenWindowReady(() {
    final win = appWindow;

    win.size = isNote ? Size(260, 260) : Size(200, 200);
    win.alignment = Alignment.center;
    win.title = "Smart Sticky";

    win.show();
  });
}

class MyApp extends StatelessWidget {
  final bool isNote;

  const MyApp({super.key, required this.isNote});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isNote ? NoteWindow() : MainApp(),
    );
  }
}

////////////////////////////////////////////////////////////
/// MAIN APP (ONLY + BUTTON)
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
/// NOTE WINDOW
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

  // ✨ POP-IN
  late AnimationController popController;
  late Animation<double> popScale;

  // 🧻 DELETE ANIMATION
  late AnimationController deleteController;
  late Animation<double> scaleDown;
  late Animation<double> fadeOut;
  late Animation<double> rotate;

  bool isDeleting = false;
  bool isHovering = false;

  @override
  void initState() {
    super.initState();

    // POP-IN
    popController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    popScale = CurvedAnimation(
      parent: popController,
      curve: Curves.elasticOut,
    );

    popController.forward();

    // DELETE
    deleteController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    scaleDown = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: deleteController, curve: Curves.easeInBack),
    );

    fadeOut = Tween(begin: 1.0, end: 0.0).animate(deleteController);

    rotate = Tween(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: deleteController, curve: Curves.easeIn),
    );
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
              child: MouseRegion(
                onEnter: (_) => setState(() => isHovering = true),
                onExit: (_) => setState(() => isHovering = false),
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
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      transform: Matrix4.identity()
                        ..scale(isHovering ? 1.05 : 1.0),
                      width: 230,
                      height: 230,
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFFF176),
                            Color(0xFFFFE082),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: Offset(5, 5),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 10,
                            offset: Offset(-3, -3),
                          ),
                        ],
                      ),

                      // CONTENT
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "✨ Note",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: deleteNote,
                                child: Icon(Icons.close, size: 18),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              maxLines: null,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Drop your thoughts...",
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
          ),
        ],
      ),
    );
  }
}