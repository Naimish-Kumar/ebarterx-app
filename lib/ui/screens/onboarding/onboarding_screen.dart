import 'package:eBarterx/app/app_theme.dart';
import 'package:eBarterx/app/routes.dart';
import 'package:eBarterx/data/cubits/system/app_theme_cubit.dart';
import 'package:eBarterx/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eBarterx/data/model/system_settings_model.dart';
import 'package:eBarterx/ui/theme/theme.dart';
import 'package:eBarterx/utils/custom_text.dart';
import 'package:eBarterx/utils/extensions/extensions.dart';
import 'package:eBarterx/utils/hive_keys.dart';
import 'package:eBarterx/utils/hive_utils.dart';
import 'package:eBarterx/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPageIndex = 0;
  double _changedOnPageScroll = 0.5;
  double _currentSwipe = 0;
  late final int _totalPages;

  final List<Map<String, String>> _slidersList = [
    {
      'svg': "assets/svg/Illustrators/onbo_a.svg",
      'title': "onboarding_1_title",
      'description': "onboarding_1_des",
    },
    {
      'svg': "assets/svg/Illustrators/onbo_b.svg",
      'title': "onboarding_2_title",
      'description': "onboarding_2_des",
    },
    {
      'svg': "assets/svg/Illustrators/onbo_c.svg",
      'title': "onboarding_3_title",
      'description': "onboarding_3_des",
    },
  ];

  @override
  void initState() {
    super.initState();
    _totalPages = _slidersList.length;
  }

  void _handleNextPage() {
    if (_currentPageIndex < _slidersList.length - 1) {
      setState(() => _currentPageIndex++);
    } else {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Routes.login, (route) => false);
    }
    HiveUtils.setUserIsNotNew();
  }

  void _handleSkip() {
    HiveUtils.setUserIsNotNew();
    HiveUtils.setUserSkip();
    Navigator.pushReplacementNamed(
      context,
      Routes.main,
      arguments: {"from": "login", "isSkipped": true},
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLanguageButton(),
                    _buildSkipButton(),
                  ],
                ),
              ),
              _buildSliderContent(),
              SizedBox(
                height: context.screenHeight * 0.1,
              ),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton() {
    return TextButton(
      onPressed: () {
        context.read<FetchSystemSettingsCubit>().fetchSettings();
        Navigator.pushNamed(context, Routes.languageListScreenRoute);
      },
      child: StreamBuilder(
        stream: Hive.box(HiveKeys.languageBox)
            .watch(key: HiveKeys.currentLanguageKey),
        builder: (context, AsyncSnapshot<BoxEvent> value) {
          final defaultLanguage = context
              .watch<FetchSystemSettingsCubit>()
              .getSetting(SystemSetting.defaultLanguage)
              ?.toString()
              .firstUpperCase();
          final languageCode =
              value.data?.value?['code'] ?? defaultLanguage ?? "En";

          return Row(
            children: [
              CustomText(
                languageCode,
                color: context.color.textColorDark,
              ),
              Icon(
                Icons.keyboard_arrow_down_sharp,
                color: context.color.territoryColor,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkipButton() {
    return MaterialButton(
      onPressed: _handleSkip,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: context.color.forthColor.withOpacity(0.102),
      elevation: 0,
      height: 28,
      minWidth: 64,
      child: CustomText(
        "skip".translate(context),
        color: context.color.forthColor,
      ),
    );
  }

  Widget _buildSliderContent() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() => _currentSwipe = details.localPosition.direction);
      },
      onHorizontalDragEnd: (_) {
        setState(() {
          if (_currentSwipe < 0.9) {
            if (_changedOnPageScroll >= 0.5 && _currentPageIndex > 0) {
              _currentPageIndex--;
              _changedOnPageScroll = 0;
            }
          } else if (_currentPageIndex < _slidersList.length - 1 &&
              _changedOnPageScroll <= 0.5) {
            _currentPageIndex++;
          }
          _changedOnPageScroll = 0.5;
        });
      },
      child: SizedBox(
        width: context.screenWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              const SizedBox(height: 80),
              SizedBox(
                width: context.screenWidth,
                height: 221,
                child:
                    SvgPicture.asset(_slidersList[_currentPageIndex]['svg']!),
              ),
              const SizedBox(height: 39),
              CustomText(
                _slidersList[_currentPageIndex]['title']!.translate(context),
                fontSize: context.font.extraLarge,
                fontWeight: FontWeight.w600,
                color: context.color.textDefaultColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: CustomText(
                  _slidersList[_currentPageIndex]['description']!
                      .translate(context),
                  textAlign: TextAlign.center,
                  fontSize: context.font.larger,
                ),
              ),
              const SizedBox(height: 24),
              IndicatorBuilder(
                total: _totalPages,
                selectedIndex: _currentPageIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _handleNextPage,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: context.color.forthColor,
          boxShadow:
              context.watch<AppThemeCubit>().state.appTheme == AppTheme.dark
                  ? null
                  : [
                      BoxShadow(
                        color: context.color.forthColor.withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_forward, color: Colors.white),
      ),
    );
  }
}

class IndicatorBuilder extends StatelessWidget {
  final int total;
  final int selectedIndex;

  const IndicatorBuilder(
      {super.key, required this.total, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: total,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, index) => Container(
          width: selectedIndex == index ? 24 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: context.color.territoryColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
