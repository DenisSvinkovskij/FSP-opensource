import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.hidden});
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (hidden) {
      return const Positioned(
        top: 0,
        left: 0,
        child: SizedBox(
          width: 0,
          height: 0,
        ),
      );
    }
    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: <Widget>[
            const Spacer(),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'safe place',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SvgPicture.asset(
                    'assets/loading_marker.svg',
                    height: 30.0,
                    width: 30.0,
                    allowDrawingOutsideViewBox: true,
                  ),
                ],
              ),
            ),

            // SizedBox(
            //   height: 100,
            //   child: Image.asset('assets/loading_marker.png'),
            // ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
