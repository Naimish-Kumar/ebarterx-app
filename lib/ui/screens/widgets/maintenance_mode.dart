import 'package:eBarterx/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eBarterx/ui/theme/theme.dart';
import 'package:eBarterx/utils/constant.dart';
import 'package:eBarterx/utils/custom_text.dart';
import 'package:eBarterx/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MaintenanceMode extends StatelessWidget {
  const MaintenanceMode({super.key});
  static Route route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return const MaintenanceMode();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            "assets/lottie/${Constant.maintenanceModeLottieFile}",
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomText("maintenanceModeMessage".translate(context),
                  color: context.color.textColorDark,
                  textAlign: TextAlign.center))
        ],
      ),
    );
  }
}
