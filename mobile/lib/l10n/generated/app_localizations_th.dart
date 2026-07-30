// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTagline => 'เพื่อนเดินทางที่คอยดูแลคุณ';

  @override
  String get loginWelcomeTitle => 'ยินดีต้อนรับสู่ AseanGo';

  @override
  String get loginWelcomeSubtitle =>
      'เพื่อนเดินทางที่คอยดูแลคุณ ไปเที่ยวด้วยกันนะ';

  @override
  String get displayNameLabel => 'ชื่อที่แสดง';

  @override
  String get displayNameValidator => 'กรุณากรอกชื่อนะ';

  @override
  String get emailLabel => 'อีเมล';

  @override
  String get emailRequiredValidator => 'กรุณากรอกอีเมล';

  @override
  String get emailValidator => 'กรอกอีเมลให้ถูกต้องด้วยนะ';

  @override
  String get passwordLabel => 'รหัสผ่าน';

  @override
  String get passwordValidator => 'อย่างน้อย 8 ตัวอักษรนะ';

  @override
  String get passwordRequiredValidator => 'กรุณากรอกรหัสผ่าน';

  @override
  String get registerSubmit => 'สมัครสมาชิกเลย';

  @override
  String get loginSubmit => 'มาเที่ยวด้วยกันนะ';

  @override
  String get switchToLogin => 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบเลย';

  @override
  String get switchToRegister => 'ยังไม่มีบัญชีใช่ไหม? สมัครกันเถอะ';

  @override
  String get loginFailedFallback => 'เข้าสู่ระบบไม่สำเร็จ ลองใหม่อีกทีนะ';

  @override
  String get registerFailedFallback => 'สมัครสมาชิกไม่สำเร็จ ลองใหม่อีกทีนะ';

  @override
  String get rememberMeLabel => 'จำฉันไว้';

  @override
  String get forgotPasswordLink => 'ลืมรหัสผ่าน?';

  @override
  String get confirmPasswordLabel => 'ยืนยันรหัสผ่าน';

  @override
  String get confirmPasswordMismatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get signupTitle => 'สมัครสมาชิก';

  @override
  String get signupHeading => 'สร้างบัญชีใหม่';

  @override
  String get signupSubheading => 'มาเริ่มการผจญภัยไปด้วยกันนะ';

  @override
  String get forgotPasswordTitle => 'ลืมรหัสผ่าน';

  @override
  String get forgotPasswordHeading => 'ลืมรหัสผ่านใช่ไหม?';

  @override
  String get forgotPasswordInstructions =>
      'กรอกอีเมลที่ใช้สมัครไว้ เราจะส่งลิงก์สำหรับตั้งรหัสผ่านใหม่ให้นะ';

  @override
  String get forgotPasswordSubmitButton => 'ส่งลิงก์ตั้งรหัสผ่านใหม่';

  @override
  String get forgotPasswordNotAvailable =>
      'ฟีเจอร์นี้ยังไม่พร้อมใช้งานตอนนี้นะ กรุณาติดต่อทีมงานเพื่อขอความช่วยเหลือ';

  @override
  String get forgotPasswordCodeSentMessage =>
      'ถ้าอีเมลนี้ลงทะเบียนไว้ เราได้ส่งรหัส 6 หลักไปให้แล้วนะ';

  @override
  String get forgotPasswordRequestFailed =>
      'ส่งรหัสรีเซ็ตไม่สำเร็จ ลองใหม่อีกทีนะ';

  @override
  String get resetPasswordHeading => 'กรอกรหัสที่ได้รับ';

  @override
  String resetPasswordInstructions(String email) {
    return 'กรอกรหัส 6 หลักที่เราส่งไปที่ $email แล้วตั้งรหัสผ่านใหม่';
  }

  @override
  String get resetPasswordCodeLabel => 'รหัสรีเซ็ต';

  @override
  String get resetPasswordCodeValidator => 'กรอกรหัส 6 หลักจากอีเมลของคุณ';

  @override
  String get resetPasswordNewPasswordLabel => 'รหัสผ่านใหม่';

  @override
  String get resetPasswordSubmitButton => 'รีเซ็ตรหัสผ่าน';

  @override
  String get resetPasswordSuccessMessage =>
      'รีเซ็ตรหัสผ่านสำเร็จแล้ว กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่';

  @override
  String get resetPasswordFailedFallback =>
      'รีเซ็ตรหัสผ่านไม่สำเร็จ ตรวจสอบรหัสแล้วลองใหม่อีกทีนะ';

  @override
  String get resetPasswordResendCode => 'ไม่ได้รับรหัสใช่ไหม? ส่งอีกครั้ง';

  @override
  String get resetPasswordResendSuccess => 'ส่งรหัสใหม่แล้วนะ';

  @override
  String get backToLoginLink => 'กลับไปหน้าเข้าสู่ระบบ';

  @override
  String get continueWithGoogle => 'เข้าสู่ระบบด้วย Google';

  @override
  String get continueWithFacebook => 'เข้าสู่ระบบด้วย Facebook';

  @override
  String get signUpWithGoogle => 'สมัครสมาชิกด้วย Google';

  @override
  String get signUpWithFacebook => 'สมัครสมาชิกด้วย Facebook';

  @override
  String get orDivider => 'หรือ';

  @override
  String get socialLoginFailedFallback => 'เข้าสู่ระบบไม่สำเร็จ ลองใหม่อีกทีนะ';

  @override
  String get passwordStrengthWeak => 'อ่อน';

  @override
  String get passwordStrengthMedium => 'ปานกลาง';

  @override
  String get passwordStrengthStrong => 'แข็งแรง';

  @override
  String get termsAgreementPrefix => 'ฉันยอมรับ';

  @override
  String get termsOfServiceLink => 'ข้อกำหนดการให้บริการ';

  @override
  String get termsAgreementRequired => 'กรุณายอมรับข้อกำหนดการให้บริการก่อนนะ';

  @override
  String get termsOfServiceTitle => 'ข้อกำหนดการให้บริการ';

  @override
  String get termsOfServicePlaceholder =>
      'เนื้อหาข้อกำหนดการให้บริการฉบับเต็มจะประกาศให้ทราบเร็ว ๆ นี้';

  @override
  String get noAccountYetPrompt => 'ยังไม่มีบัญชีใช่ไหม?';

  @override
  String get haveAccountPrompt => 'มีบัญชีอยู่แล้ว?';

  @override
  String get logInLinkLabel => 'เข้าสู่ระบบ';

  @override
  String get retryLabel => 'ลองใหม่อีกครั้ง';

  @override
  String get languageSettingsTitle => 'การตั้งค่าภาษา';

  @override
  String get languageSystemDefault => 'ตามระบบ (System Default)';

  @override
  String get languageThai => 'ไทย';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get settingsAccountSection => 'การตั้งค่าบัญชี';

  @override
  String get settingsChangePassword => 'เปลี่ยนรหัสผ่าน';

  @override
  String get settingsChangePasswordSubtitle => 'อัปเดตรหัสผ่านบัญชีของคุณ';

  @override
  String get settingsNotifications => 'การตั้งค่าการแจ้งเตือน';

  @override
  String get settingsNotificationsSubtitle => 'จัดการการตั้งค่าการแจ้งเตือน';

  @override
  String get settingsPrivacy => 'การตั้งค่าความเป็นส่วนตัว';

  @override
  String get settingsPrivacySubtitle => 'จัดการการตั้งค่าความเป็นส่วนตัว';

  @override
  String get settingsSafetySection => 'ความปลอดภัย';

  @override
  String get settingsEmergencyContact => 'ผู้ติดต่อฉุกเฉิน';

  @override
  String get settingsEmergencyContactSubtitle =>
      'ตั้งค่าผู้ที่จะได้รับแจ้งเมื่อคุณกด SOS';

  @override
  String get settingsGeneralSection => 'การตั้งค่าทั่วไป';

  @override
  String get settingsAbout => 'เกี่ยวกับเรา';

  @override
  String get settingsAboutSubtitle => 'เรียนรู้เพิ่มเติมเกี่ยวกับเรา';

  @override
  String get settingsTheme => 'การตั้งค่าธีม';

  @override
  String get settingsThemeSubtitle => 'จัดการการตั้งค่าธีม';

  @override
  String get themeModeLight => 'สว่าง (Light Mode)';

  @override
  String get themeModeDark => 'มืด (Dark Mode)';

  @override
  String get themeModeSystem => 'ตามระบบ (System Default)';

  @override
  String get settingsLanguage => 'การตั้งค่าภาษา';

  @override
  String get settingsLanguageSubtitle => 'เปลี่ยนภาษาที่ใช้ในแอป';

  @override
  String get settingsLogout => 'ออกจากระบบ';

  @override
  String get avatarUploadError => 'อัปโหลดรูปโปรไฟล์ไม่สำเร็จ ลองใหม่อีกทีนะ';

  @override
  String get safetyLabelSafe => 'น่าปลอดภัย';

  @override
  String get safetyLabelCaution => 'ระวังหน่อยนะ';

  @override
  String get safetyLabelDanger => 'ควรระวังมากๆ';

  @override
  String get photoUploadError => 'อัปโหลดรูปไม่สำเร็จ ลองใหม่อีกทีนะ';

  @override
  String get photoSourceCamera => 'ถ่ายรูป';

  @override
  String get photoSourceGallery => 'เลือกจากคลังภาพ';

  @override
  String get mapLocationNotFound =>
      'หาตำแหน่งคุณไม่เจอเลย ขอแสดงจุดเริ่มต้นแทนนะ';

  @override
  String get mapNearbyPinsTitle => 'จุดน่าไปแถวนี้';

  @override
  String mapLoadPinsError(String error) {
    return 'ยังโหลดจุดใกล้เคียงไม่ได้เลย ลองใหม่อีกทีนะ\n$error';
  }

  @override
  String get mapAddPinLabel => 'เพิ่มจุด';

  @override
  String get mapSafetyLegendSafe => 'ปลอดภัย';

  @override
  String get mapSafetyLegendCaution => 'ควรระวัง';

  @override
  String get mapSafetyLegendDanger => 'อันตราย';

  @override
  String get mapLegendCheckpoint => 'จุดเช็คพอยท์';

  @override
  String get mapLegendQuest => 'มีเควสอยู่';

  @override
  String get mapLegendRecommended => 'แนะนำ';

  @override
  String get mapLegendToggleShow => 'แสดงคำอธิบายสัญลักษณ์';

  @override
  String get mapLegendToggleHide => 'ซ่อนคำอธิบายสัญลักษณ์';

  @override
  String get mapFilterAll => 'ทั้งหมด';

  @override
  String get mapFilterSafe => 'ปลอดภัย';

  @override
  String get mapFilterCheckpoint => 'จุดเช็คพอยท์';

  @override
  String get mapFilterQuest => 'เควส';

  @override
  String get mapFilterRecommended => 'แนะนำ';

  @override
  String get mapCategoryFood => 'ร้านอาหาร';

  @override
  String get mapCategoryShop => 'ร้านค้า';

  @override
  String get mapCategoryAttraction => 'สถานที่ท่องเที่ยว';

  @override
  String get mapCategoryTransport => 'การเดินทาง';

  @override
  String get mapCategoryLodging => 'ที่พัก';

  @override
  String get mapCategoryOther => 'อื่นๆ';

  @override
  String get mapCheckpointSheetTitle => 'จุดเช็คพอยท์';

  @override
  String get mapCheckpointSheetDescription => 'เช็คอินที่นี่เพื่อรับ XP';

  @override
  String get mapCheckpointCheckInButton => 'เช็คอิน';

  @override
  String get mapCheckpointAlreadyDoneToday => 'เช็คอินที่นี่ไปแล้ววันนี้นะ';

  @override
  String mapCheckpointCheckInSuccess(int xp) {
    return 'เช็คอินสำเร็จ! ได้ไป +$xp XP';
  }

  @override
  String get mapCheckpointCheckInError => 'เช็คอินไม่สำเร็จ ลองใหม่อีกทีนะ';

  @override
  String pinDetailCheckInSuccess(int xp) {
    return 'เช็คอินสำเร็จแล้ว! ได้ไป +$xp XP';
  }

  @override
  String get pinDetailCheckInAlreadyDone =>
      'วันนี้เช็คอินที่นี่ไปแล้วนะ พรุ่งนี้มาใหม่ได้เลย';

  @override
  String get pinDetailCheckInError => 'เช็คอินไม่สำเร็จ ลองอีกครั้งนะ';

  @override
  String get pinDetailNavigatePlaceholder =>
      'กำลังพาไปทางนั้นนะ... (ตัวอย่างเท่านั้น ยังไม่เชื่อมต่อจริง)';

  @override
  String get pinDetailReviewDeleted => 'ลบรีวิวแล้วนะ';

  @override
  String get pinDetailReviewDeleteError => 'ลบรีวิวไม่สำเร็จ ลองใหม่อีกทีนะ';

  @override
  String pinDetailRatingSummary(String rating, int count) {
    return '$rating ($count รีวิว)';
  }

  @override
  String get pinDetailNoReviews => 'ยังไม่มีรีวิว';

  @override
  String get pinDetailVerifiedBadge => 'มีคนยืนยันแล้ว';

  @override
  String get pinDetailScamAlertDefault =>
      'มีคนเคยเจอมิจฉาชีพแถวนี้ ระวังหน่อยนะ';

  @override
  String get pinDetailNavigateButton => 'นำทาง';

  @override
  String get pinDetailCheckInButton => 'เช็คอิน';

  @override
  String get pinDetailReviewsSectionTitle => 'รีวิวจากนักเดินทาง';

  @override
  String get pinDetailWriteReviewButton => 'เขียนรีวิว';

  @override
  String get pinDetailReviewsLoadError =>
      'ยังโหลดรีวิวไม่ได้เลย ลองใหม่อีกทีนะ';

  @override
  String get pinDetailReviewsEmpty =>
      'ยังไม่มีใครรีวิวที่นี่เลย\nเป็นคนแรกที่เล่าประสบการณ์กันไหม';

  @override
  String get pinDetailRiskReportsSectionTitle => 'รายงานพื้นที่เสี่ยง';

  @override
  String get pinDetailReportButton => 'รายงาน';

  @override
  String get pinDetailRiskReportsLoadError =>
      'ยังโหลดรายงานไม่ได้เลย ลองใหม่อีกทีนะ';

  @override
  String get pinDetailRiskReportsEmpty =>
      'ยังไม่มีใครรายงานความเสี่ยงที่นี่เลย';

  @override
  String get writeReviewSubmitSuccess => 'ขอบคุณสำหรับรีวิวนะ!';

  @override
  String get writeReviewSubmitError => 'ส่งรีวิวไม่สำเร็จ ลองใหม่อีกทีนะ';

  @override
  String get writeReviewEditTitle => 'แก้ไขรีวิวของคุณ';

  @override
  String get writeReviewNewTitle => 'เล่าประสบการณ์ให้ฟังหน่อยนะ';

  @override
  String get writeReviewCommentHint =>
      'เป็นยังไงบ้าง? บอกเล่าให้เพื่อนๆ ฟังหน่อยนะ';

  @override
  String get writeReviewAttachPhotos => 'แนบรูปภาพ';

  @override
  String get writeReviewSaveChanges => 'บันทึกการแก้ไข';

  @override
  String get writeReviewSubmit => 'ส่งรีวิว';

  @override
  String get submitPinTitle => 'เพิ่มจุดใหม่';

  @override
  String get submitPinDragMapHint => 'ลากแผนที่เพื่อปักหมุด';

  @override
  String get submitPinNameLabel => 'ชื่อสถานที่';

  @override
  String get submitPinNameValidator => 'กรุณากรอกชื่อสถานที่';

  @override
  String get submitPinCategoryLabel => 'หมวดหมู่';

  @override
  String get submitPinCityLabel => 'เมือง (ถ้ามี)';

  @override
  String get submitPinDescriptionHint => 'บอกเล่ารายละเอียดสถานที่นี้หน่อยนะ';

  @override
  String get submitPinAttachPhotos => 'แนบรูปภาพ';

  @override
  String get submitPinSubmitButton => 'ส่งจุดนี้';

  @override
  String get submitPinSuccess => 'ส่งจุดใหม่แล้ว รอทีมงานตรวจสอบก่อนนะ';

  @override
  String get submitPinError => 'ส่งจุดใหม่ไม่สำเร็จ ลองใหม่อีกทีนะ';

  @override
  String get aboutTitle => 'เกี่ยวกับเรา';

  @override
  String get aboutVersion => 'เวอร์ชัน 1.0.0';

  @override
  String get aboutDescription =>
      'ASEAN GO คือผู้คุ้มกันดิจิทัลและไกด์นำเที่ยวส่วนตัวของคุณในภูมิภาคอาเซียน ช่วยให้การเดินทางปลอดภัยยิ่งขึ้นด้วยจุดที่ผ่านการยืนยัน ระบบแจ้งเตือนความเสี่ยง และภารกิจที่ทำให้การท่องเที่ยวสนุกยิ่งขึ้น';

  @override
  String get aboutWebsiteLabel => 'เว็บไซต์';

  @override
  String get aboutContactEmailLabel => 'อีเมลติดต่อ';

  @override
  String get aboutPrivacyPolicyLabel => 'นโยบายความเป็นส่วนตัว';

  @override
  String get changePasswordTitle => 'เปลี่ยนรหัสผ่าน';

  @override
  String get changePasswordSuccess => 'เปลี่ยนรหัสผ่านสำเร็จ';

  @override
  String get changePasswordFailure => 'เปลี่ยนรหัสผ่านไม่สำเร็จ';

  @override
  String get changePasswordCurrentLabel => 'รหัสผ่านเดิม';

  @override
  String get changePasswordCurrentValidator => 'กรุณากรอกรหัสผ่านเดิม';

  @override
  String get changePasswordNewLabel => 'รหัสผ่านใหม่';

  @override
  String get changePasswordConfirmLabel => 'ยืนยันรหัสผ่านใหม่';

  @override
  String get changePasswordMismatchValidator => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get inventoryLoadError => 'ยังโหลดของสะสมไม่ได้เลย ลองใหม่อีกทีนะ';

  @override
  String get inventoryEmptyState =>
      'ยังไม่มีของสะสมเลย\nไปช้อปที่ร้านค้ากันก่อนนะ';

  @override
  String get settingsSavedMessage => 'บันทึกการตั้งค่าแล้ว';

  @override
  String settingsLoadError(String error) {
    return 'ไม่สามารถโหลดการตั้งค่าได้\n$error';
  }

  @override
  String get notificationSettingsPushLabel => 'การแจ้งเตือนแบบ Push';

  @override
  String get notificationSettingsEmailLabel => 'การแจ้งเตือนทางอีเมล';

  @override
  String get notificationSettingsSafetyLabel => 'การแจ้งเตือนด้านความปลอดภัย';

  @override
  String get notificationSettingsQuestLabel => 'การเตือนภารกิจ';

  @override
  String get notificationSettingsPromotionsLabel => 'โปรโมชั่นและข้อเสนอ';

  @override
  String get saveLabel => 'บันทึก';

  @override
  String get privacySettingsShowProfileLabel => 'แสดงโปรไฟล์ให้ผู้อื่นเห็น';

  @override
  String get privacySettingsShowCheckinsLabel => 'แสดงประวัติการเช็คอิน';

  @override
  String get privacySettingsShowReviewsLabel => 'แสดงรีวิวที่เขียน';

  @override
  String get privacySettingsAllowDataCollectionLabel =>
      'อนุญาตให้เก็บข้อมูลการใช้งาน';

  @override
  String profileLevelLabel(int level) {
    return 'เลเวล $level';
  }

  @override
  String profileXpProgress(int xp) {
    return '$xp / 100 XP';
  }

  @override
  String get profileMyCollectionsTitle => 'ของสะสมของฉัน';

  @override
  String get profileStoreLabel => 'ร้านค้า';

  @override
  String get profileQuestsCompletedLabel => 'เควสสำเร็จ';

  @override
  String get profileTotalXpLabel => 'XP ทั้งหมด';

  @override
  String get profileCoinsLabel => 'เหรียญ';

  @override
  String get emergencyContactSaved => 'บันทึกผู้ติดต่อฉุกเฉินแล้ว';

  @override
  String get emergencyContactSaveFailed => 'บันทึกไม่สำเร็จ';

  @override
  String get emergencyContactExplanation =>
      'เมื่อคุณกดปุ่ม SOS ระบบจะบันทึกพิกัดของคุณและแจ้งไปยังผู้ติดต่อนี้';

  @override
  String get emergencyContactNameLabel => 'ชื่อผู้ติดต่อฉุกเฉิน';

  @override
  String get emergencyContactNameValidator => 'กรุณากรอกชื่อ';

  @override
  String get emergencyContactPhoneLabel => 'เบอร์โทรศัพท์';

  @override
  String get emergencyContactPhoneValidator => 'กรุณากรอกเบอร์โทรที่ถูกต้อง';

  @override
  String proximityAlertReportCountMessage(int count) {
    return 'มีคนรายงานว่าพื้นที่นี้ควรระวัง ($count รายงาน)';
  }

  @override
  String get proximityAlertGenericMessage => 'จุดนี้ควรระวังเป็นพิเศษนะ';

  @override
  String proximityAlertNearbyTitle(String placeName) {
    return 'ใกล้ $placeName';
  }

  @override
  String get riskSeverityCaution => 'ระวังนิดหน่อย';

  @override
  String get riskSeverityWarning => 'ควรระวัง';

  @override
  String get riskSeverityDanger => 'อันตราย';

  @override
  String get reportRiskDescriptionRequired =>
      'กรุณาอธิบายเหตุการณ์ที่พบหน่อยนะ';

  @override
  String get reportRiskThanksMessage => 'ขอบคุณที่ช่วยเตือนนักเดินทางคนอื่นนะ';

  @override
  String get reportRiskTitle => 'รายงานพื้นที่เสี่ยง';

  @override
  String get reportRiskSubtitle =>
      'ช่วยเตือนนักเดินทางคนอื่นว่าจุดนี้ควรระวังอะไร';

  @override
  String get reportRiskDescriptionHint =>
      'เช่น มีคนเรียกเก็บเงินเกินราคา, ทางเดินมืดตอนกลางคืน...';

  @override
  String get reportRiskAttachPhotos => 'แนบรูปภาพ (ถ้ามี)';

  @override
  String get reportRiskSubmitButton => 'ส่งรายงาน';

  @override
  String get cardFormNumberIncomplete => 'หมายเลขบัตรไม่ครบ';

  @override
  String get cardFormNumberInvalid => 'หมายเลขบัตรไม่ถูกต้อง';

  @override
  String get cardFormExpiryFormat => 'รูปแบบ MM/YY';

  @override
  String get cardFormExpiryMonthInvalid => 'เดือนไม่ถูกต้อง';

  @override
  String get cardFormExpired => 'บัตรหมดอายุแล้ว';

  @override
  String get cardFormCvvInvalid => 'CVV ไม่ถูกต้อง';

  @override
  String get cardFormChargeFailedRetry => 'ชำระเงินไม่สำเร็จ ลองใหม่อีกทีนะ';

  @override
  String get cardFormTitle => 'ชำระเงิน';

  @override
  String get cardFormChargingMessage => 'กำลังดำเนินการชำระเงิน...';

  @override
  String get cardFormPendingMessage => 'รับคำขอชำระเงินแล้ว กำลังรอการยืนยัน';

  @override
  String cardFormSuccessMessage(int coins) {
    return 'ชำระเงินสำเร็จแล้ว! ได้เหรียญเพิ่ม $coins เหรียญ';
  }

  @override
  String get cardFormChargeFailed => 'ชำระเงินไม่สำเร็จ';

  @override
  String coinAmountLabel(int coins) {
    return '$coins เหรียญ';
  }

  @override
  String get cardFormNameLabel => 'ชื่อบนบัตร';

  @override
  String get cardFormNameValidator => 'กรุณากรอกชื่อบนบัตร';

  @override
  String get cardFormNumberLabel => 'หมายเลขบัตร';

  @override
  String get cardFormSecurityNote =>
      'ข้อมูลบัตรของคุณจะถูกส่งตรงไปยัง Omise อย่างปลอดภัย ไม่ผ่านเซิร์ฟเวอร์ของเรา';

  @override
  String cardFormPayButton(int price) {
    return 'ชำระเงิน ฿$price';
  }

  @override
  String get doneLabel => 'เสร็จสิ้น';

  @override
  String get coinPurchaseTitle => 'เติมเหรียญ';

  @override
  String get coinPurchaseSubtitle => 'ใช้ซื้อของสะสมในร้านค้าได้เลย';

  @override
  String get coinPurchaseSecureNote => 'ชำระเงินปลอดภัยผ่าน Omise';

  @override
  String coinPurchaseBonusPercent(int percent) {
    return 'คุ้มกว่า $percent%';
  }

  @override
  String get rarityCommon => 'ทั่วไป';

  @override
  String get rarityRare => 'หายาก';

  @override
  String get rarityEpic => 'พิเศษ';

  @override
  String get rarityLegendary => 'ตำนาน';

  @override
  String get storeItemOwnedLabel => 'มีแล้ว';

  @override
  String get storeItemBuyButton => 'ซื้อ';

  @override
  String get storeCategoryOutfit => 'ชุด';

  @override
  String get storeCategoryAvatar => 'อวาตาร์';

  @override
  String get storeCategoryBooster => 'บูสเตอร์';

  @override
  String get storeCategorySouvenir => 'ของที่ระลึก';

  @override
  String get storeCategoryAll => 'ทั้งหมด';

  @override
  String get storeItemPurchasedMessage => 'ได้ของชิ้นใหม่แล้ว!';

  @override
  String get storeScreenTitle => 'ร้านค้า';

  @override
  String storeLoadErrorMessage(String error) {
    return 'ยังโหลดร้านค้าไม่ได้เลย ลองใหม่อีกทีนะ\n$error';
  }

  @override
  String get storeEmptyCategoryMessage => 'ยังไม่มีสินค้าในหมวดนี้เลย';

  @override
  String get homeWhereToGo => 'ไปไหนกันดี';

  @override
  String get homeActionMap => 'แผนที่';

  @override
  String get homeActionQuests => 'เควส';

  @override
  String get homeActionProfile => 'โปรไฟล์';

  @override
  String get homeActionNotifications => 'แจ้งเตือน';

  @override
  String get homeNoNewNotifications => 'ยังไม่มีการแจ้งเตือนใหม่ตอนนี้นะ';

  @override
  String homeGreeting(String displayName) {
    return 'สวัสดี คุณ$displayName!';
  }

  @override
  String get homeGreetingSubtitle => 'วันนี้ไปเที่ยวไหนกันดีนะ';

  @override
  String get homeCloseToNextLevel => 'ใกล้เลเวลถัดไปแล้วนะ';

  @override
  String homeQuestsProgressToday(int completed, int total) {
    return 'วันนี้ทำเควสไปแล้ว $completed/$total นะ';
  }

  @override
  String get homeRecommendedQuests => 'ภารกิจน่าลอง';

  @override
  String get homeAllQuestsCompleted => 'เก่งมาก ทำครบทุกภารกิจแล้ว';

  @override
  String get homeNearbyPlaces => 'ที่เที่ยวใกล้ๆ คุณ';

  @override
  String get homeNearbyPlacesError =>
      'ยังหาที่เที่ยวใกล้ๆ ไม่เจอเลย ลองใหม่อีกทีนะ';

  @override
  String get homeNoNearbyPlaces => 'ยังไม่มีที่เที่ยวใกล้ๆ ตอนนี้เลย';

  @override
  String get homeSosActiveButton => 'ส่งสัญญาณ SOS แล้ว — แตะเพื่อยกเลิก';

  @override
  String get homeSosTriggerButton => 'ฉุกเฉิน — ส่งพิกัดขอความช่วยเหลือ';

  @override
  String get homeSosConfirmTitle => 'เหตุฉุกเฉิน';

  @override
  String get homeSosConfirmContent =>
      'ระบบจะส่งพิกัดปัจจุบันของคุณไปยังผู้ติดต่อฉุกเฉินที่ตั้งไว้ และบันทึกเหตุการณ์ไว้ในระบบ';

  @override
  String get homeSosCancel => 'ยกเลิก';

  @override
  String get homeSosSendButton => 'ส่ง SOS';

  @override
  String get homeSosSentMessage =>
      'ส่งสัญญาณ SOS แล้ว ทีมงานและผู้ติดต่อฉุกเฉินจะได้รับแจ้ง';

  @override
  String homeSosSendFailed(String error) {
    return 'ส่ง SOS ไม่สำเร็จ: $error';
  }

  @override
  String get homeSosResolveTitle => 'ยกเลิกสัญญาณ SOS';

  @override
  String get homeSosResolveContent =>
      'คุณปลอดภัยแล้วใช่ไหม? ระบบจะปิดเหตุการณ์นี้';

  @override
  String get homeSosNotSafeYet => 'ยังไม่ปลอดภัย';

  @override
  String get homeSosSafeConfirm => 'ใช่ ปลอดภัยแล้ว';

  @override
  String get questStatusCompleted => 'ทำแล้ว';

  @override
  String get questStatusPending => 'รอทำ';

  @override
  String questCoinReward(int coins) {
    return '+$coins เหรียญ';
  }

  @override
  String get questCardCompleteButton => 'ไปทำกัน';

  @override
  String get questAlreadyCompletedOrRetry =>
      'ภารกิจนี้ทำไปแล้ว หรือลองใหม่อีกทีนะ';

  @override
  String get questsScreenTitle => 'ภารกิจประจำวัน';

  @override
  String questsLoadError(String error) {
    return 'ยังโหลดภารกิจไม่ได้เลย ลองใหม่อีกทีนะ\n$error';
  }

  @override
  String get questsEmptyState =>
      'ยังไม่มีภารกิจตอนนี้เลย กลับมาดูใหม่เร็วๆ นี้นะ';

  @override
  String get questStatCompleted => 'ทำแล้ว';

  @override
  String get questStatRemaining => 'เหลืออีก';

  @override
  String get questStatTotal => 'ทั้งหมด';

  @override
  String get questsAllCompletedBanner => 'เก่งมาก ทำครบทุกภารกิจแล้ว!';

  @override
  String get questsKeepGoingBanner => 'ทำต่ออีกนิดนะ สู้ๆ';
}
