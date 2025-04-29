import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:eBarterx/app/routes.dart';
import 'package:eBarterx/data/cubits/auth/auth_cubit.dart';
import 'package:eBarterx/data/cubits/auth/authentication_cubit.dart';
import 'package:eBarterx/data/cubits/slider_cubit.dart';
import 'package:eBarterx/data/cubits/system/user_details.dart';
import 'package:eBarterx/data/model/user_model.dart';
import 'package:eBarterx/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eBarterx/ui/screens/widgets/custom_text_form_field.dart';
import 'package:eBarterx/ui/theme/theme.dart';
import 'package:eBarterx/utils/app_icon.dart';
import 'package:eBarterx/utils/constant.dart';
import 'package:eBarterx/utils/custom_text.dart';
import 'package:eBarterx/utils/extensions/extensions.dart';
import 'package:eBarterx/utils/helper_utils.dart';
import 'package:eBarterx/utils/hive_utils.dart';
import 'package:eBarterx/utils/ui_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class UserProfileScreen extends StatefulWidget {
  final String from;
  final bool? navigateToHome;
  final bool? popToCurrent;
  //final AuthenticationType? type;

  const UserProfileScreen({
    super.key,
    required this.from,
    this.navigateToHome,
    this.popToCurrent,
    //required this.type,
  });

  @override
  State<UserProfileScreen> createState() => UserProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return BlurredRouter(
      builder: (_) => UserProfileScreen(
        from: arguments['from'] as String,
        popToCurrent: arguments['popToCurrent'] as bool?,
        //type: arguments['type'],
        navigateToHome: arguments['navigateToHome'] as bool?,
      ),
    );
  }
}

