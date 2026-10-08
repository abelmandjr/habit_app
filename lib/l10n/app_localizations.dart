import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hábitos'**
  String get appTitle;

  /// No description provided for @actionCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar'**
  String get actionDelete;

  /// No description provided for @actionRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get actionRetry;

  /// No description provided for @actionOpenSettings.
  ///
  /// In pt, this message translates to:
  /// **'Abrir definições'**
  String get actionOpenSettings;

  /// No description provided for @actionNotNow.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get actionNotNow;

  /// No description provided for @yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get no;

  /// No description provided for @today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get today;

  /// No description provided for @errorSaveLog.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível guardar o registo. Tenta novamente.'**
  String get errorSaveLog;

  /// No description provided for @errorDeleteHabit.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível eliminar o hábito. Tenta novamente.'**
  String get errorDeleteHabit;

  /// No description provided for @errorSaveHabit.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível guardar o hábito. Tenta novamente.'**
  String get errorSaveHabit;

  /// No description provided for @errorSaveName.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível guardar o nome. Tenta novamente.'**
  String get errorSaveName;

  /// No description provided for @errorLoadHabit.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o hábito.'**
  String get errorLoadHabit;

  /// No description provided for @errorLoadData.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os dados.'**
  String get errorLoadData;

  /// No description provided for @errorLoadHabits.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os hábitos.'**
  String get errorLoadHabits;

  /// No description provided for @errorLoadHabitDetail.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o hábito.'**
  String get errorLoadHabitDetail;

  /// No description provided for @errorRequestNotificationPermission.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível pedir permissão para as notificações.'**
  String get errorRequestNotificationPermission;

  /// No description provided for @errorCheckAlarmPermission.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar a permissão de alarmes.'**
  String get errorCheckAlarmPermission;

  /// No description provided for @errorOpenSettings.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir as definições.'**
  String get errorOpenSettings;

  /// No description provided for @dashboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hábitos'**
  String get dashboardTitle;

  /// No description provided for @dashboardNewHabit.
  ///
  /// In pt, this message translates to:
  /// **'Novo hábito'**
  String get dashboardNewHabit;

  /// No description provided for @dashboardEditName.
  ///
  /// In pt, this message translates to:
  /// **'Editar nome'**
  String get dashboardEditName;

  /// No description provided for @greetingMorning.
  ///
  /// In pt, this message translates to:
  /// **'Bom dia'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In pt, this message translates to:
  /// **'Boa tarde'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In pt, this message translates to:
  /// **'Boa noite'**
  String get greetingEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In pt, this message translates to:
  /// **'{period}, {name} 👋'**
  String greetingWithName(String period, String name);

  /// No description provided for @greetingWithoutName.
  ///
  /// In pt, this message translates to:
  /// **'{period} 👋'**
  String greetingWithoutName(String period);

  /// No description provided for @dashboardHint.
  ///
  /// In pt, this message translates to:
  /// **'Sim/não: toca para marcar. Quantitativo: toca para registar. Desliza para eliminar.'**
  String get dashboardHint;

  /// No description provided for @dashboardAllDone.
  ///
  /// In pt, this message translates to:
  /// **'Todos os hábitos de hoje já estão feitos.'**
  String get dashboardAllDone;

  /// No description provided for @nameDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'O teu nome'**
  String get nameDialogTitle;

  /// No description provided for @nameDialogHint.
  ///
  /// In pt, this message translates to:
  /// **'Como te devemos chamar?'**
  String get nameDialogHint;

  /// No description provided for @emptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tens hábitos'**
  String get emptyTitle;

  /// No description provided for @emptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Cria o teu primeiro hábito e acompanha o teu progresso diário.'**
  String get emptyMessage;

  /// No description provided for @deleteHabitTitle.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar hábito?'**
  String get deleteHabitTitle;

  /// No description provided for @deleteHabitMessage.
  ///
  /// In pt, this message translates to:
  /// **'Queres eliminar \"{title}\"? Todo o histórico será apagado.'**
  String deleteHabitMessage(String title);

  /// No description provided for @deleteHabitMessageGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Todo o histórico será apagado. Esta ação não pode ser desfeita.'**
  String get deleteHabitMessageGeneric;

  /// No description provided for @detailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get detailTitle;

  /// No description provided for @detailDeleteMenu.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar hábito'**
  String get detailDeleteMenu;

  /// No description provided for @detailNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Hábito não encontrado'**
  String get detailNotFound;

  /// No description provided for @goalPerDay.
  ///
  /// In pt, this message translates to:
  /// **'Meta: {goal}/dia'**
  String goalPerDay(String goal);

  /// No description provided for @yesNoTag.
  ///
  /// In pt, this message translates to:
  /// **'Sim / Não'**
  String get yesNoTag;

  /// No description provided for @reminderActive.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete ativo'**
  String get reminderActive;

  /// No description provided for @logUpdateToday.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar o registo de hoje'**
  String get logUpdateToday;

  /// No description provided for @logValueToday.
  ///
  /// In pt, this message translates to:
  /// **'Registar o valor de hoje'**
  String get logValueToday;

  /// No description provided for @doneToday.
  ///
  /// In pt, this message translates to:
  /// **'Feito hoje'**
  String get doneToday;

  /// No description provided for @markDoneToday.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como feito hoje'**
  String get markDoneToday;

  /// No description provided for @formNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo hábito'**
  String get formNewTitle;

  /// No description provided for @formEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar hábito'**
  String get formEditTitle;

  /// No description provided for @formTypeQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Que tipo de hábito é?'**
  String get formTypeQuestion;

  /// No description provided for @formTypeHelp.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe como vais registar este hábito no dia a dia.'**
  String get formTypeHelp;

  /// No description provided for @habitTypeYesNo.
  ///
  /// In pt, this message translates to:
  /// **'Sim ou não'**
  String get habitTypeYesNo;

  /// No description provided for @habitTypeYesNoExamples.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: meditar, tomar a medicação, ler'**
  String get habitTypeYesNoExamples;

  /// No description provided for @habitTypeQuantitative.
  ///
  /// In pt, this message translates to:
  /// **'Quantitativo'**
  String get habitTypeQuantitative;

  /// No description provided for @habitTypeQuantitativeExamples.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: beber água, caminhar, horas de estudo'**
  String get habitTypeQuantitativeExamples;

  /// No description provided for @formTitleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get formTitleLabel;

  /// No description provided for @formTitleHintYesNo.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Meditar'**
  String get formTitleHintYesNo;

  /// No description provided for @formTitleHintQuantitative.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Beber água'**
  String get formTitleHintQuantitative;

  /// No description provided for @formDescriptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get formDescriptionLabel;

  /// No description provided for @formCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get formCategory;

  /// No description provided for @formCustomCategorySwitch.
  ///
  /// In pt, this message translates to:
  /// **'Criar categoria personalizada'**
  String get formCustomCategorySwitch;

  /// No description provided for @formCustomCategoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'A tua categoria'**
  String get formCustomCategoryLabel;

  /// No description provided for @formCustomCategoryHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Espiritualidade, Finanças'**
  String get formCustomCategoryHint;

  /// No description provided for @formUnitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get formUnitLabel;

  /// No description provided for @formUnitHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: L, kg, min'**
  String get formUnitHint;

  /// No description provided for @formDailyGoal.
  ///
  /// In pt, this message translates to:
  /// **'Meta diária'**
  String get formDailyGoal;

  /// No description provided for @formReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete diário'**
  String get formReminder;

  /// No description provided for @formReminderSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificação à hora escolhida'**
  String get formReminderSubtitle;

  /// No description provided for @formPickTime.
  ///
  /// In pt, this message translates to:
  /// **'Escolher hora'**
  String get formPickTime;

  /// No description provided for @formSaveChanges.
  ///
  /// In pt, this message translates to:
  /// **'Guardar alterações'**
  String get formSaveChanges;

  /// No description provided for @formCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar hábito'**
  String get formCreate;

  /// No description provided for @formValidation.
  ///
  /// In pt, this message translates to:
  /// **'Preenche o título, a categoria e a unidade (se for quantitativo).'**
  String get formValidation;

  /// No description provided for @formCreated.
  ///
  /// In pt, this message translates to:
  /// **'Hábito criado'**
  String get formCreated;

  /// No description provided for @formUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Hábito atualizado'**
  String get formUpdated;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In pt, this message translates to:
  /// **'Sem permissão para notificações. Ativa-a nas definições do telemóvel para receberes lembretes.'**
  String get notificationPermissionDenied;

  /// No description provided for @exactAlarmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes à hora certa'**
  String get exactAlarmTitle;

  /// No description provided for @exactAlarmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Para os lembretes chegarem à hora exata, permite \"Alarmes e lembretes\" nas definições da app. Sem isso, o Android pode atrasá-los.'**
  String get exactAlarmMessage;

  /// No description provided for @exactAlarmWarning.
  ///
  /// In pt, this message translates to:
  /// **'Os lembretes podem chegar atrasados: a app não tem permissão para alarmes exatos.'**
  String get exactAlarmWarning;

  /// No description provided for @sortBy.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por'**
  String get sortBy;

  /// No description provided for @sortName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get sortName;

  /// No description provided for @sortCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get sortCategory;

  /// No description provided for @sortProgress.
  ///
  /// In pt, this message translates to:
  /// **'Progresso de hoje'**
  String get sortProgress;

  /// No description provided for @sortStreak.
  ///
  /// In pt, this message translates to:
  /// **'Sequência'**
  String get sortStreak;

  /// No description provided for @sortNewest.
  ///
  /// In pt, this message translates to:
  /// **'Mais recentes'**
  String get sortNewest;

  /// No description provided for @hideDone.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar feitos'**
  String get hideDone;

  /// No description provided for @logQuestionToday.
  ///
  /// In pt, this message translates to:
  /// **'Fizeste este hábito hoje?'**
  String get logQuestionToday;

  /// No description provided for @logPastDay.
  ///
  /// In pt, this message translates to:
  /// **'Registar o histórico deste dia'**
  String get logPastDay;

  /// No description provided for @logRemoveDay.
  ///
  /// In pt, this message translates to:
  /// **'Remover o registo deste dia'**
  String get logRemoveDay;

  /// No description provided for @logTodayGoal.
  ///
  /// In pt, this message translates to:
  /// **'Registo de hoje · meta {goal}'**
  String logTodayGoal(String goal);

  /// No description provided for @logPastGoal.
  ///
  /// In pt, this message translates to:
  /// **'Registo histórico · meta {goal}'**
  String logPastGoal(String goal);

  /// No description provided for @logValueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor atingido'**
  String get logValueLabel;

  /// No description provided for @logClearDay.
  ///
  /// In pt, this message translates to:
  /// **'Limpar o registo deste dia'**
  String get logClearDay;

  /// No description provided for @reportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatório'**
  String get reportTitle;

  /// No description provided for @metricDaysDone.
  ///
  /// In pt, this message translates to:
  /// **'Dias feitos'**
  String get metricDaysDone;

  /// No description provided for @metricDaysMissed.
  ///
  /// In pt, this message translates to:
  /// **'Dias falhados'**
  String get metricDaysMissed;

  /// No description provided for @metricSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Sucesso'**
  String get metricSuccess;

  /// No description provided for @metricTrackedDays.
  ///
  /// In pt, this message translates to:
  /// **'Dias acompanhados'**
  String get metricTrackedDays;

  /// No description provided for @metricToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get metricToday;

  /// No description provided for @metricDailyAverage.
  ///
  /// In pt, this message translates to:
  /// **'Média diária'**
  String get metricDailyAverage;

  /// No description provided for @metricTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total acumulado'**
  String get metricTotal;

  /// No description provided for @metricBestDay.
  ///
  /// In pt, this message translates to:
  /// **'Melhor dia'**
  String get metricBestDay;

  /// No description provided for @reportTapToEdit.
  ///
  /// In pt, this message translates to:
  /// **'Toca num dia para editar o histórico.'**
  String get reportTapToEdit;

  /// No description provided for @reportTapToEditValues.
  ///
  /// In pt, this message translates to:
  /// **'Toca num dia para registar ou corrigir valores passados.'**
  String get reportTapToEditValues;

  /// No description provided for @reportGoalProgress.
  ///
  /// In pt, this message translates to:
  /// **'Progresso da meta de hoje'**
  String get reportGoalProgress;

  /// No description provided for @reportGoalMet.
  ///
  /// In pt, this message translates to:
  /// **'✓ meta atingida'**
  String get reportGoalMet;

  /// No description provided for @reportEvolution.
  ///
  /// In pt, this message translates to:
  /// **'Evolução (últimos 30 dias)'**
  String get reportEvolution;

  /// No description provided for @chartGoal.
  ///
  /// In pt, this message translates to:
  /// **'Meta'**
  String get chartGoal;

  /// No description provided for @calendarTitle.
  ///
  /// In pt, this message translates to:
  /// **'Calendário de progresso'**
  String get calendarTitle;

  /// No description provided for @legendDone.
  ///
  /// In pt, this message translates to:
  /// **'Feito'**
  String get legendDone;

  /// No description provided for @legendLogged.
  ///
  /// In pt, this message translates to:
  /// **'Registado'**
  String get legendLogged;

  /// No description provided for @legendToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get legendToday;

  /// No description provided for @streakCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Sequência atual'**
  String get streakCurrent;

  /// No description provided for @streakBest.
  ///
  /// In pt, this message translates to:
  /// **'Melhor sequência'**
  String get streakBest;

  /// No description provided for @streakTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get streakTotal;

  /// Palavra 'dia(s)' que acompanha um número mostrado à parte. O =0 é explícito porque a regra CLDR de "pt" (brasileira) põe o 0 no singular; em PT-PT é "0 dias".
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{dias} =1{dia} other{dias}}'**
  String dayUnit(int count);

  /// No description provided for @globalStreakBest.
  ///
  /// In pt, this message translates to:
  /// **'melhor:'**
  String get globalStreakBest;

  /// No description provided for @todaySummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atividades de hoje'**
  String get todaySummaryTitle;

  /// No description provided for @todayDone.
  ///
  /// In pt, this message translates to:
  /// **'Feitas'**
  String get todayDone;

  /// No description provided for @todayPercent.
  ///
  /// In pt, this message translates to:
  /// **'Percentagem'**
  String get todayPercent;

  /// No description provided for @todayRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Faltam'**
  String get todayRemaining;

  /// No description provided for @tileGoal.
  ///
  /// In pt, this message translates to:
  /// **'Meta: {goal}'**
  String tileGoal(String goal);

  /// No description provided for @tileTodayValue.
  ///
  /// In pt, this message translates to:
  /// **'Hoje: {value} / {goal}'**
  String tileTodayValue(String value, String goal);

  /// No description provided for @tileDetails.
  ///
  /// In pt, this message translates to:
  /// **'Ver detalhes'**
  String get tileDetails;

  /// No description provided for @notificationChannelName.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes de hábitos'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In pt, this message translates to:
  /// **'Notificações diárias para te lembrar dos teus hábitos'**
  String get notificationChannelDescription;

  /// No description provided for @notificationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hora do hábito'**
  String get notificationTitle;
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
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
