import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// Tagline shown under the logo on splash and login
  ///
  /// In th, this message translates to:
  /// **'เพื่อนเดินทางที่คอยดูแลคุณ'**
  String get appTagline;

  /// Login screen heading
  ///
  /// In th, this message translates to:
  /// **'ยินดีต้อนรับสู่ AseanGo'**
  String get loginWelcomeTitle;

  /// Login screen subheading
  ///
  /// In th, this message translates to:
  /// **'เพื่อนเดินทางที่คอยดูแลคุณ ไปเที่ยวด้วยกันนะ'**
  String get loginWelcomeSubtitle;

  /// Register form display name field label
  ///
  /// In th, this message translates to:
  /// **'ชื่อที่แสดง'**
  String get displayNameLabel;

  /// Validation error when display name is empty
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกชื่อนะ'**
  String get displayNameValidator;

  /// Username field label
  ///
  /// In th, this message translates to:
  /// **'ชื่อผู้ใช้'**
  String get usernameLabel;

  /// Validation error for invalid username format/length
  ///
  /// In th, this message translates to:
  /// **'ชื่อผู้ใช้ต้องมี 3-30 ตัวอักษร (ใช้ได้แค่ตัวอักษร ตัวเลข และขีดล่าง)'**
  String get usernameValidator;

  /// Login screen combined username-or-email field label
  ///
  /// In th, this message translates to:
  /// **'ชื่อผู้ใช้หรืออีเมล'**
  String get usernameOrEmailLabel;

  /// Validation error when the login identifier field is empty
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกชื่อผู้ใช้หรืออีเมล'**
  String get usernameOrEmailRequiredValidator;

  /// Email field label
  ///
  /// In th, this message translates to:
  /// **'อีเมล'**
  String get emailLabel;

  /// Validation error when email field is empty
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกอีเมล'**
  String get emailRequiredValidator;

  /// Validation error for invalid email format
  ///
  /// In th, this message translates to:
  /// **'กรอกอีเมลให้ถูกต้องด้วยนะ'**
  String get emailValidator;

  /// Password field label
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่าน'**
  String get passwordLabel;

  /// Validation error for password too short (used on signup)
  ///
  /// In th, this message translates to:
  /// **'อย่างน้อย 8 ตัวอักษรนะ'**
  String get passwordValidator;

  /// Validation error when password field is empty (used on login, which only checks presence, not length)
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกรหัสผ่าน'**
  String get passwordRequiredValidator;

  /// Register submit button label
  ///
  /// In th, this message translates to:
  /// **'สมัครสมาชิกเลย'**
  String get registerSubmit;

  /// Login submit button label
  ///
  /// In th, this message translates to:
  /// **'มาเที่ยวด้วยกันนะ'**
  String get loginSubmit;

  /// Link shown in register mode to switch to login
  ///
  /// In th, this message translates to:
  /// **'มีบัญชีอยู่แล้ว? เข้าสู่ระบบเลย'**
  String get switchToLogin;

  /// Link shown in login mode to switch to register
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีบัญชีใช่ไหม? สมัครกันเถอะ'**
  String get switchToRegister;

  /// Fallback error message when login fails with no specific backend message
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบไม่สำเร็จ ลองใหม่อีกทีนะ'**
  String get loginFailedFallback;

  /// Fallback error message when registration fails with no specific backend message
  ///
  /// In th, this message translates to:
  /// **'สมัครสมาชิกไม่สำเร็จ ลองใหม่อีกทีนะ'**
  String get registerFailedFallback;

  /// Remember-me checkbox label on login screen
  ///
  /// In th, this message translates to:
  /// **'จำฉันไว้'**
  String get rememberMeLabel;

  /// Forgot password link on login screen
  ///
  /// In th, this message translates to:
  /// **'ลืมรหัสผ่าน?'**
  String get forgotPasswordLink;

  /// Confirm password field label on signup screen
  ///
  /// In th, this message translates to:
  /// **'ยืนยันรหัสผ่าน'**
  String get confirmPasswordLabel;

  /// Validation error when confirm password doesn't match password
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านไม่ตรงกัน'**
  String get confirmPasswordMismatch;

  /// Signup screen app bar title
  ///
  /// In th, this message translates to:
  /// **'สมัครสมาชิก'**
  String get signupTitle;

  /// Signup screen heading
  ///
  /// In th, this message translates to:
  /// **'สร้างบัญชีใหม่'**
  String get signupHeading;

  /// Signup screen subheading
  ///
  /// In th, this message translates to:
  /// **'มาเริ่มการผจญภัยไปด้วยกันนะ'**
  String get signupSubheading;

  /// Forgot password screen app bar title
  ///
  /// In th, this message translates to:
  /// **'ลืมรหัสผ่าน'**
  String get forgotPasswordTitle;

  /// Forgot password screen heading
  ///
  /// In th, this message translates to:
  /// **'ลืมรหัสผ่านใช่ไหม?'**
  String get forgotPasswordHeading;

  /// Forgot password screen instructions text
  ///
  /// In th, this message translates to:
  /// **'กรอกอีเมลที่ใช้สมัครไว้ เราจะส่งลิงก์สำหรับตั้งรหัสผ่านใหม่ให้นะ'**
  String get forgotPasswordInstructions;

  /// Forgot password screen submit button label
  ///
  /// In th, this message translates to:
  /// **'ส่งลิงก์ตั้งรหัสผ่านใหม่'**
  String get forgotPasswordSubmitButton;

  /// Message shown when forgot-password is submitted but the backend doesn't support it yet
  ///
  /// In th, this message translates to:
  /// **'ฟีเจอร์นี้ยังไม่พร้อมใช้งานตอนนี้นะ กรุณาติดต่อทีมงานเพื่อขอความช่วยเหลือ'**
  String get forgotPasswordNotAvailable;

  /// Message shown after submitting forgot-password email, before entering the reset code
  ///
  /// In th, this message translates to:
  /// **'ถ้าอีเมลนี้ลงทะเบียนไว้ เราได้ส่งรหัส 6 หลักไปให้แล้วนะ'**
  String get forgotPasswordCodeSentMessage;

  /// Error message shown when the forgot-password request fails (network/server error)
  ///
  /// In th, this message translates to:
  /// **'ส่งรหัสรีเซ็ตไม่สำเร็จ ลองใหม่อีกทีนะ'**
  String get forgotPasswordRequestFailed;

  /// Heading on the reset-password step (step 2 of forgot password flow)
  ///
  /// In th, this message translates to:
  /// **'กรอกรหัสที่ได้รับ'**
  String get resetPasswordHeading;

  /// Instructions on the reset-password step, includes the email address the code was sent to
  ///
  /// In th, this message translates to:
  /// **'กรอกรหัส 6 หลักที่เราส่งไปที่ {email} แล้วตั้งรหัสผ่านใหม่'**
  String resetPasswordInstructions(String email);

  /// Reset code text field label
  ///
  /// In th, this message translates to:
  /// **'รหัสรีเซ็ต'**
  String get resetPasswordCodeLabel;

  /// Validation error when reset code field is empty or not 6 digits
  ///
  /// In th, this message translates to:
  /// **'กรอกรหัส 6 หลักจากอีเมลของคุณ'**
  String get resetPasswordCodeValidator;

  /// New password text field label on reset-password step
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านใหม่'**
  String get resetPasswordNewPasswordLabel;

  /// Submit button label on reset-password step
  ///
  /// In th, this message translates to:
  /// **'รีเซ็ตรหัสผ่าน'**
  String get resetPasswordSubmitButton;

  /// Message shown after successfully resetting the password
  ///
  /// In th, this message translates to:
  /// **'รีเซ็ตรหัสผ่านสำเร็จแล้ว กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่'**
  String get resetPasswordSuccessMessage;

  /// Fallback error message when reset-password fails with no specific backend message
  ///
  /// In th, this message translates to:
  /// **'รีเซ็ตรหัสผ่านไม่สำเร็จ ตรวจสอบรหัสแล้วลองใหม่อีกทีนะ'**
  String get resetPasswordFailedFallback;

  /// Link to resend the reset code on the reset-password step
  ///
  /// In th, this message translates to:
  /// **'ไม่ได้รับรหัสใช่ไหม? ส่งอีกครั้ง'**
  String get resetPasswordResendCode;

  /// Snackbar shown after successfully resending the reset code
  ///
  /// In th, this message translates to:
  /// **'ส่งรหัสใหม่แล้วนะ'**
  String get resetPasswordResendSuccess;

  /// Link back to login screen
  ///
  /// In th, this message translates to:
  /// **'กลับไปหน้าเข้าสู่ระบบ'**
  String get backToLoginLink;

  /// Google social login button label
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบด้วย Google'**
  String get continueWithGoogle;

  /// Facebook social login button label
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบด้วย Facebook'**
  String get continueWithFacebook;

  /// Google social sign-up button label
  ///
  /// In th, this message translates to:
  /// **'สมัครสมาชิกด้วย Google'**
  String get signUpWithGoogle;

  /// Facebook social sign-up button label
  ///
  /// In th, this message translates to:
  /// **'สมัครสมาชิกด้วย Facebook'**
  String get signUpWithFacebook;

  /// Divider text between email form and social login buttons
  ///
  /// In th, this message translates to:
  /// **'หรือ'**
  String get orDivider;

  /// Fallback error message when social login fails with no specific backend message
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบไม่สำเร็จ ลองใหม่อีกทีนะ'**
  String get socialLoginFailedFallback;

  /// Password strength indicator label: weak
  ///
  /// In th, this message translates to:
  /// **'อ่อน'**
  String get passwordStrengthWeak;

  /// Password strength indicator label: medium
  ///
  /// In th, this message translates to:
  /// **'ปานกลาง'**
  String get passwordStrengthMedium;

  /// Password strength indicator label: strong
  ///
  /// In th, this message translates to:
  /// **'แข็งแรง'**
  String get passwordStrengthStrong;

  /// Text before the terms-of-service link in the agreement checkbox
  ///
  /// In th, this message translates to:
  /// **'ฉันยอมรับ'**
  String get termsAgreementPrefix;

  /// Terms of service link label
  ///
  /// In th, this message translates to:
  /// **'ข้อกำหนดการให้บริการ'**
  String get termsOfServiceLink;

  /// Validation message shown when submitting signup without accepting terms
  ///
  /// In th, this message translates to:
  /// **'กรุณายอมรับข้อกำหนดการให้บริการก่อนนะ'**
  String get termsAgreementRequired;

  /// Terms of service screen app bar title
  ///
  /// In th, this message translates to:
  /// **'ข้อกำหนดการให้บริการ'**
  String get termsOfServiceTitle;

  /// Placeholder body text on the terms of service screen until real legal copy is written
  ///
  /// In th, this message translates to:
  /// **'เนื้อหาข้อกำหนดการให้บริการฉบับเต็มจะประกาศให้ทราบเร็ว ๆ นี้'**
  String get termsOfServicePlaceholder;

  /// Prompt text before the sign-up link on login screen
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีบัญชีใช่ไหม?'**
  String get noAccountYetPrompt;

  /// Prompt text before the log-in link on signup screen
  ///
  /// In th, this message translates to:
  /// **'มีบัญชีอยู่แล้ว?'**
  String get haveAccountPrompt;

  /// Plain 'Log in' link label (as opposed to loginSubmit's adventurous CTA phrasing)
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบ'**
  String get logInLinkLabel;

  /// Generic retry button label used across empty/error states
  ///
  /// In th, this message translates to:
  /// **'ลองใหม่อีกครั้ง'**
  String get retryLabel;

  /// Language settings screen title
  ///
  /// In th, this message translates to:
  /// **'การตั้งค่าภาษา'**
  String get languageSettingsTitle;

  /// Follow-system-locale option label
  ///
  /// In th, this message translates to:
  /// **'ตามระบบ (System Default)'**
  String get languageSystemDefault;

  /// Thai language option label
  ///
  /// In th, this message translates to:
  /// **'ไทย'**
  String get languageThai;

  /// English language option label
  ///
  /// In th, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Settings screen app bar title
  ///
  /// In th, this message translates to:
  /// **'การตั้งค่า'**
  String get settingsTitle;

  /// Settings section header
  ///
  /// In th, this message translates to:
  /// **'การตั้งค่าบัญชี'**
  String get settingsAccountSection;

  /// Settings list item title
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนรหัสผ่าน'**
  String get settingsChangePassword;

  /// Settings list item subtitle
  ///
  /// In th, this message translates to:
  /// **'อัปเดตรหัสผ่านบัญชีของคุณ'**
  String get settingsChangePasswordSubtitle;

  /// Settings list item title
  ///
  /// In th, this message translates to:
  /// **'การตั้งค่าการแจ้งเตือน'**
  String get settingsNotifications;

  /// Settings list item subtitle
  ///
  /// In th, this message translates to:
  /// **'จัดการการตั้งค่าการแจ้งเตือน'**
  String get settingsNotificationsSubtitle;

  /// Settings list item title
  ///
  /// In th, this message translates to:
  /// **'การตั้งค่าความเป็นส่วนตัว'**
  String get settingsPrivacy;

  /// Settings list item subtitle
  ///
  /// In th, this message translates to:
  /// **'จัดการการตั้งค่าความเป็นส่วนตัว'**
  String get settingsPrivacySubtitle;

  /// Settings section header
  ///
  /// In th, this message translates to:
  /// **'ความปลอดภัย'**
  String get settingsSafetySection;

  /// Settings list item title
  ///
  /// In th, this message translates to:
  /// **'ผู้ติดต่อฉุกเฉิน'**
  String get settingsEmergencyContact;

  /// Settings list item subtitle
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่าผู้ที่จะได้รับแจ้งเมื่อคุณกด SOS'**
  String get settingsEmergencyContactSubtitle;

  /// Settings section header
  ///
  /// In th, this message translates to:
  /// **'การตั้งค่าทั่วไป'**
  String get settingsGeneralSection;

  /// Settings list item title
  ///
  /// In th, this message translates to:
  /// **'เกี่ยวกับเรา'**
  String get settingsAbout;

  /// Settings list item subtitle
  ///
  /// In th, this message translates to:
  /// **'เรียนรู้เพิ่มเติมเกี่ยวกับเรา'**
  String get settingsAboutSubtitle;

  /// Settings list item title
  ///
  /// In th, this message translates to:
  /// **'การตั้งค่าธีม'**
  String get settingsTheme;

  /// Settings list item subtitle
  ///
  /// In th, this message translates to:
  /// **'จัดการการตั้งค่าธีม'**
  String get settingsThemeSubtitle;

  /// Theme settings option label: light mode
  ///
  /// In th, this message translates to:
  /// **'สว่าง (Light Mode)'**
  String get themeModeLight;

  /// Theme settings option label: dark mode
  ///
  /// In th, this message translates to:
  /// **'มืด (Dark Mode)'**
  String get themeModeDark;

  /// Theme settings option label: follow system
  ///
  /// In th, this message translates to:
  /// **'ตามระบบ (System Default)'**
  String get themeModeSystem;

  /// Settings list item title for language option
  ///
  /// In th, this message translates to:
  /// **'การตั้งค่าภาษา'**
  String get settingsLanguage;

  /// Settings list item subtitle for language option
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนภาษาที่ใช้ในแอป'**
  String get settingsLanguageSubtitle;

  /// Logout button label
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบ'**
  String get settingsLogout;

  /// Snackbar shown when avatar upload fails
  ///
  /// In th, this message translates to:
  /// **'อัปโหลดรูปโปรไฟล์ไม่สำเร็จ ลองใหม่อีกทีนะ'**
  String get avatarUploadError;

  /// Safety indicator label for score >= 70
  ///
  /// In th, this message translates to:
  /// **'น่าปลอดภัย'**
  String get safetyLabelSafe;

  /// Safety indicator label for score 40-69
  ///
  /// In th, this message translates to:
  /// **'ระวังหน่อยนะ'**
  String get safetyLabelCaution;

  /// Safety indicator label for score < 40
  ///
  /// In th, this message translates to:
  /// **'ควรระวังมากๆ'**
  String get safetyLabelDanger;

  /// Snackbar shown when photo upload fails
  ///
  /// In th, this message translates to:
  /// **'อัปโหลดรูปไม่สำเร็จ ลองใหม่อีกทีนะ'**
  String get photoUploadError;

  /// Bottom sheet option to take a photo with the camera
  ///
  /// In th, this message translates to:
  /// **'ถ่ายรูป'**
  String get photoSourceCamera;

  /// Bottom sheet option to pick a photo from the gallery
  ///
  /// In th, this message translates to:
  /// **'เลือกจากคลังภาพ'**
  String get photoSourceGallery;

  /// Snackbar shown when GPS location can't be found, falling back to default map center
  ///
  /// In th, this message translates to:
  /// **'หาตำแหน่งคุณไม่เจอเลย ขอแสดงจุดเริ่มต้นแทนนะ'**
  String get mapLocationNotFound;

  /// Map screen app bar title
  ///
  /// In th, this message translates to:
  /// **'จุดน่าไปแถวนี้'**
  String get mapNearbyPinsTitle;

  /// Error text shown when nearby pins fail to load
  ///
  /// In th, this message translates to:
  /// **'ยังโหลดจุดใกล้เคียงไม่ได้เลย ลองใหม่อีกทีนะ\n{error}'**
  String mapLoadPinsError(String error);

  /// FAB label to add a new map pin
  ///
  /// In th, this message translates to:
  /// **'เพิ่มจุด'**
  String get mapAddPinLabel;

  /// Map safety legend label for safe areas
  ///
  /// In th, this message translates to:
  /// **'ปลอดภัย'**
  String get mapSafetyLegendSafe;

  /// Map safety legend label for areas needing caution
  ///
  /// In th, this message translates to:
  /// **'ควรระวัง'**
  String get mapSafetyLegendCaution;

  /// Map safety legend label for dangerous areas
  ///
  /// In th, this message translates to:
  /// **'อันตราย'**
  String get mapSafetyLegendDanger;

  /// Map legend label for checkpoint pins
  ///
  /// In th, this message translates to:
  /// **'จุดเช็คพอยท์'**
  String get mapLegendCheckpoint;

  /// Map legend label for pins with an active quest
  ///
  /// In th, this message translates to:
  /// **'มีเควสอยู่'**
  String get mapLegendQuest;

  /// Map legend label for admin-recommended pins
  ///
  /// In th, this message translates to:
  /// **'แนะนำ'**
  String get mapLegendRecommended;

  /// Button label to show the map legend
  ///
  /// In th, this message translates to:
  /// **'แสดงคำอธิบายสัญลักษณ์'**
  String get mapLegendToggleShow;

  /// Button label to hide the map legend
  ///
  /// In th, this message translates to:
  /// **'ซ่อนคำอธิบายสัญลักษณ์'**
  String get mapLegendToggleHide;

  /// Map filter chip label: show all pins
  ///
  /// In th, this message translates to:
  /// **'ทั้งหมด'**
  String get mapFilterAll;

  /// Map filter chip label: safe pins only
  ///
  /// In th, this message translates to:
  /// **'ปลอดภัย'**
  String get mapFilterSafe;

  /// Map filter chip label: checkpoint pins only
  ///
  /// In th, this message translates to:
  /// **'จุดเช็คพอยท์'**
  String get mapFilterCheckpoint;

  /// Map filter chip label: pins with an active quest
  ///
  /// In th, this message translates to:
  /// **'เควส'**
  String get mapFilterQuest;

  /// Map filter chip label: admin-recommended pins only
  ///
  /// In th, this message translates to:
  /// **'แนะนำ'**
  String get mapFilterRecommended;

  /// Pin category label: food/restaurant
  ///
  /// In th, this message translates to:
  /// **'ร้านอาหาร'**
  String get mapCategoryFood;

  /// Pin category label: shop
  ///
  /// In th, this message translates to:
  /// **'ร้านค้า'**
  String get mapCategoryShop;

  /// Pin category label: tourist attraction
  ///
  /// In th, this message translates to:
  /// **'สถานที่ท่องเที่ยว'**
  String get mapCategoryAttraction;

  /// Pin category label: transport
  ///
  /// In th, this message translates to:
  /// **'การเดินทาง'**
  String get mapCategoryTransport;

  /// Pin category label: lodging
  ///
  /// In th, this message translates to:
  /// **'ที่พัก'**
  String get mapCategoryLodging;

  /// Pin category label: other
  ///
  /// In th, this message translates to:
  /// **'อื่นๆ'**
  String get mapCategoryOther;

  /// Bottom sheet title when tapping a checkpoint marker
  ///
  /// In th, this message translates to:
  /// **'จุดเช็คพอยท์'**
  String get mapCheckpointSheetTitle;

  /// Bottom sheet description for a checkpoint pin
  ///
  /// In th, this message translates to:
  /// **'เช็คอินที่นี่เพื่อรับ XP'**
  String get mapCheckpointSheetDescription;

  /// Check-in button label in the checkpoint bottom sheet
  ///
  /// In th, this message translates to:
  /// **'เช็คอิน'**
  String get mapCheckpointCheckInButton;

  /// Message shown when the user already checked in at this checkpoint today
  ///
  /// In th, this message translates to:
  /// **'เช็คอินที่นี่ไปแล้ววันนี้นะ'**
  String get mapCheckpointAlreadyDoneToday;

  /// Snackbar shown after a successful checkpoint check-in
  ///
  /// In th, this message translates to:
  /// **'เช็คอินสำเร็จ! ได้ไป +{xp} XP'**
  String mapCheckpointCheckInSuccess(int xp);

  /// Snackbar shown when checkpoint check-in fails
  ///
  /// In th, this message translates to:
  /// **'เช็คอินไม่สำเร็จ ลองใหม่อีกทีนะ'**
  String get mapCheckpointCheckInError;

  /// Snackbar shown after successful check-in with XP earned
  ///
  /// In th, this message translates to:
  /// **'เช็คอินสำเร็จแล้ว! ได้ไป +{xp} XP'**
  String pinDetailCheckInSuccess(int xp);

  /// Snackbar shown when user already checked in today (HTTP 409)
  ///
  /// In th, this message translates to:
  /// **'วันนี้เช็คอินที่นี่ไปแล้วนะ พรุ่งนี้มาใหม่ได้เลย'**
  String get pinDetailCheckInAlreadyDone;

  /// Snackbar shown on generic check-in failure
  ///
  /// In th, this message translates to:
  /// **'เช็คอินไม่สำเร็จ ลองอีกครั้งนะ'**
  String get pinDetailCheckInError;

  /// Snackbar shown after favoriting a pin
  ///
  /// In th, this message translates to:
  /// **'บันทึกเป็นรายการโปรดแล้ว'**
  String get pinDetailFavoriteAdded;

  /// Snackbar shown after unfavoriting a pin
  ///
  /// In th, this message translates to:
  /// **'ลบออกจากรายการโปรดแล้ว'**
  String get pinDetailFavoriteRemoved;

  /// Snackbar shown when favoriting/unfavoriting fails
  ///
  /// In th, this message translates to:
  /// **'อัปเดตรายการโปรดไม่สำเร็จ ลองอีกครั้งนะ'**
  String get pinDetailFavoriteError;

  /// Pin detail screen button to add this pin to the user's schedule
  ///
  /// In th, this message translates to:
  /// **'เพิ่มลงตารางเที่ยว'**
  String get pinDetailAddToScheduleButton;

  /// Snackbar placeholder shown when tapping Navigate (feature not implemented)
  ///
  /// In th, this message translates to:
  /// **'กำลังพาไปทางนั้นนะ... (ตัวอย่างเท่านั้น ยังไม่เชื่อมต่อจริง)'**
  String get pinDetailNavigatePlaceholder;

  /// Snackbar shown after successfully deleting own review
  ///
  /// In th, this message translates to:
  /// **'ลบรีวิวแล้วนะ'**
  String get pinDetailReviewDeleted;

  /// Snackbar shown when deleting own review fails
  ///
  /// In th, this message translates to:
  /// **'ลบรีวิวไม่สำเร็จ ลองใหม่อีกทีนะ'**
  String get pinDetailReviewDeleteError;

  /// Average rating with review count, e.g. '4.5 (12 reviews)'
  ///
  /// In th, this message translates to:
  /// **'{rating} ({count} รีวิว)'**
  String pinDetailRatingSummary(String rating, int count);

  /// Shown next to star rating when a pin has no reviews yet
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรีวิว'**
  String get pinDetailNoReviews;

  /// Badge label shown on verified pins
  ///
  /// In th, this message translates to:
  /// **'มีคนยืนยันแล้ว'**
  String get pinDetailVerifiedBadge;

  /// Default scam alert message when pin has no custom message
  ///
  /// In th, this message translates to:
  /// **'มีคนเคยเจอมิจฉาชีพแถวนี้ ระวังหน่อยนะ'**
  String get pinDetailScamAlertDefault;

  /// Navigate button label on pin detail screen
  ///
  /// In th, this message translates to:
  /// **'นำทาง'**
  String get pinDetailNavigateButton;

  /// Check-in button label on pin detail screen
  ///
  /// In th, this message translates to:
  /// **'เช็คอิน'**
  String get pinDetailCheckInButton;

  /// Section header for reviews list on pin detail screen
  ///
  /// In th, this message translates to:
  /// **'รีวิวจากนักเดินทาง'**
  String get pinDetailReviewsSectionTitle;

  /// Button to open the write-review dialog
  ///
  /// In th, this message translates to:
  /// **'เขียนรีวิว'**
  String get pinDetailWriteReviewButton;

  /// Error message shown when reviews fail to load
  ///
  /// In th, this message translates to:
  /// **'ยังโหลดรีวิวไม่ได้เลย ลองใหม่อีกทีนะ'**
  String get pinDetailReviewsLoadError;

  /// Empty state message when a pin has no reviews
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีใครรีวิวที่นี่เลย\nเป็นคนแรกที่เล่าประสบการณ์กันไหม'**
  String get pinDetailReviewsEmpty;

  /// Section header for risk reports list on pin detail screen
  ///
  /// In th, this message translates to:
  /// **'รายงานพื้นที่เสี่ยง'**
  String get pinDetailRiskReportsSectionTitle;

  /// Button to open the report-risk dialog
  ///
  /// In th, this message translates to:
  /// **'รายงาน'**
  String get pinDetailReportButton;

  /// Error message shown when risk reports fail to load
  ///
  /// In th, this message translates to:
  /// **'ยังโหลดรายงานไม่ได้เลย ลองใหม่อีกทีนะ'**
  String get pinDetailRiskReportsLoadError;

  /// Empty state message when a pin has no risk reports
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีใครรายงานความเสี่ยงที่นี่เลย'**
  String get pinDetailRiskReportsEmpty;

  /// Snackbar shown after successfully submitting a review
  ///
  /// In th, this message translates to:
  /// **'ขอบคุณสำหรับรีวิวนะ!'**
  String get writeReviewSubmitSuccess;

  /// Snackbar shown when submitting a review fails
  ///
  /// In th, this message translates to:
  /// **'ส่งรีวิวไม่สำเร็จ ลองใหม่อีกทีนะ'**
  String get writeReviewSubmitError;

  /// Write-review dialog title when editing an existing review
  ///
  /// In th, this message translates to:
  /// **'แก้ไขรีวิวของคุณ'**
  String get writeReviewEditTitle;

  /// Write-review dialog title when writing a new review
  ///
  /// In th, this message translates to:
  /// **'เล่าประสบการณ์ให้ฟังหน่อยนะ'**
  String get writeReviewNewTitle;

  /// Hint text for the review comment text field
  ///
  /// In th, this message translates to:
  /// **'เป็นยังไงบ้าง? บอกเล่าให้เพื่อนๆ ฟังหน่อยนะ'**
  String get writeReviewCommentHint;

  /// Label above the photo picker grid in write-review dialog
  ///
  /// In th, this message translates to:
  /// **'แนบรูปภาพ'**
  String get writeReviewAttachPhotos;

  /// Submit button label when editing an existing review
  ///
  /// In th, this message translates to:
  /// **'บันทึกการแก้ไข'**
  String get writeReviewSaveChanges;

  /// Submit button label when writing a new review
  ///
  /// In th, this message translates to:
  /// **'ส่งรีวิว'**
  String get writeReviewSubmit;

  /// Submit pin screen app bar title
  ///
  /// In th, this message translates to:
  /// **'แนะนำสถานที่ใหม่'**
  String get submitPinTitle;

  /// Hint overlay on the draggable map for placing a new pin
  ///
  /// In th, this message translates to:
  /// **'ลากแผนที่เพื่อปักหมุด'**
  String get submitPinDragMapHint;

  /// Text field label for the new pin's place name
  ///
  /// In th, this message translates to:
  /// **'ชื่อสถานที่'**
  String get submitPinNameLabel;

  /// Validation error when place name is empty
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกชื่อสถานที่'**
  String get submitPinNameValidator;

  /// Label above the category chip selector
  ///
  /// In th, this message translates to:
  /// **'หมวดหมู่'**
  String get submitPinCategoryLabel;

  /// Text field label for optional city
  ///
  /// In th, this message translates to:
  /// **'เมือง (ถ้ามี)'**
  String get submitPinCityLabel;

  /// Hint text for the description text field
  ///
  /// In th, this message translates to:
  /// **'บอกเล่ารายละเอียดสถานที่นี้หน่อยนะ'**
  String get submitPinDescriptionHint;

  /// Label above the photo picker grid in submit pin screen
  ///
  /// In th, this message translates to:
  /// **'แนบรูปภาพ'**
  String get submitPinAttachPhotos;

  /// Submit button label on submit pin screen
  ///
  /// In th, this message translates to:
  /// **'ส่งคำแนะนำ'**
  String get submitPinSubmitButton;

  /// Snackbar shown after successfully submitting a new pin
  ///
  /// In th, this message translates to:
  /// **'ส่งจุดใหม่แล้ว รอทีมงานตรวจสอบก่อนนะ'**
  String get submitPinSuccess;

  /// Snackbar shown when submitting a new pin fails
  ///
  /// In th, this message translates to:
  /// **'ส่งจุดใหม่ไม่สำเร็จ ลองใหม่อีกทีนะ'**
  String get submitPinError;

  /// About screen app bar title
  ///
  /// In th, this message translates to:
  /// **'เกี่ยวกับเรา'**
  String get aboutTitle;

  /// App version label on about screen
  ///
  /// In th, this message translates to:
  /// **'เวอร์ชัน 1.0.0'**
  String get aboutVersion;

  /// About screen body description of the app
  ///
  /// In th, this message translates to:
  /// **'ASEAN GO คือผู้คุ้มกันดิจิทัลและไกด์นำเที่ยวส่วนตัวของคุณในภูมิภาคอาเซียน ช่วยให้การเดินทางปลอดภัยยิ่งขึ้นด้วยจุดที่ผ่านการยืนยัน ระบบแจ้งเตือนความเสี่ยง และภารกิจที่ทำให้การท่องเที่ยวสนุกยิ่งขึ้น'**
  String get aboutDescription;

  /// About screen link tile label for website
  ///
  /// In th, this message translates to:
  /// **'เว็บไซต์'**
  String get aboutWebsiteLabel;

  /// About screen link tile label for contact email
  ///
  /// In th, this message translates to:
  /// **'อีเมลติดต่อ'**
  String get aboutContactEmailLabel;

  /// About screen link tile label for privacy policy
  ///
  /// In th, this message translates to:
  /// **'นโยบายความเป็นส่วนตัว'**
  String get aboutPrivacyPolicyLabel;

  /// Change password screen title and submit button label
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนรหัสผ่าน'**
  String get changePasswordTitle;

  /// Snackbar shown when password change succeeds
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนรหัสผ่านสำเร็จ'**
  String get changePasswordSuccess;

  /// Default error message when password change fails
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนรหัสผ่านไม่สำเร็จ'**
  String get changePasswordFailure;

  /// Current password field label
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านเดิม'**
  String get changePasswordCurrentLabel;

  /// Validation error when current password is empty
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกรหัสผ่านเดิม'**
  String get changePasswordCurrentValidator;

  /// New password field label
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านใหม่'**
  String get changePasswordNewLabel;

  /// Confirm new password field label
  ///
  /// In th, this message translates to:
  /// **'ยืนยันรหัสผ่านใหม่'**
  String get changePasswordConfirmLabel;

  /// Validation error when confirm password doesn't match new password
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านไม่ตรงกัน'**
  String get changePasswordMismatchValidator;

  /// Error text shown when inventory fails to load
  ///
  /// In th, this message translates to:
  /// **'ยังโหลดของสะสมไม่ได้เลย ลองใหม่อีกทีนะ'**
  String get inventoryLoadError;

  /// Empty state text shown when user has no inventory items
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีของสะสมเลย\nไปช้อปที่ร้านค้ากันก่อนนะ'**
  String get inventoryEmptyState;

  /// Snackbar shown after saving notification or privacy settings
  ///
  /// In th, this message translates to:
  /// **'บันทึกการตั้งค่าแล้ว'**
  String get settingsSavedMessage;

  /// Error text shown when settings fail to load, includes error detail
  ///
  /// In th, this message translates to:
  /// **'ไม่สามารถโหลดการตั้งค่าได้\n{error}'**
  String settingsLoadError(String error);

  /// Notification settings switch label for push notifications
  ///
  /// In th, this message translates to:
  /// **'การแจ้งเตือนแบบ Push'**
  String get notificationSettingsPushLabel;

  /// Notification settings switch label for email notifications
  ///
  /// In th, this message translates to:
  /// **'การแจ้งเตือนทางอีเมล'**
  String get notificationSettingsEmailLabel;

  /// Notification settings switch label for safety alerts
  ///
  /// In th, this message translates to:
  /// **'การแจ้งเตือนด้านความปลอดภัย'**
  String get notificationSettingsSafetyLabel;

  /// Notification settings switch label for quest reminders
  ///
  /// In th, this message translates to:
  /// **'การเตือนภารกิจ'**
  String get notificationSettingsQuestLabel;

  /// Notification settings switch label for promotions and offers
  ///
  /// In th, this message translates to:
  /// **'โปรโมชั่นและข้อเสนอ'**
  String get notificationSettingsPromotionsLabel;

  /// Generic save button label used across settings screens
  ///
  /// In th, this message translates to:
  /// **'บันทึก'**
  String get saveLabel;

  /// Privacy settings switch label for showing profile to others
  ///
  /// In th, this message translates to:
  /// **'แสดงโปรไฟล์ให้ผู้อื่นเห็น'**
  String get privacySettingsShowProfileLabel;

  /// Privacy settings switch label for showing check-in history
  ///
  /// In th, this message translates to:
  /// **'แสดงประวัติการเช็คอิน'**
  String get privacySettingsShowCheckinsLabel;

  /// Privacy settings switch label for showing written reviews
  ///
  /// In th, this message translates to:
  /// **'แสดงรีวิวที่เขียน'**
  String get privacySettingsShowReviewsLabel;

  /// Privacy settings switch label for allowing usage data collection
  ///
  /// In th, this message translates to:
  /// **'อนุญาตให้เก็บข้อมูลการใช้งาน'**
  String get privacySettingsAllowDataCollectionLabel;

  /// Profile screen badge showing the user's level
  ///
  /// In th, this message translates to:
  /// **'เลเวล {level}'**
  String profileLevelLabel(int level);

  /// Profile screen XP progress text out of 100 for current level
  ///
  /// In th, this message translates to:
  /// **'{xp} / 100 XP'**
  String profileXpProgress(int xp);

  /// Profile screen section title for inventory/collectibles
  ///
  /// In th, this message translates to:
  /// **'ของสะสมของฉัน'**
  String get profileMyCollectionsTitle;

  /// Profile screen list tile label linking to the favorites screen
  ///
  /// In th, this message translates to:
  /// **'รายการโปรด'**
  String get profileFavoritesLabel;

  /// Favorites screen app bar title
  ///
  /// In th, this message translates to:
  /// **'รายการโปรด'**
  String get favoritesScreenTitle;

  /// Empty state message when the user has no favorited pins
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรายการโปรด กดรูปหัวใจที่หมุดเพื่อบันทึกไว้ที่นี่'**
  String get favoritesEmptyState;

  /// Schedule tab/screen title
  ///
  /// In th, this message translates to:
  /// **'ตารางเที่ยว'**
  String get scheduleScreenTitle;

  /// Empty state message when there are no schedule items for the selected date
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีแผนสำหรับวันนี้'**
  String get scheduleEmptyState;

  /// Button label for adding a place to the schedule
  ///
  /// In th, this message translates to:
  /// **'เพิ่มลงตารางเที่ยว'**
  String get scheduleAddButton;

  /// Label next to the date picker row on the Schedule screen
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนวันที่'**
  String get scheduleDatePickerLabel;

  /// Snackbar shown after successfully adding a place to the schedule
  ///
  /// In th, this message translates to:
  /// **'เพิ่มลงตารางเที่ยวแล้ว'**
  String get scheduleItemAdded;

  /// Snackbar shown when adding to the schedule fails
  ///
  /// In th, this message translates to:
  /// **'เพิ่มลงตารางเที่ยวไม่สำเร็จ ลองอีกครั้งนะ'**
  String get scheduleItemAddError;

  /// Snackbar shown when the pin is already scheduled for that date (409)
  ///
  /// In th, this message translates to:
  /// **'สถานที่นี้อยู่ในตารางเที่ยววันนั้นแล้ว'**
  String get scheduleItemDuplicateError;

  /// Snackbar shown after removing a schedule item
  ///
  /// In th, this message translates to:
  /// **'ลบออกจากตารางเที่ยวแล้ว'**
  String get scheduleItemRemoved;

  /// Confirmation dialog message before deleting a schedule item
  ///
  /// In th, this message translates to:
  /// **'ลบสถานที่นี้ออกจากตารางเที่ยวไหม?'**
  String get scheduleItemDeleteConfirm;

  /// Profile screen list tile label linking to the store
  ///
  /// In th, this message translates to:
  /// **'ร้านค้า'**
  String get profileStoreLabel;

  /// Profile screen stat card label for completed quests count
  ///
  /// In th, this message translates to:
  /// **'เควสสำเร็จ'**
  String get profileQuestsCompletedLabel;

  /// Profile screen stat card label for total XP
  ///
  /// In th, this message translates to:
  /// **'XP ทั้งหมด'**
  String get profileTotalXpLabel;

  /// Profile screen stat card label for coin balance
  ///
  /// In th, this message translates to:
  /// **'เหรียญ'**
  String get profileCoinsLabel;

  /// Snackbar shown when emergency contact is saved successfully
  ///
  /// In th, this message translates to:
  /// **'บันทึกผู้ติดต่อฉุกเฉินแล้ว'**
  String get emergencyContactSaved;

  /// Fallback error message when saving emergency contact fails
  ///
  /// In th, this message translates to:
  /// **'บันทึกไม่สำเร็จ'**
  String get emergencyContactSaveFailed;

  /// Explanation text on emergency contact screen
  ///
  /// In th, this message translates to:
  /// **'เมื่อคุณกดปุ่ม SOS ระบบจะบันทึกพิกัดของคุณและแจ้งไปยังผู้ติดต่อนี้'**
  String get emergencyContactExplanation;

  /// Emergency contact name field label
  ///
  /// In th, this message translates to:
  /// **'ชื่อผู้ติดต่อฉุกเฉิน'**
  String get emergencyContactNameLabel;

  /// Validation error when emergency contact name is empty
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกชื่อ'**
  String get emergencyContactNameValidator;

  /// Emergency contact phone field label
  ///
  /// In th, this message translates to:
  /// **'เบอร์โทรศัพท์'**
  String get emergencyContactPhoneLabel;

  /// Validation error for invalid emergency contact phone number
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกเบอร์โทรที่ถูกต้อง'**
  String get emergencyContactPhoneValidator;

  /// Proximity alert banner message showing how many community reports exist for a nearby risk
  ///
  /// In th, this message translates to:
  /// **'มีคนรายงานว่าพื้นที่นี้ควรระวัง ({count} รายงาน)'**
  String proximityAlertReportCountMessage(int count);

  /// Proximity alert banner message when there's no report count detail
  ///
  /// In th, this message translates to:
  /// **'จุดนี้ควรระวังเป็นพิเศษนะ'**
  String get proximityAlertGenericMessage;

  /// Proximity alert banner title showing the name of the nearby risky place
  ///
  /// In th, this message translates to:
  /// **'ใกล้ {placeName}'**
  String proximityAlertNearbyTitle(String placeName);

  /// Risk severity chip label: caution level
  ///
  /// In th, this message translates to:
  /// **'ระวังนิดหน่อย'**
  String get riskSeverityCaution;

  /// Risk severity chip label: warning level
  ///
  /// In th, this message translates to:
  /// **'ควรระวัง'**
  String get riskSeverityWarning;

  /// Risk severity chip label: danger level
  ///
  /// In th, this message translates to:
  /// **'อันตราย'**
  String get riskSeverityDanger;

  /// Snackbar shown when submitting a risk report without a description
  ///
  /// In th, this message translates to:
  /// **'กรุณาอธิบายเหตุการณ์ที่พบหน่อยนะ'**
  String get reportRiskDescriptionRequired;

  /// Snackbar shown after successfully submitting a risk report
  ///
  /// In th, this message translates to:
  /// **'ขอบคุณที่ช่วยเตือนนักเดินทางคนอื่นนะ'**
  String get reportRiskThanksMessage;

  /// Report risk dialog title
  ///
  /// In th, this message translates to:
  /// **'รายงานพื้นที่เสี่ยง'**
  String get reportRiskTitle;

  /// Report risk dialog subtitle
  ///
  /// In th, this message translates to:
  /// **'ช่วยเตือนนักเดินทางคนอื่นว่าจุดนี้ควรระวังอะไร'**
  String get reportRiskSubtitle;

  /// Hint text for risk report description field
  ///
  /// In th, this message translates to:
  /// **'เช่น มีคนเรียกเก็บเงินเกินราคา, ทางเดินมืดตอนกลางคืน...'**
  String get reportRiskDescriptionHint;

  /// Label for optional photo attachment section in risk report dialog
  ///
  /// In th, this message translates to:
  /// **'แนบรูปภาพ (ถ้ามี)'**
  String get reportRiskAttachPhotos;

  /// Submit button label in risk report dialog
  ///
  /// In th, this message translates to:
  /// **'ส่งรายงาน'**
  String get reportRiskSubmitButton;

  /// Validation error when card number is too short
  ///
  /// In th, this message translates to:
  /// **'หมายเลขบัตรไม่ครบ'**
  String get cardFormNumberIncomplete;

  /// Validation error when card number fails Luhn check
  ///
  /// In th, this message translates to:
  /// **'หมายเลขบัตรไม่ถูกต้อง'**
  String get cardFormNumberInvalid;

  /// Validation error for wrong expiry format
  ///
  /// In th, this message translates to:
  /// **'รูปแบบ MM/YY'**
  String get cardFormExpiryFormat;

  /// Validation error for invalid month in expiry
  ///
  /// In th, this message translates to:
  /// **'เดือนไม่ถูกต้อง'**
  String get cardFormExpiryMonthInvalid;

  /// Validation error when card is already expired
  ///
  /// In th, this message translates to:
  /// **'บัตรหมดอายุแล้ว'**
  String get cardFormExpired;

  /// Validation error for invalid CVV length
  ///
  /// In th, this message translates to:
  /// **'CVV ไม่ถูกต้อง'**
  String get cardFormCvvInvalid;

  /// Fallback error message on unexpected charge exception
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินไม่สำเร็จ ลองใหม่อีกทีนะ'**
  String get cardFormChargeFailedRetry;

  /// Card form screen app bar title
  ///
  /// In th, this message translates to:
  /// **'ชำระเงิน'**
  String get cardFormTitle;

  /// Status message shown while payment is processing
  ///
  /// In th, this message translates to:
  /// **'กำลังดำเนินการชำระเงิน...'**
  String get cardFormChargingMessage;

  /// Status message shown when payment result is pending confirmation
  ///
  /// In th, this message translates to:
  /// **'รับคำขอชำระเงินแล้ว กำลังรอการยืนยัน'**
  String get cardFormPendingMessage;

  /// Status message shown when payment succeeds and coins are credited
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินสำเร็จแล้ว! ได้เหรียญเพิ่ม {coins} เหรียญ'**
  String cardFormSuccessMessage(int coins);

  /// Generic status message shown on payment failure with no specific error
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินไม่สำเร็จ'**
  String get cardFormChargeFailed;

  /// Label showing a coin amount, e.g. '100 coins'
  ///
  /// In th, this message translates to:
  /// **'{coins} เหรียญ'**
  String coinAmountLabel(int coins);

  /// Card form name-on-card field label
  ///
  /// In th, this message translates to:
  /// **'ชื่อบนบัตร'**
  String get cardFormNameLabel;

  /// Validation error when name on card is empty
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกชื่อบนบัตร'**
  String get cardFormNameValidator;

  /// Card form card-number field label
  ///
  /// In th, this message translates to:
  /// **'หมายเลขบัตร'**
  String get cardFormNumberLabel;

  /// Security disclaimer note shown below the card form, mentions Omise by name
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลบัตรของคุณจะถูกส่งตรงไปยัง Omise อย่างปลอดภัย ไม่ผ่านเซิร์ฟเวอร์ของเรา'**
  String get cardFormSecurityNote;

  /// Pay button label with THB price
  ///
  /// In th, this message translates to:
  /// **'ชำระเงิน ฿{price}'**
  String cardFormPayButton(int price);

  /// No description provided for @doneLabel.
  ///
  /// In th, this message translates to:
  /// **'เสร็จสิ้น'**
  String get doneLabel;

  /// Coin purchase bottom sheet title
  ///
  /// In th, this message translates to:
  /// **'เติมเหรียญ'**
  String get coinPurchaseTitle;

  /// Coin purchase bottom sheet subtitle
  ///
  /// In th, this message translates to:
  /// **'ใช้ซื้อของสะสมในร้านค้าได้เลย'**
  String get coinPurchaseSubtitle;

  /// Secure payment note in coin purchase dialog, mentions Omise by name
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินปลอดภัยผ่าน Omise'**
  String get coinPurchaseSecureNote;

  /// Label showing bonus value percentage for a coin package, e.g. '20% better value'
  ///
  /// In th, this message translates to:
  /// **'คุ้มกว่า {percent}%'**
  String coinPurchaseBonusPercent(int percent);

  /// Item rarity badge label: common
  ///
  /// In th, this message translates to:
  /// **'ทั่วไป'**
  String get rarityCommon;

  /// Item rarity badge label: rare
  ///
  /// In th, this message translates to:
  /// **'หายาก'**
  String get rarityRare;

  /// Item rarity badge label: epic
  ///
  /// In th, this message translates to:
  /// **'พิเศษ'**
  String get rarityEpic;

  /// Item rarity badge label: legendary
  ///
  /// In th, this message translates to:
  /// **'ตำนาน'**
  String get rarityLegendary;

  /// Label shown on a store item card the user already owns
  ///
  /// In th, this message translates to:
  /// **'มีแล้ว'**
  String get storeItemOwnedLabel;

  /// Buy button label on a store item card
  ///
  /// In th, this message translates to:
  /// **'ซื้อ'**
  String get storeItemBuyButton;

  /// Store category tab label: outfits
  ///
  /// In th, this message translates to:
  /// **'ชุด'**
  String get storeCategoryOutfit;

  /// Store category tab label: avatars
  ///
  /// In th, this message translates to:
  /// **'อวาตาร์'**
  String get storeCategoryAvatar;

  /// Store category tab label: boosters
  ///
  /// In th, this message translates to:
  /// **'บูสเตอร์'**
  String get storeCategoryBooster;

  /// Store category tab label: souvenirs
  ///
  /// In th, this message translates to:
  /// **'ของที่ระลึก'**
  String get storeCategorySouvenir;

  /// Store category tab label: all items
  ///
  /// In th, this message translates to:
  /// **'ทั้งหมด'**
  String get storeCategoryAll;

  /// Snackbar shown after successfully purchasing a store item
  ///
  /// In th, this message translates to:
  /// **'ได้ของชิ้นใหม่แล้ว!'**
  String get storeItemPurchasedMessage;

  /// Store screen app bar title
  ///
  /// In th, this message translates to:
  /// **'ร้านค้า'**
  String get storeScreenTitle;

  /// Error message shown when the store catalog fails to load, includes raw error detail
  ///
  /// In th, this message translates to:
  /// **'ยังโหลดร้านค้าไม่ได้เลย ลองใหม่อีกทีนะ\n{error}'**
  String storeLoadErrorMessage(String error);

  /// Empty state message when a store category has no items
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีสินค้าในหมวดนี้เลย'**
  String get storeEmptyCategoryMessage;

  /// Home screen section header for quick actions
  ///
  /// In th, this message translates to:
  /// **'ไปไหนกันดี'**
  String get homeWhereToGo;

  /// Home quick action label - map tab
  ///
  /// In th, this message translates to:
  /// **'แผนที่'**
  String get homeActionMap;

  /// Home quick action label - quests tab
  ///
  /// In th, this message translates to:
  /// **'เควส'**
  String get homeActionQuests;

  /// Home quick action label - profile tab
  ///
  /// In th, this message translates to:
  /// **'โปรไฟล์'**
  String get homeActionProfile;

  /// Home quick action label - notifications
  ///
  /// In th, this message translates to:
  /// **'แจ้งเตือน'**
  String get homeActionNotifications;

  /// Snackbar shown when notifications button tapped and there are none
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีการแจ้งเตือนใหม่ตอนนี้นะ'**
  String get homeNoNewNotifications;

  /// Home header greeting with user's display name
  ///
  /// In th, this message translates to:
  /// **'สวัสดี คุณ{displayName}!'**
  String homeGreeting(String displayName);

  /// Home header subtitle under greeting
  ///
  /// In th, this message translates to:
  /// **'วันนี้ไปเที่ยวไหนกันดีนะ'**
  String get homeGreetingSubtitle;

  /// Home header label near XP progress bar
  ///
  /// In th, this message translates to:
  /// **'ใกล้เลเวลถัดไปแล้วนะ'**
  String get homeCloseToNextLevel;

  /// Home header line showing today's completed vs total quests
  ///
  /// In th, this message translates to:
  /// **'วันนี้ทำเควสไปแล้ว {completed}/{total} นะ'**
  String homeQuestsProgressToday(int completed, int total);

  /// Home screen section header for recommended quests carousel
  ///
  /// In th, this message translates to:
  /// **'ภารกิจน่าลอง'**
  String get homeRecommendedQuests;

  /// Home screen message when there are no pending quests left (recommended quests section)
  ///
  /// In th, this message translates to:
  /// **'เก่งมาก ทำครบทุกภารกิจแล้ว'**
  String get homeAllQuestsCompleted;

  /// Home screen section header for nearby places
  ///
  /// In th, this message translates to:
  /// **'ที่เที่ยวใกล้ๆ คุณ'**
  String get homeNearbyPlaces;

  /// Home screen error message when nearby places fail to load
  ///
  /// In th, this message translates to:
  /// **'ยังหาที่เที่ยวใกล้ๆ ไม่เจอเลย ลองใหม่อีกทีนะ'**
  String get homeNearbyPlacesError;

  /// Home screen message when there are no nearby places
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีที่เที่ยวใกล้ๆ ตอนนี้เลย'**
  String get homeNoNearbyPlaces;

  /// Button label when an SOS is currently active, tap to cancel
  ///
  /// In th, this message translates to:
  /// **'ส่งสัญญาณ SOS แล้ว — แตะเพื่อยกเลิก'**
  String get homeSosActiveButton;

  /// Button label to trigger an SOS emergency alert
  ///
  /// In th, this message translates to:
  /// **'ฉุกเฉิน — ส่งพิกัดขอความช่วยเหลือ'**
  String get homeSosTriggerButton;

  /// Dialog title confirming SOS trigger
  ///
  /// In th, this message translates to:
  /// **'เหตุฉุกเฉิน'**
  String get homeSosConfirmTitle;

  /// Dialog body confirming SOS trigger
  ///
  /// In th, this message translates to:
  /// **'ระบบจะส่งพิกัดปัจจุบันของคุณไปยังผู้ติดต่อฉุกเฉินที่ตั้งไว้ และบันทึกเหตุการณ์ไว้ในระบบ'**
  String get homeSosConfirmContent;

  /// Cancel button label in SOS dialogs
  ///
  /// In th, this message translates to:
  /// **'ยกเลิก'**
  String get homeSosCancel;

  /// Confirm button label to send SOS
  ///
  /// In th, this message translates to:
  /// **'ส่ง SOS'**
  String get homeSosSendButton;

  /// Snackbar shown after SOS is successfully sent
  ///
  /// In th, this message translates to:
  /// **'ส่งสัญญาณ SOS แล้ว ทีมงานและผู้ติดต่อฉุกเฉินจะได้รับแจ้ง'**
  String get homeSosSentMessage;

  /// Snackbar shown when sending SOS fails
  ///
  /// In th, this message translates to:
  /// **'ส่ง SOS ไม่สำเร็จ: {error}'**
  String homeSosSendFailed(String error);

  /// Dialog title to resolve/cancel an active SOS
  ///
  /// In th, this message translates to:
  /// **'ยกเลิกสัญญาณ SOS'**
  String get homeSosResolveTitle;

  /// Dialog body to resolve/cancel an active SOS
  ///
  /// In th, this message translates to:
  /// **'คุณปลอดภัยแล้วใช่ไหม? ระบบจะปิดเหตุการณ์นี้'**
  String get homeSosResolveContent;

  /// Button label declining to resolve the SOS (not safe yet)
  ///
  /// In th, this message translates to:
  /// **'ยังไม่ปลอดภัย'**
  String get homeSosNotSafeYet;

  /// Button label confirming user is safe, resolving the SOS
  ///
  /// In th, this message translates to:
  /// **'ใช่ ปลอดภัยแล้ว'**
  String get homeSosSafeConfirm;

  /// Small status label on quest card when completed
  ///
  /// In th, this message translates to:
  /// **'ทำแล้ว'**
  String get questStatusCompleted;

  /// Small status label on quest card when pending
  ///
  /// In th, this message translates to:
  /// **'รอทำ'**
  String get questStatusPending;

  /// Coin reward chip label on quest card
  ///
  /// In th, this message translates to:
  /// **'+{coins} เหรียญ'**
  String questCoinReward(int coins);

  /// Button label on quest card to go complete the quest
  ///
  /// In th, this message translates to:
  /// **'ไปทำกัน'**
  String get questCardCompleteButton;

  /// Snackbar shown when completing a quest returns no XP (already completed or error)
  ///
  /// In th, this message translates to:
  /// **'ภารกิจนี้ทำไปแล้ว หรือลองใหม่อีกทีนะ'**
  String get questAlreadyCompletedOrRetry;

  /// Quests screen app bar title
  ///
  /// In th, this message translates to:
  /// **'ภารกิจประจำวัน'**
  String get questsScreenTitle;

  /// Empty state message when quests fail to load, includes error detail
  ///
  /// In th, this message translates to:
  /// **'ยังโหลดภารกิจไม่ได้เลย ลองใหม่อีกทีนะ\n{error}'**
  String questsLoadError(String error);

  /// Empty state message when there are no quests at all
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีภารกิจตอนนี้เลย กลับมาดูใหม่เร็วๆ นี้นะ'**
  String get questsEmptyState;

  /// Quests stats pill label for completed count
  ///
  /// In th, this message translates to:
  /// **'ทำแล้ว'**
  String get questStatCompleted;

  /// Quests stats pill label for remaining count
  ///
  /// In th, this message translates to:
  /// **'เหลืออีก'**
  String get questStatRemaining;

  /// Quests stats pill label for total count
  ///
  /// In th, this message translates to:
  /// **'ทั้งหมด'**
  String get questStatTotal;

  /// Banner text on quests screen when all quests are done (with exclamation)
  ///
  /// In th, this message translates to:
  /// **'เก่งมาก ทำครบทุกภารกิจแล้ว!'**
  String get questsAllCompletedBanner;

  /// Banner text on quests screen encouraging user to keep completing quests
  ///
  /// In th, this message translates to:
  /// **'ทำต่ออีกนิดนะ สู้ๆ'**
  String get questsKeepGoingBanner;

  /// Section header label for daily-type quests
  ///
  /// In th, this message translates to:
  /// **'รายวัน'**
  String get questTypeDaily;

  /// Section header label for location-type quests
  ///
  /// In th, this message translates to:
  /// **'สถานที่'**
  String get questTypeLocation;

  /// Section header label for category-type quests
  ///
  /// In th, this message translates to:
  /// **'หมวดหมู่'**
  String get questTypeCategory;

  /// Section header label for level-type quests
  ///
  /// In th, this message translates to:
  /// **'เลเวล'**
  String get questTypeLevel;

  /// Section header label for story-type quests
  ///
  /// In th, this message translates to:
  /// **'เนื้อเรื่อง'**
  String get questTypeStory;

  /// Badge text on a locked quest card
  ///
  /// In th, this message translates to:
  /// **'ล็อคอยู่'**
  String get questLockedLabel;

  /// Toast shown after completing a quest that also unlocked an achievement
  ///
  /// In th, this message translates to:
  /// **'ปลดล็อค Achievement: {title}'**
  String questUnlockAchievementToast(String title);

  /// Achievements screen app bar title
  ///
  /// In th, this message translates to:
  /// **'Achievements'**
  String get achievementsScreenTitle;

  /// Error message shown when achievements fail to load
  ///
  /// In th, this message translates to:
  /// **'โหลด Achievements ไม่สำเร็จ ลองใหม่อีกครั้ง\n{error}'**
  String achievementsLoadError(String error);

  /// Empty state message on achievements screen
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มี Achievement'**
  String get achievementsEmptyState;

  /// Badge text on a locked achievement card
  ///
  /// In th, this message translates to:
  /// **'ล็อคอยู่'**
  String get achievementLockedLabel;

  /// Badge text on an unlocked achievement card
  ///
  /// In th, this message translates to:
  /// **'ปลดล็อคแล้ว'**
  String get achievementUnlockedLabel;

  /// Label on the Profile screen entry point linking to the Achievements screen
  ///
  /// In th, this message translates to:
  /// **'Achievements'**
  String get profileAchievementsLabel;

  /// Level-up modal title
  ///
  /// In th, this message translates to:
  /// **'เลเวลอัพ!'**
  String get levelUpTitle;

  /// Level-up modal body showing the new level reached
  ///
  /// In th, this message translates to:
  /// **'คุณถึงเลเวล {level} แล้ว'**
  String levelUpBody(Object level);

  /// Level-up modal flourish line shown when a level-skip fired
  ///
  /// In th, this message translates to:
  /// **'คุณข้ามไป {count} เลเวล!'**
  String levelUpSkippedLevels(Object count);

  /// Level-up modal dismiss/continue button label
  ///
  /// In th, this message translates to:
  /// **'เยี่ยมมาก!'**
  String get levelUpContinueButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