class UserProfileScreenState extends State<UserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final phoneController = TextEditingController();
  late final nameController = TextEditingController();
  late final emailController = TextEditingController();
  final addressController = TextEditingController();
  dynamic size;
  dynamic city, _state, country;
  double? latitude, longitude;
  String? name, email, address;
  File? fileUserimg;
  bool isNotificationsEnabled = true;
  bool isPersonalDetailShow = true;
  bool? isLoading;
  String? countryCode = "+${Constant.defaultCountryCode}";

  @override
  void initState() {
    super.initState();
    isLoading = false;

    city = HiveUtils.getCityName();
    _state = HiveUtils.getStateName();
    country = HiveUtils.getCountryName();
    latitude = HiveUtils.getLatitude();
    longitude = HiveUtils.getLongitude();

    nameController.text = (HiveUtils.getUserDetails().name) ?? "";
    emailController.text = HiveUtils.getUserDetails().email ?? "";
    addressController.text = HiveUtils.getUserDetails().address ?? "";

    if (widget.from == "login") {
      isNotificationsEnabled = true;
    } else {
      isNotificationsEnabled =
          HiveUtils.getUserDetails().notification == 1 ? true : false;
    }

    if (widget.from == "login") {
      isPersonalDetailShow = true;
    } else {
      isPersonalDetailShow =
          HiveUtils.getUserDetails().isPersonalDetailShow == 1 ? true : false;
    }

    if (HiveUtils.getCountryCode() != null) {
      countryCode = (HiveUtils.getCountryCode() != null
          ? HiveUtils.getCountryCode()!
          : "");
      phoneController.text = HiveUtils.getUserDetails().mobile != null
          ? HiveUtils.getUserDetails().mobile!.replaceFirst("+$countryCode", "")
          : "";
    } else {
      phoneController.text = HiveUtils.getUserDetails().mobile != null
          ? HiveUtils.getUserDetails().mobile!
          : "";
    }
  }

  @override
  void dispose() {
    super.dispose();
    phoneController.dispose();
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: safeAreaCondition(
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: widget.from == "login"
              ? null
              : UiUtils.buildAppBar(context, showBackButton: true),
          body: Stack(
            children: [
              ScrollConfiguration(
                behavior: RemoveGlow(),
                child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                          key: _formKey,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Align(
                                  alignment: AlignmentDirectional.center,
                                  child: buildProfilePicture(),
                                ),
                                buildTextField(
                                  context,
                                  title: "fullName",
                                  controller: nameController,
                                  validator: CustomTextFieldValidator.nullCheck,
                                ),
                                buildTextField(
                                  context,
                                  readOnly: HiveUtils.getUserDetails().type ==
                                              AuthenticationType.email.name ||
                                          HiveUtils.getUserDetails().type ==
                                              AuthenticationType.google.name ||
                                          HiveUtils.getUserDetails().type ==
                                              AuthenticationType.apple.name
                                      ? true
                                      : false,
                                  title: "emailAddress",
                                  controller: emailController,
                                  validator: CustomTextFieldValidator.email,
                                ),
                                phoneWidget(),
                                buildAddressTextField(
                                  context,
                                  title: "addressLbl",
                                  controller: addressController,
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                CustomText(
                                  "notification".translate(context),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                buildNotificationEnableDisableSwitch(context),
                                SizedBox(
                                  height: 10,
                                ),
                                CustomText(
                                  "showContactInfo".translate(context),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                buildPersonalDetailEnableDisableSwitch(context),
                                SizedBox(
                                  height: 25,
                                ),
                                UiUtils.buildButton(
                                  context,
                                  onPressed: () {
                                    if (widget.from == 'login') {
                                      validateData();
                                    } else {
                                      if (city != null && city != "") {
                                        HiveUtils.setCurrentLocation(
                                            city: city,
                                            state: _state,
                                            country: country,
                                            latitude: latitude,
                                            longitude: longitude);

                                        context
                                            .read<SliderCubit>()
                                            .fetchSlider(context);
                                      } else {
                                        HiveUtils.clearLocation();

                                        context
                                            .read<SliderCubit>()
                                            .fetchSlider(context);
                                      }
                                      validateData();
                                    }
                                  },
                                  height: 48,
                                  buttonTitle:
                                      "updateProfile".translate(context),
                                )
                              ])),
                    )),
              ),
              if (isLoading != null && isLoading!)
                Center(
                  child: UiUtils.progress(
                    normalProgressColor: context.color.territoryColor,
                  ),
                ),
              if (widget.from == 'login')
                Positioned(
                  left: 10,
                  top: 10,
                  child: BackButton(),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget phoneWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 10,
      ),
      CustomText(
        "phoneNumber".translate(context),
        color: context.color.textDefaultColor,
      ),
      SizedBox(
        height: 10,
      ),
      CustomTextFormField(
        controller: phoneController,
        validator: CustomTextFieldValidator.phoneNumber,
        keyboard: TextInputType.phone,
        isReadOnly:
            HiveUtils.getUserDetails().type == AuthenticationType.phone.name
                ? true
                : false,
        fillColor: context.color.secondaryColor,
        // borderColor: context.color.borderColor.darken(10),
        onChange: (value) {
          setState(() {});
        },
        isMobileRequired: false,
        fixedPrefix: SizedBox(
          width: 55,
          child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                onTap: () {
                  if (HiveUtils.getUserDetails().type !=
                      AuthenticationType.phone.name) {
                    showCountryCode();
                  }
                },
                child: Container(
                    // color: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 8),
                    child: Center(
                      child: CustomText(
                        formatCountryCode(countryCode!),
                        fontSize: context.font.large,
                        textAlign: TextAlign.center,
                      ),
                    )),
              )),
        ),
        hintText: "phoneNumber".translate(context),
      )
    ]);
  }

  String formatCountryCode(String countryCode) {
    if (!countryCode.startsWith('+')) {
      return '+$countryCode';
    }
    return countryCode;
  }

  Widget safeAreaCondition({required Widget child}) {
    if (widget.from == "login") {
      return SafeArea(child: child);
    }
    return child;
  }

  Widget buildNotificationEnableDisableSwitch(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
            color: context.color.textLightColor.withOpacity(0.23),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
          color: context.color.secondaryColor),
      height: 60,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CustomText(
              (isNotificationsEnabled
                      ? "enabled".translate(context)
                      : "disabled".translate(context))
                  .translate(context),
              fontSize: context.font.large,
              color: context.color.textDefaultColor,
            ),
          ),
          CupertinoSwitch(
            inactiveTrackColor: context.color.territoryColor,
            value: isNotificationsEnabled,
            onChanged: (value) {
              isNotificationsEnabled = value;
              setState(() {});
            },
          )
        ],
      ),
    );
  }

  Widget buildPersonalDetailEnableDisableSwitch(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
            color: context.color.textLightColor.withOpacity(0.23),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
          color: context.color.secondaryColor),
      height: 60,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomText(
                (isPersonalDetailShow
                        ? "enabled".translate(context)
                        : "disabled".translate(context))
                    .translate(context),
                fontSize: context.font.large,
              )),
          CupertinoSwitch(
            inactiveTrackColor: context.color.territoryColor,
            value: isPersonalDetailShow,
            onChanged: (value) {
              isPersonalDetailShow = value;
              setState(() {});
            },
          )
        ],
      ),
    );
  }

  Widget buildTextField(BuildContext context,
      {required String title,
      required TextEditingController controller,
      CustomTextFieldValidator? validator,
      bool? readOnly}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
        ),
        CustomText(
          title.translate(context),
          color: context.color.textDefaultColor,
        ),
        SizedBox(
          height: 10,
        ),
        CustomTextFormField(
          controller: controller,
          isReadOnly: readOnly,
          validator: validator,
          // formaters: [FilteringTextInputFormatter.deny(RegExp(","))],
          fillColor: context.color.secondaryColor,
        ),
      ],
    );
  }

  Widget buildAddressTextField(BuildContext context,
      {required String title,
      required TextEditingController controller,
      CustomTextFieldValidator? validator,
      bool? readOnly}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
        ),
        CustomText(title.translate(context)),
        SizedBox(
          height: 10,
        ),
        CustomTextFormField(
          controller: controller,
          maxLine: 5,
          action: TextInputAction.newline,
          isReadOnly: readOnly,
          fillColor: context.color.secondaryColor,
        ),
      ],
    );
  }

  Widget getProfileImage() {
    if (fileUserimg != null) {
      return Image.file(
        fileUserimg!,
        fit: BoxFit.cover,
      );
    } else {
      if (widget.from == "login") {
        if (HiveUtils.getUserDetails().profile != "" &&
            HiveUtils.getUserDetails().profile != null) {
          return UiUtils.getImage(
            HiveUtils.getUserDetails().profile!,
            fit: BoxFit.cover,
          );
        }

        return UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else {
        if ((HiveUtils.getUserDetails().profile ?? "").isEmpty) {
          return UiUtils.getSvg(
            AppIcons.defaultPersonLogo,
            color: context.color.territoryColor,
            fit: BoxFit.none,
          );
        } else {
          return UiUtils.getImage(
            HiveUtils.getUserDetails().profile!,
            fit: BoxFit.cover,
          );
        }
      }
    }
  }

  Widget buildProfilePicture() {
    return Stack(
      children: [
        Container(
          height: 124,
          width: 124,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: context.color.territoryColor, width: 2)),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.color.territoryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            width: 106,
            height: 106,
            child: getProfileImage(),
          ),
        ),
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: InkWell(
            onTap: showPicker,
            child: Container(
                height: 37,
                width: 37,
                alignment: AlignmentDirectional.center,
                decoration: BoxDecoration(
                    border: Border.all(
                        color: context.color.buttonColor, width: 1.5),
                    shape: BoxShape.circle,
                    color: context.color.territoryColor),
                child: SizedBox(
                    width: 15,
                    height: 15,
                    child: UiUtils.getSvg(AppIcons.edit))),
          ),
        )
      ],
    );
  }

  Future<void> validateData() async {
    if (_formKey.currentState!.validate()) {
      if (widget.from == 'login') {
        HiveUtils.setUserIsAuthenticated(true);
      }
      profileUpdateProcess();
    }
  }

  void profileUpdateProcess() async {
    if (isLoading == true) return;

    setState(() {
      isLoading = true;
    });

    try {
      var response = await context.read<AuthCubit>().updateuserdata(
            context,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            fileUserimg: fileUserimg,
            address: addressController.text,
            mobile: phoneController.text,
            notification: isNotificationsEnabled ? "1" : "0",
            countryCode: countryCode,
            personalDetail: isPersonalDetailShow ? 1 : 0,
          );

      if (response['status'] == true) {
        context
            .read<UserDetailsCubit>()
            .copy(UserModel.fromJson(response['data']));

        HelperUtils.showSnackBarMessage(
            context, response['message'] ?? "Profile updated successfully");

        if (widget.from != "login") {
          Navigator.pop(context);
        } else if (widget.popToCurrent != true) {
          if (HiveUtils.getCityName() != null &&
              HiveUtils.getCityName() != "") {
            HelperUtils.killPreviousPages(
                context, Routes.main, {"from": widget.from});
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
                Routes.locationPermissionScreen, (route) => false);
          }
        } else if (widget.popToCurrent == true) {
          Navigator.of(context)
            ..pop()
            ..pop();
        }
      } else {
        HelperUtils.showSnackBarMessage(
            context, response['message'] ?? "Failed to update profile");
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, "Error: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showPicker() {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(10)),
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: CustomText("gallery".translate(context)),
                    onTap: () {
                      _imgFromGallery(ImageSource.gallery);
                      Navigator.of(context).pop();
                    }),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: CustomText("camera".translate(context)),
                  onTap: () {
                    _imgFromGallery(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
                if (fileUserimg != null && widget.from == 'login')
                  ListTile(
                    leading: const Icon(Icons.clear_rounded),
                    title: CustomText("lblremove".translate(context)),
                    onTap: () {
                      fileUserimg = null;

                      Navigator.of(context).pop();
                      setState(() {});
                    },
                  ),
              ],
            ),
          );
        });
  }

  void _imgFromGallery(ImageSource imageSource) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: imageSource);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final sizeInBytes = await file.length();
        final sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 5) {
          HelperUtils.showSnackBarMessage(
              context, "Image size should be less than 5MB");
          return;
        }

        fileUserimg = File(pickedFile.path);
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(
          context, "Failed to pick image: ${e.toString()}");
      fileUserimg = null;
    } finally {
      setState(() {});
    }
  }

  Future<File> compressImage(File file) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      file.path,
      quality: 70,
    );
    return File(result!.path);
  }

  void showCountryCode() {
    showCountryPicker(
      context: context,
      showWorldWide: false,
      showPhoneCode: true,
      countryListTheme:
          CountryListThemeData(borderRadius: BorderRadius.circular(11)),
      onSelect: (Country value) {
        countryCode = value.phoneCode;
        setState(() {});
      },
    );
  }
}
