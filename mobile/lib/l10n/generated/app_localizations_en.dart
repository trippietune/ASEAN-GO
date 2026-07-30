// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Your travel companion who\'s got your back';

  @override
  String get loginWelcomeTitle => 'Welcome to AseanGo';

  @override
  String get loginWelcomeSubtitle =>
      'Your travel companion who\'s got your back. Let\'s explore together';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get displayNameValidator => 'Please enter your name';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequiredValidator => 'Please enter your email';

  @override
  String get emailValidator => 'Please enter a valid email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordValidator => 'At least 8 characters';

  @override
  String get passwordRequiredValidator => 'Please enter your password';

  @override
  String get registerSubmit => 'Create account';

  @override
  String get loginSubmit => 'Let\'s go';

  @override
  String get switchToLogin => 'Already have an account? Log in';

  @override
  String get switchToRegister => 'Don\'t have an account? Sign up';

  @override
  String get loginFailedFallback => 'Couldn\'t log in. Please try again';

  @override
  String get registerFailedFallback =>
      'Couldn\'t create your account. Please try again';

  @override
  String get rememberMeLabel => 'Remember me';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordMismatch => 'Passwords don\'t match';

  @override
  String get signupTitle => 'Sign Up';

  @override
  String get signupHeading => 'Create an account';

  @override
  String get signupSubheading => 'Let\'s start the adventure together';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordHeading => 'Forgot your password?';

  @override
  String get forgotPasswordInstructions =>
      'Enter the email you signed up with and we\'ll send you a link to reset your password';

  @override
  String get forgotPasswordSubmitButton => 'Send reset link';

  @override
  String get forgotPasswordNotAvailable =>
      'This feature isn\'t available yet. Please contact support for help';

  @override
  String get forgotPasswordCodeSentMessage =>
      'If that email is registered, we\'ve sent a 6-digit code to it';

  @override
  String get forgotPasswordRequestFailed =>
      'Couldn\'t send the reset code. Please try again';

  @override
  String get resetPasswordHeading => 'Enter your code';

  @override
  String resetPasswordInstructions(String email) {
    return 'Enter the 6-digit code we sent to $email and choose a new password';
  }

  @override
  String get resetPasswordCodeLabel => 'Reset code';

  @override
  String get resetPasswordCodeValidator =>
      'Enter the 6-digit code from your email';

  @override
  String get resetPasswordNewPasswordLabel => 'New password';

  @override
  String get resetPasswordSubmitButton => 'Reset password';

  @override
  String get resetPasswordSuccessMessage =>
      'Password reset successfully. Please log in with your new password';

  @override
  String get resetPasswordFailedFallback =>
      'Couldn\'t reset your password. Please check the code and try again';

  @override
  String get resetPasswordResendCode => 'Didn\'t get a code? Resend';

  @override
  String get resetPasswordResendSuccess => 'A new code has been sent';

  @override
  String get backToLoginLink => 'Back to login';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithFacebook => 'Continue with Facebook';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get signUpWithFacebook => 'Sign up with Facebook';

  @override
  String get orDivider => 'OR';

  @override
  String get socialLoginFailedFallback => 'Couldn\'t sign in. Please try again';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Medium';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get termsAgreementPrefix => 'I agree to the';

  @override
  String get termsOfServiceLink => 'Terms of Service';

  @override
  String get termsAgreementRequired =>
      'Please accept the Terms of Service to continue';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get termsOfServicePlaceholder =>
      'The full Terms of Service will be published here soon';

  @override
  String get noAccountYetPrompt => 'Don\'t have an account?';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get logInLinkLabel => 'Log in';

  @override
  String get retryLabel => 'Try again';

  @override
  String get languageSettingsTitle => 'Language Settings';

  @override
  String get languageSystemDefault => 'System Default';

  @override
  String get languageThai => 'ไทย (Thai)';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccountSection => 'Account Settings';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsChangePasswordSubtitle => 'Update your account password';

  @override
  String get settingsNotifications => 'Notification Settings';

  @override
  String get settingsNotificationsSubtitle =>
      'Manage your notification preferences';

  @override
  String get settingsPrivacy => 'Privacy Settings';

  @override
  String get settingsPrivacySubtitle => 'Manage your privacy preferences';

  @override
  String get settingsSafetySection => 'Safety';

  @override
  String get settingsEmergencyContact => 'Emergency Contact';

  @override
  String get settingsEmergencyContactSubtitle =>
      'Set who gets notified when you press SOS';

  @override
  String get settingsGeneralSection => 'General Settings';

  @override
  String get settingsAbout => 'About Us';

  @override
  String get settingsAboutSubtitle => 'Learn more about us';

  @override
  String get settingsTheme => 'Theme Settings';

  @override
  String get settingsThemeSubtitle => 'Manage your theme preferences';

  @override
  String get themeModeLight => 'Light Mode';

  @override
  String get themeModeDark => 'Dark Mode';

  @override
  String get themeModeSystem => 'System Default';

  @override
  String get settingsLanguage => 'Language Settings';

  @override
  String get settingsLanguageSubtitle => 'Change the app\'s language';

  @override
  String get settingsLogout => 'Log Out';

  @override
  String get avatarUploadError =>
      'Couldn\'t upload profile photo. Please try again';

  @override
  String get safetyLabelSafe => 'Looks safe';

  @override
  String get safetyLabelCaution => 'Stay a bit cautious';

  @override
  String get safetyLabelDanger => 'Be very careful';

  @override
  String get photoUploadError => 'Couldn\'t upload photo. Please try again';

  @override
  String get photoSourceCamera => 'Take a photo';

  @override
  String get photoSourceGallery => 'Choose from gallery';

  @override
  String get mapLocationNotFound =>
      'Couldn\'t find your location, showing the default spot instead';

  @override
  String get mapNearbyPinsTitle => 'Nearby Spots';

  @override
  String mapLoadPinsError(String error) {
    return 'Couldn\'t load nearby pins. Try again\n$error';
  }

  @override
  String get mapAddPinLabel => 'Add Pin';

  @override
  String get mapSafetyLegendSafe => 'Safe';

  @override
  String get mapSafetyLegendCaution => 'Caution';

  @override
  String get mapSafetyLegendDanger => 'Danger';

  @override
  String get mapLegendCheckpoint => 'Checkpoint';

  @override
  String get mapLegendQuest => 'Active quest';

  @override
  String get mapLegendRecommended => 'Recommended';

  @override
  String get mapLegendToggleShow => 'Show legend';

  @override
  String get mapLegendToggleHide => 'Hide legend';

  @override
  String get mapFilterAll => 'All';

  @override
  String get mapFilterSafe => 'Safe';

  @override
  String get mapFilterCheckpoint => 'Checkpoints';

  @override
  String get mapFilterQuest => 'Quests';

  @override
  String get mapFilterRecommended => 'Recommended';

  @override
  String get mapCategoryFood => 'Food';

  @override
  String get mapCategoryShop => 'Shop';

  @override
  String get mapCategoryAttraction => 'Attraction';

  @override
  String get mapCategoryTransport => 'Transport';

  @override
  String get mapCategoryLodging => 'Lodging';

  @override
  String get mapCategoryOther => 'Other';

  @override
  String get mapCheckpointSheetTitle => 'Checkpoint';

  @override
  String get mapCheckpointSheetDescription => 'Check in here to earn XP';

  @override
  String get mapCheckpointCheckInButton => 'Check in';

  @override
  String get mapCheckpointAlreadyDoneToday => 'Already checked in here today';

  @override
  String mapCheckpointCheckInSuccess(int xp) {
    return 'Checked in! +$xp XP earned';
  }

  @override
  String get mapCheckpointCheckInError => 'Check-in failed. Please try again.';

  @override
  String pinDetailCheckInSuccess(int xp) {
    return 'Check-in successful! +$xp XP earned';
  }

  @override
  String get pinDetailCheckInAlreadyDone =>
      'You\'ve already checked in here today. Come back tomorrow!';

  @override
  String get pinDetailCheckInError => 'Check-in failed. Please try again.';

  @override
  String get pinDetailNavigatePlaceholder =>
      'Navigating there... (demo only, not yet connected)';

  @override
  String get pinDetailReviewDeleted => 'Review deleted';

  @override
  String get pinDetailReviewDeleteError =>
      'Couldn\'t delete review. Try again.';

  @override
  String pinDetailRatingSummary(String rating, int count) {
    return '$rating ($count reviews)';
  }

  @override
  String get pinDetailNoReviews => 'No reviews yet';

  @override
  String get pinDetailVerifiedBadge => 'Verified';

  @override
  String get pinDetailScamAlertDefault =>
      'Someone reported a scam near here. Be careful.';

  @override
  String get pinDetailNavigateButton => 'Navigate';

  @override
  String get pinDetailCheckInButton => 'Check In';

  @override
  String get pinDetailReviewsSectionTitle => 'Reviews from travelers';

  @override
  String get pinDetailWriteReviewButton => 'Write a review';

  @override
  String get pinDetailReviewsLoadError => 'Couldn\'t load reviews. Try again.';

  @override
  String get pinDetailReviewsEmpty =>
      'No reviews yet.\nBe the first to share your experience';

  @override
  String get pinDetailRiskReportsSectionTitle => 'Risk reports';

  @override
  String get pinDetailReportButton => 'Report';

  @override
  String get pinDetailRiskReportsLoadError =>
      'Couldn\'t load reports. Try again.';

  @override
  String get pinDetailRiskReportsEmpty => 'No one has reported a risk here yet';

  @override
  String get writeReviewSubmitSuccess => 'Thanks for your review!';

  @override
  String get writeReviewSubmitError => 'Couldn\'t submit review. Try again.';

  @override
  String get writeReviewEditTitle => 'Edit your review';

  @override
  String get writeReviewNewTitle => 'Tell us about your experience';

  @override
  String get writeReviewCommentHint =>
      'How was it? Share it with fellow travelers';

  @override
  String get writeReviewAttachPhotos => 'Attach photos';

  @override
  String get writeReviewSaveChanges => 'Save changes';

  @override
  String get writeReviewSubmit => 'Submit review';

  @override
  String get submitPinTitle => 'Add New Pin';

  @override
  String get submitPinDragMapHint => 'Drag the map to place the pin';

  @override
  String get submitPinNameLabel => 'Place name';

  @override
  String get submitPinNameValidator => 'Please enter a place name';

  @override
  String get submitPinCategoryLabel => 'Category';

  @override
  String get submitPinCityLabel => 'City (optional)';

  @override
  String get submitPinDescriptionHint => 'Tell us more about this place';

  @override
  String get submitPinAttachPhotos => 'Attach photos';

  @override
  String get submitPinSubmitButton => 'Submit pin';

  @override
  String get submitPinSuccess =>
      'New pin submitted. Our team will review it shortly.';

  @override
  String get submitPinError => 'Couldn\'t submit pin. Try again.';

  @override
  String get aboutTitle => 'About Us';

  @override
  String get aboutVersion => 'Version 1.0.0';

  @override
  String get aboutDescription =>
      'ASEAN GO is your digital guardian and personal travel guide across the ASEAN region, making your trips safer with verified spots, risk alerts, and quests that make traveling more fun.';

  @override
  String get aboutWebsiteLabel => 'Website';

  @override
  String get aboutContactEmailLabel => 'Contact Email';

  @override
  String get aboutPrivacyPolicyLabel => 'Privacy Policy';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordSuccess => 'Password changed successfully';

  @override
  String get changePasswordFailure => 'Failed to change password';

  @override
  String get changePasswordCurrentLabel => 'Current Password';

  @override
  String get changePasswordCurrentValidator =>
      'Please enter your current password';

  @override
  String get changePasswordNewLabel => 'New Password';

  @override
  String get changePasswordConfirmLabel => 'Confirm New Password';

  @override
  String get changePasswordMismatchValidator => 'Passwords do not match';

  @override
  String get inventoryLoadError =>
      'Couldn\'t load your collectibles. Please try again.';

  @override
  String get inventoryEmptyState =>
      'No collectibles yet\nGo shopping at the store first!';

  @override
  String get settingsSavedMessage => 'Settings saved';

  @override
  String settingsLoadError(String error) {
    return 'Couldn\'t load settings\n$error';
  }

  @override
  String get notificationSettingsPushLabel => 'Push Notifications';

  @override
  String get notificationSettingsEmailLabel => 'Email Notifications';

  @override
  String get notificationSettingsSafetyLabel => 'Safety Alerts';

  @override
  String get notificationSettingsQuestLabel => 'Quest Reminders';

  @override
  String get notificationSettingsPromotionsLabel => 'Promotions and Offers';

  @override
  String get saveLabel => 'Save';

  @override
  String get privacySettingsShowProfileLabel => 'Show profile to others';

  @override
  String get privacySettingsShowCheckinsLabel => 'Show check-in history';

  @override
  String get privacySettingsShowReviewsLabel => 'Show written reviews';

  @override
  String get privacySettingsAllowDataCollectionLabel =>
      'Allow usage data collection';

  @override
  String profileLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String profileXpProgress(int xp) {
    return '$xp / 100 XP';
  }

  @override
  String get profileMyCollectionsTitle => 'My Collectibles';

  @override
  String get profileStoreLabel => 'Store';

  @override
  String get profileQuestsCompletedLabel => 'Quests Done';

  @override
  String get profileTotalXpLabel => 'Total XP';

  @override
  String get profileCoinsLabel => 'Coins';

  @override
  String get emergencyContactSaved => 'Emergency contact saved';

  @override
  String get emergencyContactSaveFailed => 'Save failed';

  @override
  String get emergencyContactExplanation =>
      'When you press the SOS button, your location will be recorded and sent to this contact';

  @override
  String get emergencyContactNameLabel => 'Emergency contact name';

  @override
  String get emergencyContactNameValidator => 'Please enter a name';

  @override
  String get emergencyContactPhoneLabel => 'Phone number';

  @override
  String get emergencyContactPhoneValidator =>
      'Please enter a valid phone number';

  @override
  String proximityAlertReportCountMessage(int count) {
    return 'People have reported this area needs caution ($count reports)';
  }

  @override
  String get proximityAlertGenericMessage => 'This spot needs extra caution';

  @override
  String proximityAlertNearbyTitle(String placeName) {
    return 'Near $placeName';
  }

  @override
  String get riskSeverityCaution => 'Minor caution';

  @override
  String get riskSeverityWarning => 'Use caution';

  @override
  String get riskSeverityDanger => 'Dangerous';

  @override
  String get reportRiskDescriptionRequired => 'Please describe what happened';

  @override
  String get reportRiskThanksMessage => 'Thanks for warning other travelers';

  @override
  String get reportRiskTitle => 'Report a risky area';

  @override
  String get reportRiskSubtitle =>
      'Help warn other travelers about what to watch out for here';

  @override
  String get reportRiskDescriptionHint =>
      'e.g. Someone overcharged me, the path is dark at night...';

  @override
  String get reportRiskAttachPhotos => 'Attach photos (optional)';

  @override
  String get reportRiskSubmitButton => 'Submit report';

  @override
  String get cardFormNumberIncomplete => 'Card number is incomplete';

  @override
  String get cardFormNumberInvalid => 'Card number is invalid';

  @override
  String get cardFormExpiryFormat => 'Format MM/YY';

  @override
  String get cardFormExpiryMonthInvalid => 'Invalid month';

  @override
  String get cardFormExpired => 'This card has expired';

  @override
  String get cardFormCvvInvalid => 'Invalid CVV';

  @override
  String get cardFormChargeFailedRetry => 'Payment failed. Please try again';

  @override
  String get cardFormTitle => 'Payment';

  @override
  String get cardFormChargingMessage => 'Processing your payment...';

  @override
  String get cardFormPendingMessage =>
      'Payment request received, awaiting confirmation';

  @override
  String cardFormSuccessMessage(int coins) {
    return 'Payment successful! You got $coins more coins';
  }

  @override
  String get cardFormChargeFailed => 'Payment failed';

  @override
  String coinAmountLabel(int coins) {
    return '$coins coins';
  }

  @override
  String get cardFormNameLabel => 'Name on card';

  @override
  String get cardFormNameValidator => 'Please enter the name on the card';

  @override
  String get cardFormNumberLabel => 'Card number';

  @override
  String get cardFormSecurityNote =>
      'Your card details are sent directly and securely to Omise, never through our servers';

  @override
  String cardFormPayButton(int price) {
    return 'Pay ฿$price';
  }

  @override
  String get doneLabel => 'Done';

  @override
  String get coinPurchaseTitle => 'Top up coins';

  @override
  String get coinPurchaseSubtitle =>
      'Use them to buy collectibles in the store';

  @override
  String get coinPurchaseSecureNote => 'Secure payment via Omise';

  @override
  String coinPurchaseBonusPercent(int percent) {
    return '$percent% better value';
  }

  @override
  String get rarityCommon => 'Common';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpic => 'Epic';

  @override
  String get rarityLegendary => 'Legendary';

  @override
  String get storeItemOwnedLabel => 'Owned';

  @override
  String get storeItemBuyButton => 'Buy';

  @override
  String get storeCategoryOutfit => 'Outfits';

  @override
  String get storeCategoryAvatar => 'Avatars';

  @override
  String get storeCategoryBooster => 'Boosters';

  @override
  String get storeCategorySouvenir => 'Souvenirs';

  @override
  String get storeCategoryAll => 'All';

  @override
  String get storeItemPurchasedMessage => 'You got a new item!';

  @override
  String get storeScreenTitle => 'Store';

  @override
  String storeLoadErrorMessage(String error) {
    return 'Couldn\'t load the store. Please try again\n$error';
  }

  @override
  String get storeEmptyCategoryMessage => 'No items in this category yet';

  @override
  String get homeWhereToGo => 'Where to go';

  @override
  String get homeActionMap => 'Map';

  @override
  String get homeActionQuests => 'Quests';

  @override
  String get homeActionProfile => 'Profile';

  @override
  String get homeActionNotifications => 'Notifications';

  @override
  String get homeNoNewNotifications => 'No new notifications right now';

  @override
  String homeGreeting(String displayName) {
    return 'Hi $displayName!';
  }

  @override
  String get homeGreetingSubtitle => 'Where would you like to go today?';

  @override
  String get homeCloseToNextLevel => 'Almost at the next level';

  @override
  String homeQuestsProgressToday(int completed, int total) {
    return 'You\'ve completed $completed/$total quests today';
  }

  @override
  String get homeRecommendedQuests => 'Quests to try';

  @override
  String get homeAllQuestsCompleted =>
      'Great job, you\'ve completed all quests';

  @override
  String get homeNearbyPlaces => 'Places near you';

  @override
  String get homeNearbyPlacesError => 'Couldn\'t find nearby places. Try again';

  @override
  String get homeNoNearbyPlaces => 'No nearby places right now';

  @override
  String get homeSosActiveButton => 'SOS signal sent — tap to cancel';

  @override
  String get homeSosTriggerButton => 'Emergency — send location for help';

  @override
  String get homeSosConfirmTitle => 'Emergency';

  @override
  String get homeSosConfirmContent =>
      'This will send your current location to your emergency contacts and log the incident.';

  @override
  String get homeSosCancel => 'Cancel';

  @override
  String get homeSosSendButton => 'Send SOS';

  @override
  String get homeSosSentMessage =>
      'SOS signal sent. Our team and your emergency contacts have been notified';

  @override
  String homeSosSendFailed(String error) {
    return 'Failed to send SOS: $error';
  }

  @override
  String get homeSosResolveTitle => 'Cancel SOS signal';

  @override
  String get homeSosResolveContent =>
      'Are you safe now? This will close the incident';

  @override
  String get homeSosNotSafeYet => 'Not safe yet';

  @override
  String get homeSosSafeConfirm => 'Yes, I\'m safe';

  @override
  String get questStatusCompleted => 'Done';

  @override
  String get questStatusPending => 'Pending';

  @override
  String questCoinReward(int coins) {
    return '+$coins coins';
  }

  @override
  String get questCardCompleteButton => 'Let\'s go';

  @override
  String get questAlreadyCompletedOrRetry =>
      'This quest was already completed, or try again';

  @override
  String get questsScreenTitle => 'Daily Quests';

  @override
  String questsLoadError(String error) {
    return 'Couldn\'t load quests. Try again\n$error';
  }

  @override
  String get questsEmptyState => 'No quests right now. Check back soon';

  @override
  String get questStatCompleted => 'Done';

  @override
  String get questStatRemaining => 'Remaining';

  @override
  String get questStatTotal => 'Total';

  @override
  String get questsAllCompletedBanner =>
      'Great job, you\'ve completed all quests!';

  @override
  String get questsKeepGoingBanner => 'Keep going, you\'ve got this';
}
