// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Hábitos';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionRetry => 'Tentar de novo';

  @override
  String get actionOpenSettings => 'Abrir definições';

  @override
  String get actionNotNow => 'Agora não';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get today => 'Hoje';

  @override
  String get errorSaveLog =>
      'Não foi possível guardar o registo. Tenta novamente.';

  @override
  String get errorDeleteHabit =>
      'Não foi possível eliminar o hábito. Tenta novamente.';

  @override
  String get errorSaveHabit =>
      'Não foi possível guardar o hábito. Tenta novamente.';

  @override
  String get errorSaveName =>
      'Não foi possível guardar o nome. Tenta novamente.';

  @override
  String get errorLoadHabit => 'Não foi possível abrir o hábito.';

  @override
  String get errorLoadData => 'Não foi possível carregar os dados.';

  @override
  String get errorLoadHabits => 'Não foi possível carregar os hábitos.';

  @override
  String get errorLoadHabitDetail => 'Não foi possível carregar o hábito.';

  @override
  String get errorRequestNotificationPermission =>
      'Não foi possível pedir permissão para as notificações.';

  @override
  String get errorCheckAlarmPermission =>
      'Não foi possível verificar a permissão de alarmes.';

  @override
  String get errorOpenSettings => 'Não foi possível abrir as definições.';

  @override
  String get dashboardTitle => 'Hábitos';

  @override
  String get dashboardNewHabit => 'Novo hábito';

  @override
  String get dashboardEditName => 'Editar nome';

  @override
  String get greetingMorning => 'Bom dia';

  @override
  String get greetingAfternoon => 'Boa tarde';

  @override
  String get greetingEvening => 'Boa noite';

  @override
  String greetingWithName(String period, String name) {
    return '$period, $name 👋';
  }

  @override
  String greetingWithoutName(String period) {
    return '$period 👋';
  }

  @override
  String get dashboardHint =>
      'Sim/não: toca para marcar. Quantitativo: toca para registar. Desliza para eliminar.';

  @override
  String get dashboardAllDone => 'Todos os hábitos de hoje já estão feitos.';

  @override
  String get nameDialogTitle => 'O teu nome';

  @override
  String get nameDialogHint => 'Como te devemos chamar?';

  @override
  String get emptyTitle => 'Ainda não tens hábitos';

  @override
  String get emptyMessage =>
      'Cria o teu primeiro hábito e acompanha o teu progresso diário.';

  @override
  String get deleteHabitTitle => 'Eliminar hábito?';

  @override
  String deleteHabitMessage(String title) {
    return 'Queres eliminar \"$title\"? Todo o histórico será apagado.';
  }

  @override
  String get deleteHabitMessageGeneric =>
      'Todo o histórico será apagado. Esta ação não pode ser desfeita.';

  @override
  String get detailTitle => 'Detalhes';

  @override
  String get detailDeleteMenu => 'Eliminar hábito';

  @override
  String get detailNotFound => 'Hábito não encontrado';

  @override
  String goalPerDay(String goal) {
    return 'Meta: $goal/dia';
  }

  @override
  String get yesNoTag => 'Sim / Não';

  @override
  String get reminderActive => 'Lembrete ativo';

  @override
  String get logUpdateToday => 'Atualizar o registo de hoje';

  @override
  String get logValueToday => 'Registar o valor de hoje';

  @override
  String get doneToday => 'Feito hoje';

  @override
  String get markDoneToday => 'Marcar como feito hoje';

  @override
  String get formNewTitle => 'Novo hábito';

  @override
  String get formEditTitle => 'Editar hábito';

  @override
  String get formTypeQuestion => 'Que tipo de hábito é?';

  @override
  String get formTypeHelp =>
      'Escolhe como vais registar este hábito no dia a dia.';

  @override
  String get habitTypeYesNo => 'Sim ou não';

  @override
  String get habitTypeYesNoExamples => 'Ex.: meditar, tomar a medicação, ler';

  @override
  String get habitTypeQuantitative => 'Quantitativo';

  @override
  String get habitTypeQuantitativeExamples =>
      'Ex.: beber água, caminhar, horas de estudo';

  @override
  String get formTitleLabel => 'Título';

  @override
  String get formTitleHintYesNo => 'Ex.: Meditar';

  @override
  String get formTitleHintQuantitative => 'Ex.: Beber água';

  @override
  String get formDescriptionLabel => 'Descrição (opcional)';

  @override
  String get formCategory => 'Categoria';

  @override
  String get formCustomCategorySwitch => 'Criar categoria personalizada';

  @override
  String get formCustomCategoryLabel => 'A tua categoria';

  @override
  String get formCustomCategoryHint => 'Ex.: Espiritualidade, Finanças';

  @override
  String get formUnitLabel => 'Unidade';

  @override
  String get formUnitHint => 'Ex.: L, kg, min';

  @override
  String get formDailyGoal => 'Meta diária';

  @override
  String get formReminder => 'Lembrete diário';

  @override
  String get formReminderSubtitle => 'Notificação à hora escolhida';

  @override
  String get formPickTime => 'Escolher hora';

  @override
  String get formSaveChanges => 'Guardar alterações';

  @override
  String get formCreate => 'Criar hábito';

  @override
  String get formValidation =>
      'Preenche o título, a categoria e a unidade (se for quantitativo).';

  @override
  String get formCreated => 'Hábito criado';

  @override
  String get formUpdated => 'Hábito atualizado';

  @override
  String get notificationPermissionDenied =>
      'Sem permissão para notificações. Ativa-a nas definições do telemóvel para receberes lembretes.';

  @override
  String get exactAlarmTitle => 'Lembretes à hora certa';

  @override
  String get exactAlarmMessage =>
      'Para os lembretes chegarem à hora exata, permite \"Alarmes e lembretes\" nas definições da app. Sem isso, o Android pode atrasá-los.';

  @override
  String get exactAlarmWarning =>
      'Os lembretes podem chegar atrasados: a app não tem permissão para alarmes exatos.';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortName => 'Nome';

  @override
  String get sortCategory => 'Categoria';

  @override
  String get sortProgress => 'Progresso de hoje';

  @override
  String get sortStreak => 'Sequência';

  @override
  String get sortNewest => 'Mais recentes';

  @override
  String get hideDone => 'Ocultar feitos';

  @override
  String get logQuestionToday => 'Fizeste este hábito hoje?';

  @override
  String get logPastDay => 'Registar o histórico deste dia';

  @override
  String get logRemoveDay => 'Remover o registo deste dia';

  @override
  String logTodayGoal(String goal) {
    return 'Registo de hoje · meta $goal';
  }

  @override
  String logPastGoal(String goal) {
    return 'Registo histórico · meta $goal';
  }

  @override
  String get logValueLabel => 'Valor atingido';

  @override
  String get logClearDay => 'Limpar o registo deste dia';

  @override
  String get reportTitle => 'Relatório';

  @override
  String get metricDaysDone => 'Dias feitos';

  @override
  String get metricDaysMissed => 'Dias falhados';

  @override
  String get metricSuccess => 'Sucesso';

  @override
  String get metricTrackedDays => 'Dias acompanhados';

  @override
  String get metricToday => 'Hoje';

  @override
  String get metricDailyAverage => 'Média diária';

  @override
  String get metricTotal => 'Total acumulado';

  @override
  String get metricBestDay => 'Melhor dia';

  @override
  String get reportTapToEdit => 'Toca num dia para editar o histórico.';

  @override
  String get reportTapToEditValues =>
      'Toca num dia para registar ou corrigir valores passados.';

  @override
  String get reportGoalProgress => 'Progresso da meta de hoje';

  @override
  String get reportGoalMet => '✓ meta atingida';

  @override
  String get reportEvolution => 'Evolução (últimos 30 dias)';

  @override
  String get chartGoal => 'Meta';

  @override
  String get calendarTitle => 'Calendário de progresso';

  @override
  String get legendDone => 'Feito';

  @override
  String get legendLogged => 'Registado';

  @override
  String get legendToday => 'Hoje';

  @override
  String get streakCurrent => 'Sequência atual';

  @override
  String get streakBest => 'Melhor sequência';

  @override
  String get streakTotal => 'Total';

  @override
  String dayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dias',
      one: 'dia',
      zero: 'dias',
    );
    return '$_temp0';
  }

  @override
  String get globalStreakBest => 'melhor:';

  @override
  String get todaySummaryTitle => 'Atividades de hoje';

  @override
  String get todayDone => 'Feitas';

  @override
  String get todayPercent => 'Percentagem';

  @override
  String get todayRemaining => 'Faltam';

  @override
  String tileGoal(String goal) {
    return 'Meta: $goal';
  }

  @override
  String tileTodayValue(String value, String goal) {
    return 'Hoje: $value / $goal';
  }

  @override
  String get tileDetails => 'Ver detalhes';

  @override
  String get notificationChannelName => 'Lembretes de hábitos';

  @override
  String get notificationChannelDescription =>
      'Notificações diárias para te lembrar dos teus hábitos';

  @override
  String get notificationTitle => 'Hora do hábito';
}
