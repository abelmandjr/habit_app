# Análise do projeto — habit_app

> Levantamento feito em 2026-09-24 sobre o commit `f6254ad` (branch `main`).
> O levantamento inicial (secções 1 a 5) foi feito só com leitura, sem alterar código.
> Atualizado em 2026-09-24: 2.ª ronda de decisões, roadmap reordenado e proposta do modelo v5 (secções 0, 6, 7 e 8).

---

## 0. Decisões tomadas

> Última atualização: 2026-09-24 (2.ª ronda de decisões). ⏳ = ainda por confirmar.
> As secções 1 a 5 descrevem o código no commit `f6254ad`. As secções 6 a 8 são o plano atual.

| # | Tema | Decisão |
|---|---|---|
| 1 | Objetivo | App de hábitos para **Android**, com **hábitos permanentes** e **projetos temporários**, **progresso visual** e **dados guardados online**. |
| 2 | Plataformas | **Só Android.** A pasta `ios/` fica como está, sem suporte ativo nem testes. As pastas `web/`, `windows/`, `linux/` e `macos/` são removidas na tarefa 1.11. |
| 3 | Migrações | A app nunca foi distribuída. O schema atual (v4) passa a ser a base (1.4) e todas as alterações novas ao modelo entram numa **única migração v5** (secção 7). |
| 4 | Dados | **Mudou: os dados passam a ser guardados online.** A arquitetura é **offline-first**: o Drift continua a ser a base local, a app funciona sem rede e sincroniza quando há rede. A sincronização e o login deixam de estar adiados e passam à Fase 4. **Backend: Supabase.** **Login: só Google** (o e-mail pode vir mais tarde). **A conta é obrigatória** desde o onboarding, por isso não há modo sem conta. |
| 11 | Dados de desenvolvimento | Os dados atuais do telemóvel podem ser apagados. **A v5 começa como base limpa**, sem migração de dados a partir da v4. |
| 5 | Idioma | **Português de Portugal (PT-PT)** em todos os textos. |
| 6 | Frequência | "Dias específicos da semana" e "X vezes por semana". **Os dias não programados não quebram o streak.** |
| 7 | Data de início | Passa a ser editável e os registos anteriores a ela são ignorados. |
| 8 | Riverpod | Manter o **Riverpod 2**. |
| 9 | Play Store | **Sim, mais tarde.** É preciso cumprir três requisitos: ter política de privacidade, preencher o formulário "Segurança dos dados" e permitir apagar a conta a partir da app. Por isso a app deixa de usar `USE_EXACT_ALARM` (1.10). |
| 10 | Novas funcionalidades | **Projetos**: duração ou data de fim, barra "Dia X de N", ecrã de conclusão, arquivar/repetir/tornar permanente, modelos de 21/30/66 dias. **Progresso visual**: anel nos quantitativos, barra nos projetos, mapa de calor anual, anel "X de Y" no dashboard. **Outras**: pausa/modo férias, saltar dia com limite, notas por registo, resumo semanal por notificação, widget Android, conquistas por sequência (7/30/100). |

**Estado do plano:** ✅ **aprovado em 2026-09-24.** A execução segue pela Fase 1 a partir da 1.5.
**Testes no dispositivo:** ✅ a 1.1 e a 1.2 foram verificadas em 2026-10-07 num Samsung SM-G986U (Android 13, fuso `Africa/Maputo`), com testes de integração automáticos. Os resultados estão na secção 9.
**Lembrete:** as dúvidas 5 a 18 da secção 8 são respondidas **no início da Fase 3**.

---

## 1. Resumo executivo

- App de hábitos **offline, só em Android/iOS**, com Riverpod 2 + go_router + Drift (SQLite). Cerca de 3 900 linhas de código próprio, sem contar o `.g.dart`. `flutter analyze` não encontra problemas.
- **O núcleo funciona**: criar, editar e eliminar hábitos (tipo *sim/não* ou *quantitativo*), marcar o dia, editar o histórico no calendário, streaks por hábito e globais, relatório com gráfico de 30 dias e lembretes diários.
- **Riscos críticos**: os lembretes são agendados em **UTC** e não na hora local; o swipe para eliminar dispara uma asserção do Flutter; a migração da BD a partir da v1 falha; a taxa de sucesso pode passar de 100 %; os erros assíncronos da UI não são apanhados.
- **Ainda não existe**: frequência não diária, tema escuro, onboarding, cores/ícones por hábito, backup/sincronização, login e i18n. Os textos misturam PT-BR e PT-PT.
- **Não há testes úteis**: o único teste é o do template do contador e falha. A cobertura real é **0 %**.

---

## 2. Stack e arquitetura

| Item | Valor |
|---|---|
| Flutter / Dart | Flutter **3.44.0** (stable) · Dart **3.12.0** · `sdk: ^3.12.0` |
| Arquitetura | *Feature-first* com nomes de Clean Architecture (`features/<f>/data`, `presentation`), **sem camada `domain`**. O repositório é uma classe concreta (`HabitRepositoryImpl`) sem interface. A entidade usada em toda a app é a classe gerada pelo Drift (`HabitData`). |
| Gestão de estado | **Riverpod 2.6** com `StateNotifier`/`StateNotifierProvider`, uma API *legacy* no Riverpod 3 |
| Navegação | **go_router**, com 4 rotas declaradas em [app_router.dart](lib/core/routes/app_router.dart): `/`, `/habits/new`, `/habits/:id` e `/habits/:id/edit` |
| Persistência | **Drift** (SQLite) via `drift_flutter`, `schemaVersion = 4`. Tabelas: `Habits`, `HabitCompletions` e `AppSettings` (chave/valor). |
| Tema | `flex_color_scheme` (esquema indigo), **apenas claro** |
| Notificações | `flutter_local_notifications` + `timezone`, com um lembrete diário por hábito |
| Plataformas | As pastas android/ios/web/windows/linux/macos existem. **Na prática só Android e iOS**: a Web não tem `sqlite3.wasm`/`drift_worker.js`, que o Drift exige. |

### Estrutura

```
lib/
├── main.dart
├── core/
│   ├── database/        app_database.dart (+ .g.dart)  ← tabelas, migrações E lógica de negócio
│   ├── models/          habit_type.dart
│   ├── notifications/   notification_service.dart
│   ├── providers/       database_provider.dart
│   ├── routes/          app_router.dart
│   ├── storage/         user_settings_service.dart     ← nome do utilizador + categorias
│   ├── theme/           light_theme.dart
│   └── utils/           date_utils, streak_calculator, habit_report_calculator
└── features/
    ├── dashboard/presentation/pages/dashboard_page.dart
    └── habits/
        ├── data/repositories/habit_repository_impl.dart
        └── presentation/{pages, providers, utils, widgets}
```

Existem também artefactos soltos: `ficheiroaa.bat`, um script de *scaffolding* versionado no git que cria pastas não usadas, e `assets/{animations,fonts,icons,images}`, pastas vazias e não declaradas no pubspec.

### Dependências

| Pacote | Versão atual → última | Função | Observação |
|---|---|---|---|
| flutter_riverpod | 2.6.1 → **3.4.3** | Estado | Migrar para a v3 é trabalho não trivial (StateNotifier → Notifier) |
| go_router | 17.2.3 → 18.0.1 | Rotas | OK |
| google_fonts | 8.1.0 → 8.2.1 | Fontes | ❌ **Não é usado** |
| flex_color_scheme | 8.4.0 → 9.0.0 | Tema | Usado |
| flutter_local_notifications | 21.0.0 → 22.3.1 | Lembretes | Usado |
| flutter_animate | 4.5.2 | Animações | Usado apenas em `StreakCard` |
| fl_chart | 1.x | Gráficos | Usado apenas no gráfico quantitativo |
| drift | 2.31.0 → 2.35.0 | ORM SQLite | Usado |
| drift_flutter | 0.2.7 → 0.3.1 | Abertura da BD | Usado |
| sqlite3_flutter_libs | 0.5.42 → 0.6.0+**eol** | Binários SQLite | Não é importado diretamente. O pacote está em *end-of-life* e deve ser revisto ao atualizar o Drift. |
| path_provider | 2.1.5 → 2.1.6 | Diretórios | ❌ **Não é usado** (será útil para exportar/fazer backup) |
| timezone | 0.11.0 → 0.11.1 | Fusos horários | Usado, mas mal configurado (ver bug A1) |
| uuid | 4.5.3 → 4.6.0 | IDs | Usado |
| cupertino_icons | 1.0.8 | Ícones iOS | ❌ Não é usado |
| drift_dev / build_runner (dev) | 2.31 / 2.6.1 | Geração de código | OK |
| flutter_lints (dev) | 6.0.0 | Lints | Conjunto padrão, sem regras extra |

---

## 3. Tabela de funcionalidades

| Funcionalidade | Estado | Ficheiros | O que falta |
|---|---|---|---|
| Criar hábito (assistente de 2 passos: tipo → detalhes) | ✅ Completa | `habit_form_page.dart`, `habit_provider.dart` (HabitFormNotifier) | Validação por campo (hoje só há um snackbar genérico). A meta só aceita inteiros ≥ 1. |
| Editar hábito | 🟡 Parcial | idem | O tipo não pode ser alterado (é intencional). Uma categoria personalizada já guardada aparece como "personalizada" em vez de no dropdown. Não é possível limpar a hora do lembrete. |
| Eliminar hábito | ⚠️ Com bugs | `dashboard_page.dart` (Dismissible), `habit_detail_page.dart` | Asserção "dismissed Dismissible still in tree" (A2). Não há *undo* nem arquivo. |
| Tipos de hábito (sim/não, quantitativo) | ✅ Completa | `habit_type.dart`, `app_database.dart` | Aceitar vírgula decimal (M5). Metas decimais. |
| Frequência (diária / semanal / dias específicos) | 🔴 Não existe | — | Tudo assume "todos os dias". É preciso alterar o modelo, os streaks, as estatísticas e os lembretes. |
| Marcar conclusão (hoje) | ✅ Completa | `habit_today_tile.dart`, `habit_log_sheet.dart`, `HabitListNotifier.logHabit` | Tratamento de erros (A5). O ecrã não atualiza depois da meia-noite (M3). |
| Histórico / editar dias passados | 🟡 Parcial | `streak_calendar.dart`, `habit_detail_page.dart` | O calendário volta ao mês atual depois de cada edição (M2). Permite registar dias anteriores à criação, o que distorce as estatísticas (M1). |
| Streaks por hábito | ✅ Completa | `streak_calculator.dart` | Não suportam frequências não diárias. Não têm testes. |
| Streak global (todos os hábitos cumpridos) | ✅ Completa | `habit_report_calculator.dart:172` | Ao eliminar um hábito, o histórico global muda retroativamente. |
| Estatísticas / gráficos | 🟡 Parcial | `habit_report_section.dart`, `habit_report_calculator.dart` | Gráfico só para hábitos quantitativos (30 dias). Faltam vistas semanais/mensais, estatísticas globais e um gráfico para sim/não. A taxa de sucesso pode passar de 100 %. |
| Notificações / lembretes | ⚠️ Com bugs | `notification_service.dart`, `AndroidManifest.xml` | Hora errada (UTC) (A1). Pedidos de permissão no arranque (M6). Tocar na notificação não faz nada. O lembrete toca mesmo com o hábito já feito. `USE_EXACT_ALARM` pode ser rejeitado pela Play Store. |
| Categorias | 🟡 Parcial | `user_settings_service.dart` | Não é possível renomear nem apagar categorias, nem filtrar por categoria. As categorias personalizadas são guardadas como uma string separada por `\n`. |
| Cores / ícones por hábito | 🔴 Não existe | — | Colunas no modelo, seletor na UI e uso no tile e no detalhe |
| Ordenar / filtrar lista | 🟡 Parcial | `habit_list_preferences.dart`, `habit_list_utils.dart`, `habit_list_controls.dart` | As preferências não são persistidas e perdem-se ao fechar a app. Não há ordenação manual (arrastar). |
| Nome do utilizador / saudação | ✅ Completa | `dashboard_page.dart:199`, `AppSettings` | — |
| Tema claro/escuro | 🔴 Só claro | `light_theme.dart`, `main.dart` | `darkTheme` e `themeMode`, e remover as cores *hardcoded* (tile, calendário) |
| Onboarding | 🔴 Não existe | — | Ecrãs iniciais, pedido de nome e permissão de notificações no momento certo |
| Backup / sincronização | 🔴 Não existe | — | Exportar/importar (JSON/ficheiro) e, eventualmente, a nuvem |
| Autenticação | 🔴 Não existe | — | Só faz sentido com sincronização na nuvem |
| Internacionalização | 🔴 Não existe | Textos *hardcoded* em todos os widgets | `flutter_localizations` + ARB. Os nomes de meses estão duplicados em 3 sítios. Há mistura de PT-BR ("Salvar", "Excluir", "registrar") com PT-PT ("registo", "Registar"). |
| Estados de carregamento, vazio e erro | 🟡 Parcial | `dashboard_page.dart`, `habit_detail_page.dart` | Carregamento e vazio: OK. Erro: só mostra `Erro: $e`, sem botão para tentar de novo. O erro do streak global é silencioso. |
| Testes | 🔴 Inexistentes | `test/widget_test.dart` | O teste do template falha e deve ser substituído |

---

## 4. Modelo de dados

Definido em [app_database.dart](lib/core/database/app_database.dart), `schemaVersion = 4`.

### `Habits` (classe gerada `HabitData`)
| Campo | Tipo | Notas |
|---|---|---|
| `id` | TEXT PK | UUID v4 ✅ |
| `title` | TEXT | |
| `description` | TEXT, default `''` | |
| `category` | TEXT | Texto livre. Não é FK para nenhuma tabela de categorias. |
| `habitType` | TEXT, default `'yesNo'` | `yesNo` \| `quantitative` |
| `unit` | TEXT? | Só nos quantitativos |
| `goalValue` | INT, default 1 | Inteiro. Os valores registados são `double`, o que é inconsistente. |
| `isCompleted` | BOOL | **Legado**. Só é usado na migração v1→v2 e deve ser removido. |
| `reminderHour` / `reminderMinute` / `reminderEnabled` | INT? / INT? / BOOL | Um único lembrete diário |
| `createdAt` | DATETIME, default now | Guardado como epoch (Drift) |

### `HabitCompletions` (classe gerada `HabitCompletion`)
| Campo | Tipo | Notas |
|---|---|---|
| `id` | INT autoincrement PK | |
| `habitId` | TEXT FK → Habits.id, `onDelete: cascade` | ⚠️ `PRAGMA foreign_keys` **não é ativado**, portanto o cascade não atua. O `deleteHabit` apaga manualmente e compensa. |
| `date` | TEXT `YYYY-MM-DD` | Data **local** do dispositivo, sem fuso horário |
| `loggedValue` | REAL? | 1 para sim/não, o valor registado para quantitativos |
| UNIQUE(`habitId`, `date`) | | `_completionRow` ainda remove duplicados, um resquício de versões antigas |

### `AppSettings`
Tabela chave/valor. Contém `user_name` e `custom_categories` (lista separada por `\n`).

### Problemas do modelo
1. **Migração v1 → v4 partida** (`app_database.dart:65-91`):
   - `createTable(habitCompletions)` já cria a coluna `logged_value`, e o passo `from < 3` volta a adicioná-la, o que dá "duplicate column".
   - `select(habits).get()` na linha 73 seleciona colunas (`habit_type`, `unit`) que ainda não existem.
   - `addColumn(createdAt)` com o default `currentDateAndTime` não é permitido em `ALTER TABLE` no SQLite.
   - As versões 2→4 e 3→4 parecem corretas.
2. **Faltam campos para funcionalidades previstas**: frequência/dias da semana, cor, ícone, ordem manual, `archivedAt`, `updatedAt`/`deletedAt` (necessários para sincronizar), vários lembretes.
3. **Datas**: a chave `YYYY-MM-DD` local é uma escolha razoável para hábitos diários. Não existe noção de fuso horário, por isso viajar entre fusos pode "saltar" ou repetir um dia. O "hoje" é calculado no momento da chamada e nunca é recalculado quando a app volta do *background*.
4. **Categorias sem tabela própria**: renomear uma categoria obriga a atualizar os hábitos por texto.
5. **Não há *schema dumps* nem testes de migração** (`drift_dev schema dump` / `SchemaVerifier`).
6. **Persistência**: os hábitos, os registos e as definições sobrevivem ao fecho da app. **As preferências da lista** (ordenação, "ocultar feitos") ficam só em memória e perdem-se.

---

## 5. Problemas de qualidade e bugs (por gravidade)

### 🔴 Alta
| # | Problema | Local | Detalhe |
|---|---|---|---|
| A1 | **Lembretes disparam à hora errada** | [notification_service.dart:27](lib/core/notifications/notification_service.dart#L27) | `tz.setLocalLocation(tz.local)` não faz nada, porque `tz.local` é UTC por omissão. Sem obter o fuso real do dispositivo (ex.: `flutter_timezone`), um lembrete às 09:00 toca às 09:00 **UTC**: 10:00 em Lisboa no verão, 06:00 em São Paulo. |
| A2 | **Swipe para eliminar provoca uma asserção** | [dashboard_page.dart:328](lib/features/dashboard/presentation/pages/dashboard_page.dart#L328), [habit_provider.dart:132-137](lib/features/habits/presentation/providers/habit_provider.dart#L132-L137) | `onDismissed` chama um `deleteHabit` assíncrono que invalida `globalStreakProvider` antes de remover o item da lista. O dashboard é reconstruído com o `Dismissible` já dispensado ainda na árvore, e o Flutter lança "A dismissed Dismissible widget is still part of the tree". É preciso remover o item do estado de forma síncrona (otimista) antes de aguardar a BD. |
| A3 ✅ | **Migração a partir da v1 falha** *(resolvido na 1.4)* | [app_database.dart:65-91](lib/core/database/app_database.dart#L65-L91) | Ver o ponto 1 do modelo de dados. Afeta apenas instalações com a BD v1, provavelmente só dispositivos de desenvolvimento. Se a app nunca foi distribuída, basta remover o caminho v1. |
| A4 | **O único teste falha e não existe cobertura** | [test/widget_test.dart](test/widget_test.dart) | É o teste do template do contador e nem usa `ProviderScope`. A lógica de streaks e estatísticas, que é a parte mais sensível, não tem testes. |
| A5 ✅ | **Erros assíncronos não apanhados na UI** *(corrigido na 1.3)* | [habit_log_sheet.dart:30-33, 48-51](lib/features/habits/presentation/widgets/habit_log_sheet.dart#L30-L51), [habit_provider.dart:93-96](lib/features/habits/presentation/providers/habit_provider.dart#L93-L96), [habit_provider.dart:584](lib/features/habits/presentation/providers/habit_provider.dart#L584), [habit_form_page.dart:326](lib/features/habits/presentation/pages/habit_form_page.dart#L326) | `logHabit` faz `rethrow`. O *sheet* já foi fechado e ninguém apanha o erro. `save()` tem `try/finally` sem `catch`. Qualquer falha na BD ou nas notificações vira uma exceção não tratada, sem feedback para o utilizador. |
| A6 ✅ | **`CircularDependencyError` ao marcar ou eliminar no dashboard** *(encontrado pelos testes da 1.5, corrigido na 1.12)* | [habit_provider.dart:86](lib/features/habits/presentation/providers/habit_provider.dart#L86), [habit_provider.dart:148](lib/features/habits/presentation/providers/habit_provider.dart#L148) | O `HabitListNotifier` faz `_ref.invalidate(globalStreakProvider)`, mas o `globalStreakProvider` depende do próprio `habitListProvider`. Em debug, o Riverpod lança o erro **depois** de gravar na BD, e o *reload* da lista e do detalhe não chega a correr. Em release a verificação está desligada. Solução: remover as duas invalidações, porque o `globalStreakProvider` já é recalculado quando a lista muda. |

### 🟠 Média
| # | Problema | Local | Detalhe |
|---|---|---|---|
| M1 ✅ | **A taxa de sucesso pode passar de 100 %** *(resolvido na 1.6)* e os "dias falhados" ficam errados | [habit_report_calculator.dart:92-95](lib/core/utils/habit_report_calculator.dart#L92-L95), [streak_calendar.dart:260-261](lib/features/habits/presentation/widgets/streak_calendar.dart#L260-L261) | O calendário permite registar dias **anteriores à criação**. `daysDone` conta esses dias, mas `trackedDays` só conta a partir de `createdAt`. Além disso, o dia de hoje conta como "falhado" antes de terminar. |
| M2 | **O calendário volta ao mês atual depois de cada edição** | [habit_report_section.dart:93-95, 206-208](lib/features/habits/presentation/widgets/habit_report_section.dart#L93-L95), [habit_detail_page.dart:160](lib/features/habits/presentation/pages/habit_detail_page.dart#L160) | A `ValueKey` usa `Set.hashCode`, que depende da identidade da instância, e as datas concluídas. Cada *refresh* recria o `StreakCalendar`, e o `_displayedMonth` volta a `now`. Isto torna muito incómodo editar meses antigos. |
| M3 | **O "hoje" fica desatualizado depois da meia-noite** | `habit_provider.dart` (nenhum listener de ciclo de vida) | Se a app ficar aberta ou em *background* a meia-noite passar, o dashboard continua a mostrar o dia anterior até um *pull-to-refresh*. |
| M4 | **Desempenho N+1** | [habit_repository_impl.dart:37-56](lib/features/habits/data/repositories/habit_repository_impl.dart#L37-L56), [habit_provider.dart:168-169](lib/features/habits/presentation/providers/habit_provider.dart#L168-L169) | Faz cerca de 6 queries por hábito em cada *reload*, e cada registo faz um *reload*. O `HabitDetailNotifier.refresh` carrega **todos** os hábitos para obter um só. O `globalStreakProvider` é recalculado 2× por ação (invalidate + watch). |
| M5 | **Não aceita vírgula decimal** | [habit_log_sheet.dart:234](lib/features/habits/presentation/widgets/habit_log_sheet.dart#L234) | O `FilteringTextInputFormatter` só permite `.`. Os teclados em português mostram `,`, e o `replaceAll(',', '.')` nunca chega a atuar. |
| M6 | **Permissões e política de alarmes** | [notification_service.dart:45-46](lib/core/notifications/notification_service.dart#L45-L46), `AndroidManifest.xml` | Pede permissão de notificações e de alarmes exatos em **cada arranque**, antes de o utilizador ter algum lembrete. `USE_EXACT_ALARM` é reservado a apps de alarme/calendário e pode levar à rejeição na Play Store. Para lembretes, `inexactAllowWhileIdle` costuma bastar. |
| M7 | **Fuga de providers** | [habit_provider.dart:75-77, 140](lib/features/habits/presentation/providers/habit_provider.dart#L75-L77) | `habitDetailNotifierProvider` é um `family` **sem autoDispose**. `logHabit` no dashboard instancia-o para cada hábito tocado, e cada instância faz um `refresh()` completo e fica viva para sempre, mesmo depois de o hábito ser eliminado. |
| M8 | **Lógica de negócio espalhada e duplicada** | `app_database.dart:189` (`isGoalMet`), `habit_report_calculator.dart:227` (`_isGoalMetSync`), `habit_provider.dart:119, 244` (otimista) | A regra "meta cumprida" está implementada em 4 sítios. A BD contém lógica de domínio (streaks, estatísticas). |
| M9 ✅ | **Web não funcional** *(resolvido na 1.11: a pasta `web/` foi removida)* | `web/` | O Drift na Web precisa de `sqlite3.wasm` e `drift_worker.js`, e as notificações também não funcionam na Web. Se a Web for um alvo, é preciso configurá-la. Se não for, recomenda-se remover a pasta. |
| M10 ✅ | **Streaks partem-se na mudança para a hora de verão** *(causa corrigida na 1.6)* *(encontrado ao preparar a 1.5)* | [streak_calculator.dart:44-58, 62-76](lib/core/utils/streak_calculator.dart#L44-L76), `date_utils.dart:30`, `habit_report_calculator.dart` | A aritmética de datas usa `subtract/add(Duration(days: 1))` e `difference().inDays` sobre `DateTime` locais. Em fusos com hora de verão (ex.: Lisboa, 29/03/2026), o dia da mudança tem 23 h: a sequência atual "salta" esse dia e a melhor sequência é subcontada. Não se reproduz nesta máquina (fuso sem hora de verão). Solução: fazer as contas com datas em UTC (`DateTime.utc(y, m, d)`) ou com `DateTime(y, m, d - 1)`. |

### 🟡 Baixa
| # | Problema | Local |
|---|---|---|
| B1 | A linha de tags do tile pode dar *overflow* com categorias longas: uma `Row` sem `Flexible` nem `Wrap` | [habit_today_tile.dart:87-105](lib/features/habits/presentation/widgets/habit_today_tile.dart#L87-L105) |
| B2 | Valores mostrados como `2.0` no tile (`'${item.todayValue}'`). No detalhe falta um espaço em "Meta: 2L/dia". | [habit_today_tile.dart:112](lib/features/habits/presentation/widgets/habit_today_tile.dart#L112), [habit_detail_page.dart:129](lib/features/habits/presentation/pages/habit_detail_page.dart#L129) |
| B3 | Cores *hardcoded* impedem o tema escuro | `habit_today_tile.dart:20-23`, `streak_calendar.dart:26-29`, `streak_card.dart` |
| B4 | Código morto: `AppDatabase.toggleToday`, `HabitRepositoryImpl.{toggleToday, setCompletion, setYesNoToday, setQuantitativeToday, getStreakStats}`, `HabitDetailNotifier.toggleToday`, `NotificationService.rescheduleAll`, `StreakCalendar.neutralFill`/`habitCreatedAt`/`initialMonth`, a coluna `isCompleted` | vários |
| B5 | `HabitFormState.copyWith` não consegue voltar a pôr `reminderTime` a `null` | `habit_provider.dart:401-433` |
| B6 | `HabitDetailPage` faz `ref.watch(habitListProvider)` sem necessidade, o que provoca *rebuilds* extra | [habit_detail_page.dart:17](lib/features/habits/presentation/pages/habit_detail_page.dart#L17) |
| B7 | Tocar na notificação não abre o hábito (`onDidReceiveNotificationResponse: (_) {}`) | `notification_service.dart:38` |
| B8 | Identidade da app por definir: `com.example.habit_app`, label `habit_app`, descrição "A new Flutter project." | `android/app/build.gradle*`, `AndroidManifest.xml`, `pubspec.yaml` |
| B9 | Ficheiros residuais: `ficheiroaa.bat` e pastas `assets/` vazias | raiz |
| B10 | `habit_provider.dart` tem 587 linhas com 3 notifiers e 2 estados, e deve ser dividido. O `StreakCard` repete a animação a cada registo. | — |

### Resumo de `flutter analyze`
`No issues found! (ran in 40.7s)`. Nota: usa apenas `flutter_lints` padrão. Regras mais estritas (ex.: `unawaited_futures`, `discarded_futures`, `prefer_final_locals`) apanhariam parte do A5.

### TODOs, FIXMEs e código comentado
Nenhum encontrado.

---

## 6. Roadmap

Esforço: **P** = até meio dia · **M** = 1–3 dias · **G** = mais de 3 dias
Estado: ✅ concluída · ⬜ por fazer · ⏳ depende de uma resposta (secção 8)

### Ordem das fases

```
Fase 1  Estabilidade (em curso)
   │
Fase 2  Fundações: camada de domínio, streams, PT-PT, tema escuro
   │
Fase 3  Modelo v5 (migração única) + motor de regras (frequência, pausa, saltos)
   │
   ├──► Fase 4  Conta e nuvem (offline-first)      ← recomendo fazer primeiro: é o objetivo "dados online"
   │
   └──► Fase 5  Projetos, progresso visual e motivação
                │
Fase 6  Publicação na Play Store (depois das Fases 4 e 5)
```

As Fases 4 e 5 dependem só da Fase 3 e podem trocar de ordem. Como o modelo v5 já inclui os campos de sincronização, as funcionalidades da Fase 5 não obrigam a outra migração.

### Fase 1: estabilidade
Ordem: 1.5 → **1.12** → 1.3 → **1.13** → **1.14** → 1.4 → 1.6 → 1.7 → 1.8 → 1.9 → 1.10 → 1.11

A 1.12 vem logo a seguir à 1.5 porque o bug A6 afeta as mesmas funções que a 1.3 vai alterar (`logHabit`, `deleteHabit`).

| # | Tarefa | Ficheiros | Esforço | Depende de |
|---|---|---|---|---|
| 1.1 ✅ | Fuso horário real do dispositivo (`flutter_timezone`). Os lembretes são reagendados ao arrancar. *(Concluída em 2026-09-24. Se o fuso não for reconhecido, a app continua em UTC. ✅ Verificada no dispositivo: alarme às 14:24 locais (12:24 UTC) e notificação às 14:24:01, ver secção 9.)* | `notification_service.dart`, `pubspec.yaml` | P | — |
| 1.2 ✅ | O swipe para eliminar retira o hábito do estado de forma síncrona e faz *rollback* se falhar. *(Concluída em 2026-09-24. O "Desfazer" fica opcional. O erro é mostrado ao utilizador na 1.3. Verificada pelo *widget test* do dashboard sobre o código real, depois da 1.12. Na 1.3 a eliminação passou para o `confirmDismiss`, para o *rollback* ser seguro. ✅ Verificada no dispositivo, ver secção 9.)* | `habit_provider.dart` | P | — |
| 1.5 ✅ | Base de testes: substituir o teste do template, testes unitários de `StreakCalculator`/`HabitReportCalculator` com relógio injetável e um *widget test* do dashboard com BD em memória. *(Concluída em 2026-09-24. São 20 testes: 16 passam e 4 estão marcados `skip`, 2 à espera da 1.6 (bug M1) e 2 à espera da 1.12 (bug A6). O relógio é injetado com o pacote `clock` e o `AppDatabase` aceita um executor. Os testes encontraram os bugs A6 e M10.)* | `test/`, `date_utils.dart`, `streak_calculator.dart`, `habit_report_calculator.dart`, `app_database.dart`, `pubspec.yaml` | M | — |
| 1.12 ✅ | **(nova)** Corrigir o bug A6: remover as duas `invalidate(globalStreakProvider)` do `HabitListNotifier` e reativar os 2 testes do dashboard. *(Concluída em 2026-09-24. O streak global continua a atualizar porque observa a lista e o `load(silent: true)` publica o estado novo depois de gravar. Há 2 testes novos para o banner, depois de marcar e depois de eliminar, e com uma verificação temporária confirmou-se que falham se essa dependência for removida. O `invalidate` do `HabitDetailNotifier.logForDate` fica, porque ali não há ciclo e é o que atualiza os registos de dias passados.)* | `habit_provider.dart`, `test/features/dashboard/dashboard_page_test.dart` | P | 1.5 |
| 1.13 ✅ | **(nova)** CI no GitHub Actions (`abelmandjr/habit_app`): `flutter analyze` e `flutter test` em Linux em cada *push* e *pull request*, com uma execução extra com `TZ=Europe/Lisbon`. Só começa a correr depois de o workflow ser enviado para o GitHub (*commit* + *push*, com a tua autorização). *(Preparada em 2026-10-07: `.github/workflows/ci.yaml` com Flutter 3.44.0 e `libsqlite3-dev`, YAML validado. ✅ **Primeira execução em 2026-10-07** (PR #1, branch `fase-1`): `push` e `pull_request` com sucesso em 116 s, incluindo o passo `TZ=Europe/Lisbon`. A CI corre só `flutter test test/`; os testes de integração ficam de fora porque precisam de dispositivo.)* | `.github/workflows/ci.yaml` | P | 1.5 |
| 1.14 ✅ | **(nova)** CI: `actions/checkout@v4` → `@v5`, por causa do aviso *"Node.js 20 is deprecated … actions/checkout@v4"* nas execuções do PR #1. *(Concluída em 2026-10-07, branch `fase-1b`. O `subosito/flutter-action@v2` é uma ação composite e não é afetado. ⚠️ A CI também avisa que o `ubuntu-latest` passa para o Ubuntu 26 a partir de 19/10/2026; confirmar então se o `libsqlite3-dev` continua disponível.)* | `.github/workflows/ci.yaml` | P | 1.13 |
| 1.15 ✅ | **(nova)** `.gitattributes` com fins de linha normalizados: `* text=auto eol=lf`, CRLF para `*.bat`/`*.cmd`/`*.ps1` e binários explícitos. *(Concluída em 2026-10-07, branch `fase-1b`. O `git add --renormalize .` não alterou nada, porque o repositório já guardava tudo em LF e só a pasta de trabalho estava em CRLF por causa do `core.autocrlf=true` do sistema. Por isso não houve commit de normalização. A pasta de trabalho foi reposta: 86 ficheiros de texto em LF e o `.bat` em CRLF. Acabaram as falsas alterações depois de `pub get`.)* | `.gitattributes` | P | — |
| 1.16 ✅ | **(nova)** Deixar de versionar `android/build/`: `android/build/reports/problems/problems-report.html` (relatório do Gradle) estava no repositório desde o commit inicial. *(Concluída em 2026-10-07: `/build/` adicionado ao `android/.gitignore`.)* | `android/.gitignore` | P | — |
| 1.3 ✅ | Tratamento de erros: `try/catch` no registo e no `save()`, SnackBar de erro, "Tentar de novo" nos estados de erro, lints `unawaited_futures`/`discarded_futures`. *(Concluída em 2026-09-24.* <br>• Helper `runWithErrorFeedback` + `ErrorRetryView` em `core/widgets/error_feedback.dart`. <br>• Registar, eliminar, guardar o hábito, guardar o nome e abrir para editar mostram mensagens em PT-PT. <br>• As atualizações otimistas são desfeitas na lista e no detalhe. <br>• Uma falha dos lembretes já não põe a lista em erro. <br>• Os lints novos estão ativos, com 0 avisos. <br>• Há 5 testes novos em `test/features/error_handling_test.dart`. <br>• Os testes encontraram um problema no *rollback* da 1.2: quando a eliminação falhava depressa, voltava a aparecer "dismissed Dismissible still in tree". A eliminação passou para o `confirmDismiss`.)* | `habit_log_sheet.dart`, `habit_provider.dart`, `habit_form_page.dart`, `dashboard_page.dart`, `analysis_options.yaml` | M | — |
| 1.4 ✅ | **(simplificada, decisão 11)** Migrações: remover os passos v1–v3. Qualquer BD mais antiga do que a versão base (4) é apagada e recriada (só há dados de desenvolvimento). Ativar `PRAGMA foreign_keys`. O *schema dump* e o `SchemaVerifier` passam para a 3.1. *(Concluída em 2026-10-07, branch `fase-1b`. Há 6 testes novos em `test/core/database/app_database_test.dart`: BD nova, BD v1 recriada, BD v4 mantida ao reabrir, chaves estrangeiras ativas, FK rejeita hábito inexistente, ON DELETE CASCADE. Contra o código antigo, o teste da v1 falha com `Cannot add a column with non-constant default`, o que confirma o bug A3.)* | `app_database.dart`, `test/core/database/` | P | — |
| 1.6 ✅ | Estatísticas corretas e causa do bug M10. *(Concluída em 2026-10-07, branch `fase-1b`.* <br>• **Data de início:** os registos anteriores ao início (`createdAt`, até à v5) são ignorados nas sequências, nas estatísticas, no streak global e em `getCompletionDates` (que alimenta o streak do tile). O calendário bloqueia os dias antes do início. <br>• **Hoje:** o dia atual por fazer já não conta como falhado, e a taxa só considera os dias avaliados. <br>• **M10:** todas as contas de dias usam `DateTime.utc(ano, mês, dia)` ou chaves `YYYY-MM-DD` (`HabitDateUtils.calendarDay/today/addDays/daysBetween`, `parseKey` em UTC). O streak global percorre os dias por chave. O `daysFromCreation`, que não era usado, foi removido. <br>• **Lembretes:** `NotificationService.nextInstanceOf` avança por campos de calendário em vez de somar 24 h. Antes, na véspera de uma mudança de hora, o lembrete ficava uma hora adiantado ou atrasado. <br>• **Testes:** `dst_test.dart` simula o dispositivo em Lisboa e em Nova Iorque com o pacote `timezone`, sem mudar o fuso do sistema. Os testes de controlo provam que a aritmética antiga falha nesses fusos (meia-noite menos 24 h salta 29/03 em Lisboa; de 08/03 a 15/03 em Nova Iorque `inDays` dá 6; somar 24 h às 09:00 dá 10:00). Os 2 testes do M1 foram reativados e há testes novos para a BD e o calendário. Ficam **55 testes, 0 ignorados**. <br>• **Limite:** numa máquina sem hora de verão, os testes com relógio simulado também passariam com o código antigo, porque este convertia para a hora local do sistema. A garantia vem de o código novo não usar `DateTime` locais nas contas, mais os testes de controlo e a execução da CI com `TZ=Europe/Lisbon`.)* | `date_utils.dart`, `streak_calculator.dart`, `habit_report_calculator.dart`, `app_database.dart`, `notification_service.dart`, `streak_calendar.dart`, `test/` | M | 1.5 |
| 1.7 ⬜ | O calendário mantém o mês ao editar | `habit_report_section.dart`, `habit_detail_page.dart`, `streak_calendar.dart` | P | — |
| 1.8 ⬜ | Recarregar ao voltar ao primeiro plano e quando muda o dia | `habit_provider.dart`, `main.dart` | P | — |
| 1.9 ⬜ | Aceitar vírgula decimal | `habit_log_sheet.dart` | P | — |
| 1.10 ✅ | **(opção 1, concluída em 2026-10-07)** Lembretes compatíveis com a Play Store, que funcionam assim: <br>• sai a `USE_EXACT_ALARM` e fica a `SCHEDULE_EXACT_ALARM`; <br>• ao ligar o primeiro lembrete, a app pede `POST_NOTIFICATIONS` e depois, com uma explicação curta, abre "Alarmes e lembretes"; <br>• se for recusado, o lembrete fica em modo inexato e o formulário mostra um aviso com o botão "Abrir definições"; <br>• ao voltar à app (`onShow`), se a permissão mudou, todos os lembretes são reagendados no modo certo. <br>Há 6 testes de widget e foi verificada no dispositivo nos casos permitido, recusado e recusado → permitido (secção 9). *(Histórico: a primeira versão, só com alarmes inexatos, mostrou atrasos inaceitáveis no dispositivo. A janela é 75 % do tempo até ao alarme e a notificação chegou no fim dela. Ver secção 9.)* | `notification_service.dart`, `habit_form_page.dart`, `AndroidManifest.xml` | P | 1.1 |
| 1.11 ✅ | Remover `web/`, `windows/`, `linux/` e `macos/`. A pasta `ios/` fica intacta. *(Concluída em 2026-10-07, branch `fase-1b`: 63 ficheiros removidos. `flutter build apk --debug`, `analyze` e `test` continuam a passar. As entradas destas plataformas em `.metadata` ficam, porque o ficheiro não deve ser editado à mão e só é usado pelo `flutter migrate`.)* | raiz | P | — |

### Fase 2: fundações
Prepara o código para o modelo novo e para a nuvem.

| # | Tarefa | Origem | Esforço | Depende de |
|---|---|---|---|---|
| 2.1 | **Camada de domínio**: entidades próprias (`Habit`, `HabitLog`…) separadas das classes do Drift, repositórios com interface (necessários para combinar a fonte local com a remota), uma única regra de "meta cumprida", dividir `habit_provider.dart` e usar `autoDispose` no detalhe | antes 2.1 | G | 1.5 |
| 2.2 | **Streams do Drift** (`watch()`) e queries agregadas em vez de N+1. Os ecrãs passam a atualizar-se sozinhos, o que é indispensável quando a sincronização altera dados em segundo plano. | antes 2.2 | M | 2.1 |
| 2.3 | Textos em PT-PT + ARB + `intl` (`pt_PT`) | antes 2.7 | M | — |
| 2.4 | Tema escuro + tokens de cor (base para as cores por hábito e para os componentes visuais da Fase 5) | antes 2.3 | M | — |
| 2.5 | Limpeza: dependências não usadas, código morto, `ficheiroaa.bat`, `assets/` vazio. A identidade da app passa para a 6.1 e a coluna `isCompleted` sai na migração 3.1. | antes 2.8 | P | — |
| 2.6 | Atualizar dependências antes de juntar os SDKs do backend (Riverpod 2 mantém-se) | antes 2.10 | M | 1.5 |
| 2.7 | Persistir as preferências da lista | antes 2.5 | P | — |

### Fase 3: modelo v5 e regras
| # | Tarefa | Esforço | Depende de |
|---|---|---|---|
| 3.1 | **Schema v5 como base limpa** (secção 7, decisão 11): definir as tabelas novas, adaptar o código às mudanças (`habit_logs`, `categoryId`, `goalValue` decimal) e gerar o primeiro *schema dump*, com o `SchemaVerifier` preparado para as migrações futuras. **Não há migração de dados**: uma BD v4 é apagada e recriada. *(Antes: M com migração de dados, cerca de 2 dias. Agora: M mais leve, cerca de 1 dia, quase só a adaptação do código.)* | M | 1.4, 2.1 |
| 3.2 | **Motor de regras no domínio** (Dart puro, sem Flutter). Responde se o hábito está programado num dia e dá o estado de cada dia: feito, parcial, falhado, saltado, em pausa, não programado ou fora do período. Calcula streaks diários (dias específicos) e semanais ("X por semana") e aplica o limite de saltos. Precisa de uma cobertura de testes alta. | G | 3.1, 1.5 |
| 3.3 | **Frequência na UI**: formulário (diária / dias da semana / X por semana), "Hoje" só com os hábitos programados para o dia e progresso semanal nos "X por semana" | M | 3.2 |
| 3.4 | Data de início editável no formulário (decisão 7), com aviso quando esconde registos | P | 3.1, 1.6 |
| 3.5 | **Pausa / modo férias**: pausar um hábito ou todos, com data de fim opcional. Os dias em pausa não contam para o streak e os lembretes ficam silenciados. | M | 3.2 |
| 3.6 | **Saltar dia com limite** (ex.: 1 por semana): ação no registo do dia e contador de saltos disponíveis. Um dia saltado não quebra nem soma ao streak. | M | 3.2 |
| 3.7 | **Notas** opcionais em cada registo (sheet de registo, calendário e detalhe) | P | 3.1 |
| 3.8 | **Cor e ícone** por hábito (seletor, e uso no tile, no detalhe e nos gráficos) | M | 3.1, 2.4 |
| 3.9 | Categorias numa tabela própria: renomear, apagar e filtrar (antes 2.4) | M | 3.1 |
| 3.10 | Lembretes só nos dias programados e fora das pausas. Tocar na notificação abre o hábito e não há lembrete se o hábito já estiver feito (antes 2.6). | M | 3.2, 3.5, 1.10 |

### Fase 4: conta e nuvem (offline-first)
| # | Tarefa | Esforço | Depende de |
|---|---|---|---|
| 4.1 | Configurar o **Supabase**: projetos dev/prod, tabelas Postgres iguais às da v5, **RLS** (`user_id = auth.uid()`), *trigger* que preenche `server_updated_at` e migrações SQL versionadas no repositório | M | 3.1 |
| 4.2 | **Login Google** (Supabase Auth + Google Sign-In no Android, com configuração do OAuth na Google Cloud e SHA-1 do *keystore*), sessão persistente, ecrã de conta e terminar sessão | M | 4.1 |
| 4.3 | **Motor de sincronização**, que funciona assim: <br>• marca as linhas alteradas no Drift (`isDirty`); <br>• envia-as em lote (*push*); <br>• recebe as alterações remotas desde a última sincronização, pelo `server_updated_at` (*pull*); <br>• em conflito, ganha a alteração com o `updatedAt` mais recente; <br>• as eliminações são `deletedAt` (*soft delete*); <br>• os dados chegam por ordem de dependência (categorias → hábitos → registos/pausas/conquistas); <br>• volta a tentar com *backoff*. <br>Sincroniza ao arrancar, ao recuperar a rede e depois de cada alteração (com *debounce*). Os testes usam um backend falso. | G | 4.1, 2.1, 2.2, 1.5 |
| 4.4 | **(simplificada, decisão 4: conta obrigatória)** Todas as linhas já nascem com `userId`, por isso não há dados anónimos para juntar. Resta: *pull* inicial completo ao entrar num dispositivo novo e limpeza da BD local ao terminar sessão ou mudar de conta. *(Antes: M. Agora: P.)* | P | 4.3 |
| 4.5 | **Apagar a conta a partir da app** (requisito da Play Store): dupla confirmação, depois apaga os dados remotos e a conta de autenticação (função no servidor) e por fim os dados locais. A Play Store também exige uma **página web** para pedir a eliminação. | M | 4.2 |
| 4.6 | Onboarding: boas-vindas, **login Google obrigatório** (o `go_router` redireciona para o login quando não há sessão), nome, primeiro hábito (com modelos) e permissão de notificações no momento certo (antes 3.4) | M | 4.2, 1.10 |
| 4.7 | Exportar/importar JSON local ⏳. Com a nuvem torna-se opcional e serve para portabilidade dos dados (antes 3.5). | M | 2.1, dúvida 5 |

### Fase 5: projetos, progresso visual e motivação
| # | Tarefa | Esforço | Depende de |
|---|---|---|---|
| 5.1 | **Projetos**: criar com duração em dias ou data de fim, modelos de 21/30/66 dias e **barra "Dia X de N"** no tile e no detalhe. Um projeto terminado sai de "Hoje". | G | 3.2, 3.3 |
| 5.2 | **Ecrã de conclusão**: resumo (taxa, melhor sequência, total, notas) e as ações **arquivar / repetir / tornar permanente** | M | 5.1 |
| 5.3 | **Anel de progresso** nos hábitos quantitativos (tile e detalhe) | P | 2.4 |
| 5.4 | **Anel "X de Y hábitos feitos hoje"** no dashboard (conta só os hábitos programados) | P | 3.3 |
| 5.5 | **Mapa de calor anual** no detalhe (53 semanas, com os estados pausa/saltado/não programado) | M | 3.2 |
| 5.6 | Estatísticas: gráfico para sim/não, taxa semanal e vista global (antes 2.9) | M | 3.2 |
| 5.7 | **Conquistas** por sequência (7/30/100): calculadas pelo motor de streaks e guardadas quando desbloqueadas, para sincronizarem e não se repetirem. Inclui uma lista de conquistas e um aviso ao desbloquear. | M | 3.2, 3.1 |
| 5.8 | **Resumo semanal** por notificação, calculado em segundo plano (`workmanager`) no dia e à hora configurados | M | 3.2, 1.10 |
| 5.9 | Arquivar hábitos e ordenação manual por arrastar (antes 3.3) | M | 3.1 |
| 5.10 | **Widget Android** (`home_widget` + Kotlin) com a lista de hoje e o anel. Só ver é **M**; marcar hábitos a partir do widget é **G** ⏳. | M/G | 2.2, 3.3 |

### Fase 6: publicação na Play Store
| # | Tarefa | Esforço | Depende de |
|---|---|---|---|
| 6.1 | Identidade: `applicationId` definitivo (**não pode mudar depois de publicar**), nome, ícone adaptativo e splash | P | dúvida 17 |
| 6.2 | **Política de privacidade** numa página pública (dados recolhidos, finalidade, backend, retenção, eliminação), com link na app e na Play Console | P | 4.1, dúvida 16 |
| 6.3 | Formulário **Segurança dos dados**: e-mail, ID do utilizador e dados da app; encriptação em trânsito; eliminação possível | P | 6.2 |
| 6.4 | Build de release: Play App Signing, AAB, `targetSdk` atual, R8, versionamento e revisão das permissões | P | 1.10 |
| 6.5 | Teste fechado. As contas pessoais de programador recentes precisam de um teste fechado com **12 testadores durante 14 dias** antes de poderem publicar em produção. Inclui relatórios de erros ⏳. | M | 6.4, dúvida 18 |

### Correspondência com o roadmap anterior
Antes 2.3 → 2.4 · 2.4 → 3.9 · 2.5 → 2.7 · 2.6 → 3.10 · 2.7 → 2.3 · 2.8 → 2.5 + 6.1 · 2.9 → 5.6 · 2.10 → 2.6 · 3.1 → 3.1–3.3 · 3.2 → 3.8 · 3.3 → 5.9 · 3.4 → 4.6 · 3.5 → 4.7 · 3.6 → Fase 4 · 3.7 → 5.10 · 3.8 cancelada.

---

## 7. Proposta de modelo de dados v5 (migração única)

### Princípios
- **As tabelas sincronizáveis têm todas as mesmas colunas extra:** `id` TEXT (UUID), `userId` TEXT NOT NULL (a conta é obrigatória), `createdAt`, `updatedAt` e `deletedAt` (UTC).
  - `isDirty` BOOL existe **só no dispositivo** e indica que a linha ainda não foi enviada.
  - Eliminar passa a ser *soft delete* (`deletedAt`). As linhas só são apagadas fisicamente depois de sincronizadas.
- **O servidor tem uma coluna a mais**, `server_updated_at`, preenchida pelo próprio servidor. Serve para o *pull* incremental e não é afetada por relógios de dispositivos errados.
- **Datas:** os dias de calendário são TEXT `YYYY-MM-DD` (dia local, como hoje). Os instantes são UTC.
- **Dias da semana** como máscara de bits: bit 0 = segunda … bit 6 = domingo.

### `habits` (alterada; recriada com `TableMigration`)
| Coluna | Tipo | Alteração | Para |
|---|---|---|---|
| `id`, `title`, `description`, `habitType`, `unit` | — | mantêm-se | |
| `categoryId` | TEXT? → `categories` | **nova**, substitui `category` (texto) | 3.9 |
| `goalValue` | REAL | **muda** de INT para REAL (metas decimais) | — |
| `color` | INT? (ARGB) | nova | 3.8 |
| `icon` | TEXT? | nova (chave de um catálogo fixo de ícones) | 3.8 |
| `startDate` | TEXT | nova, preenchida a partir de `createdAt` | 3.4 |
| `endDate` | TEXT? | nova: `null` = hábito permanente, com valor = **projeto** | 5.1 |
| `frequencyType` | TEXT, default `'daily'` | nova: `daily` / `weekdays` / `timesPerWeek` | 3.3 |
| `weekdaysMask` | INT? | nova | 3.3 |
| `timesPerWeek` | INT? | nova | 3.3 |
| `skipsPerWeek` | INT, default 1 ⏳ | nova (0 = não permite saltar) | 3.6 |
| `reminderEnabled/Hour/Minute` | — | mantêm-se | |
| `sortOrder` | INT, default 0 | nova | 5.9 |
| `archivedAt` | DATETIME? | nova | 5.2, 5.9 |
| `projectOutcome` | TEXT? | nova: `archived` / `repeated` / `madePermanent` | 5.2 |
| `repeatedFromId` | TEXT? | nova: ciclo anterior quando se escolhe "repetir" | 5.2 |
| `createdAt` + `updatedAt`, `deletedAt`, `userId` (NOT NULL), `isDirty` | | colunas de sincronização novas | 4.3 |
| ~~`isCompleted`~~ | | **removida** | |

Proposta para "repetir" um projeto: cria um hábito novo com a mesma configuração e datas novas, com `repeatedFromId` a apontar para o anterior, e arquiva o anterior. Assim cada ciclo fica com as suas estatísticas ⏳.

### `habit_logs` (substitui `HabitCompletions`; recriada)
| Coluna | Tipo | Notas |
|---|---|---|
| `id` | TEXT | **UUID determinístico** (v5 de `habitId|date`). Se dois dispositivos registarem o mesmo dia, geram o mesmo id e o registo não se duplica. Hoje é um INT autoincrement, que não funciona com sincronização. |
| `habitId` | TEXT → `habits` | |
| `date` | TEXT `YYYY-MM-DD` | UNIQUE(`habitId`, `date`) mantém-se |
| `loggedValue` | REAL? | |
| `status` | TEXT, default `'done'` | nova: `done` / `skipped`. Um `done` abaixo da meta conta como parcial. |
| `note` | TEXT? | nova (3.7) |
| colunas de sincronização | | Desmarcar um dia passa a ser *soft delete* |

### `habit_pauses` (nova, para a 3.5)
`id`, `habitId` TEXT? (`null` = **modo férias**, aplica-se a todos), `startDate`, `endDate` TEXT? (`null` = pausa sem fim definido), `reason` TEXT?, mais as colunas de sincronização.

### `categories` (nova, para a 3.9)
`id`, `name`, `color` INT?, `icon` TEXT?, `sortOrder`, `isDefault` BOOL, mais as colunas de sincronização.

### `achievements` (nova, para a 5.7)
`id` (determinístico: `habitId|type`), `habitId` TEXT? (`null` = conquista global ⏳), `type` (`streak_7`, `streak_30`, `streak_100`), `unlockedAt`, `seenAt`?, mais as colunas de sincronização.

### `profiles` (nova, 1 linha por utilizador, sincronizada)
`id` (= `userId`), `displayName` (vem de `AppSettings.user_name`), `weeklySummaryDay`/`weeklySummaryHour` (5.8), mais as colunas de sincronização.

### `AppSettings` (mantém-se, **só local**)
Guarda o que é do dispositivo e não sincroniza: tema, preferências da lista, onboarding concluído e os cursores de sincronização (`sync.lastPulledAt.<tabela>`).

### Como se chega à v5 (decisão 11: base limpa)
1. `schemaVersion = 5`. No `onUpgrade`, qualquer versão anterior apaga todas as tabelas e volta a criá-las (`m.createAll()`). Não se copiam dados.
2. As 6 categorias predefinidas são criadas na primeira utilização da conta, e não pela migração, para ficarem com o `userId`.
3. Gera-se o *schema dump* da v5 (`drift_dev schema dump`), que fica como referência. A partir daqui, todas as migrações (v6, …) são incrementais e testadas com o `SchemaVerifier`.

**Consequência da conta obrigatória (decisão 4):** `userId` pode ser **NOT NULL** em todas as tabelas sincronizáveis, porque nenhum dado é criado antes do login.

---

## 8. Dúvidas em aberto

> ⏰ **Lembrete: responder às dúvidas 5 a 18 no início da Fase 3**, antes da tarefa 3.1.

**Respondidas em 2026-09-24:** 1. Supabase · 2. Só Google · 3. Conta obrigatória · 4. Os dados de desenvolvimento podem ser apagados. A v5 começa como base limpa (ver a secção 0).

**Dados**

5. Com a nuvem, ainda queres **exportar/importar localmente** (4.7)?

**Regras**

6. **Saltar dia:**
   - O limite é por hábito ou global?
   - A semana vai de segunda a domingo?
   - Os saltos não usados acumulam?
   - Proposta: por hábito, 1 por semana por omissão e sem acumular.
7. **Pausa:**
   - Por hábito, global (férias) ou ambas? Proposta: ambas.
   - Durante uma pausa ainda se pode registar? Proposta: sim, e o registo conta como bónus.
8. **"X vezes por semana":**
   - O streak conta semanas cumpridas, e a semana atual só quebra o streak quando termina. Concordas?
   - Nas conquistas 7/30/100, estes hábitos contam dias feitos ou semanas?

**Projetos**

9. **"Repetir":** é um ciclo novo como hábito separado (proposta) ou reinicia o mesmo hábito?
10. Um projeto pode ser quantitativo e ter frequência não diária? Proposta: sim, com as mesmas opções dos hábitos. O "Dia X de N" conta dias de calendário.
11. Um projeto com muitos dias falhados "falha", ou os dias falhados ficam só nas estatísticas? Proposta: ficam só nas estatísticas.

**Conquistas, resumo e widget**

12. As conquistas são por hábito, globais (streak global) ou ambas?
13. **Resumo semanal:** em que dia e a que hora? Proposta: domingo às 20:00. O que deve mostrar?
14. **Widget:** basta ver o progresso (M), ou também queres marcar hábitos a partir dele (G)?

**Publicação**

15. Queres relatórios de erros (Crashlytics ou Sentry)?
16. Onde vais publicar a política de privacidade e a página de eliminação da conta (GitHub Pages, site próprio, Google Sites)?
17. Qual o `applicationId` definitivo (ex.: `com.<nome>.habitos`) e o nome da app na loja?
18. A tua conta de programador Google Play é pessoal ou de organização? Isto define se é obrigatório o teste com 12 testadores.

**Pendente da ronda anterior**

19. O resultado do teste da 1.1 no dispositivo chegou com o texto de exemplo. O lembrete chegou à hora certa?

---

## 9. Testes no dispositivo (2026-10-07)

**Dispositivo:** Samsung SM-G986U (`R5CN20X9KPP`), Android 13 (API 33), ligado por USB.
Os testes de integração estão em `integration_test/`. O teste do fluxo usa uma **BD em memória**, por isso não toca nos dados reais da app.

### Como correr (forma padrão)

**Regra do projeto: os testes de integração correm sempre com `--no-uninstall`.** Os testes unitários (`flutter test test/`) não precisam de dispositivo e são os que a CI corre.

```bash
ADB="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
"$ADB" devices -l                                   # R5CN20X9KPP device model:SM_G986U
"$ADB" -s R5CN20X9KPP shell pm grant --user 0 com.example.habit_app android.permission.POST_NOTIFICATIONS
flutter test --no-uninstall integration_test/habit_flow_test.dart          -d R5CN20X9KPP
flutter test --no-uninstall integration_test/reminder_test.dart            -d R5CN20X9KPP
# Precisa de orquestração com adb (ver a secção da 1.10 mais abaixo):
"$ADB" -s R5CN20X9KPP shell appops set com.example.habit_app SCHEDULE_EXACT_ALARM deny
flutter test --no-uninstall integration_test/exact_alarm_resume_test.dart  -d R5CN20X9KPP
```

> ⚠️ **Porquê `--no-uninstall`.**
> - **O que acontece sem a opção:** o `flutter test` desinstala a app no fim de cada execução que passa. Isto apaga os dados e a permissão de notificações.
> - **Porque bloqueia:** neste Samsung, a primeira abertura depois de uma instalação limpa recria a `MainActivity` (no logcat: `LauncherApps: onPackageAdded` e logo a seguir `FlutterJNI was detached`). O teste fica ligado ao isolate antigo, que já não desenha frames, e bloqueia até ao *timeout*.
> - **Padrão observado sem a opção:** as execuções alternam entre passar e bloquear.
> - **Com a opção:** 4 execuções seguidas passaram, todas em cerca de 5 s.

### 1.2 / 1.12: fluxo completo (`habit_flow_test.dart`) ✅
Criar o hábito pela UI (FAB → "Sim ou não" → título → "Criar hábito"), marcá-lo e eliminá-lo com swipe.
- A lista mostra o hábito e o ícone ✓. O banner passa de `0 dias · melhor: 0 dias` para `1 dia · melhor: 1 dia`.
- Ao eliminar com swipe não aparece nenhuma exceção (`takeException() == null`). A lista volta ao estado vazio e o banner a 0.
- Resultado: `00:05 +1: All tests passed!`, 4 vezes seguidas.

### 1.1: lembrete à hora local (`reminder_test.dart`) ✅
| Verificação | Comando | Resultado |
|---|---|---|
| Fuso do telemóvel | `adb shell getprop persist.sys.timezone` | `Africa/Maputo` (CAT, UTC+2) |
| Fuso detetado pela app | marcador `IT_REMINDER` | `tz=Africa/Maputo` |
| Agendamento | `IT_REMINDER scheduled` | `now=14:22:15`, `target=14:24:00` (hora local) |
| Alarme no sistema | `adb shell dumpsys alarm` | `RTC_WAKEUP … com.example.habit_app`, `origWhen=2026-10-07 14:24:00.000`, `exactAllowReason=policy_permission`. O *epoch* `1791375840000` corresponde a **12:24 UTC = 14:24 CAT** ✅ |
| Repetição diária | `dumpsys alarm` (histórico) | depois de disparar às 14:21, o alarme da execução anterior foi reagendado para `2026-10-08 14:21:00` ✅ |
| Notificação | `adb shell dumpsys notification --noredact` | `pkg=com.example.habit_app id=679040680 channel=habit_reminders`, `android.title=Hora do hábito`, `android.text=Teste de lembrete`, `when=1791375840053` (14:24:00.05) ✅ |
| Chegada | `IT_REMINDER arrived` | **14:24:01**, 1 s depois da hora marcada |
| Limpeza | `dumpsys alarm` depois do teste | nenhum alarme pendente da app ✅ |

**Com o bug antigo** (`tz.local` = UTC), o mesmo lembrete ficaria agendado para as 14:24 **UTC**, ou seja **16:24 em Maputo**: 2 h depois da hora marcada.

### Observações novas
- O build mostra este aviso: *"Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): flutter_timezone"*. Versões futuras do Flutter vão deixar de compilar com ele. Fica para a 2.6 (atualizar dependências): atualizar o `flutter_timezone` ou trocá-lo.
- Os testes do lembrete correram **com alarmes exatos**, que é o comportamento antes da 1.10. Depois da 1.10 (alarmes inexatos), o atraso tem de ser medido de novo com o mesmo teste.

### 1.10: lembrete com alarme inexato (mesmo teste, depois da 1.10) (antes da decisão)
| Verificação | Resultado |
|---|---|
| Permissões de alarme exato (`dumpsys package`) | já não existem |
| Alarme (`dumpsys alarm`) | `origWhen=14:30:00`, **`window=+1m3s563ms`**, `maxWhenElapsed=+2m22s`. Sem `exactAllowReason` |
| Chegada | agendado às 14:28:35 para as 14:30:00, chegou às **14:31:05** (+65 s, no **fim** da janela) |

**Conclusão:** o Android dá aos alarmes inexatos uma janela de **75 % do tempo entre o agendamento e a hora do alarme**, e neste telemóvel entregou-o no fim da janela. Para um lembrete diário isto significa atrasos de **horas**: a janela chega a cerca de 18 h quando o lembrete do dia seguinte é reagendado depois de disparar. **Não serve para lembretes.**

**Opções para fechar a 1.10:**
1. **(Recomendada) `SCHEDULE_EXACT_ALARM` pedido ao utilizador.**
   - Ao ligar o primeiro lembrete, a app verifica `canScheduleExactAlarms()`. Se a permissão faltar, explica porque precisa dela e abre o ecrã "Alarmes e lembretes" das definições.
   - Com a permissão, os lembretes são exatos. Sem ela, ficam inexatos e a app avisa que podem atrasar.
   - É compatível com a Play Store: a declaração especial só é exigida para `USE_EXACT_ALARM`.
   - No Android 14+, a permissão vem desligada por omissão nas instalações novas, por isso o pedido na UI é necessário.
   - Esforço: P.
2. **Manter `USE_EXACT_ALARM`:** os lembretes são exatos e o utilizador não tem de fazer nada. A Play Store reserva esta permissão a apps de alarme e de calendário, por isso há risco de rejeição.
3. **Manter os alarmes inexatos:** não precisa de permissões, mas os lembretes podem chegar horas mais tarde.

**Decisão (2026-10-07): opção 1.** Implementada e verificada abaixo.

### 1.10: `SCHEDULE_EXACT_ALARM` pedido ao utilizador ✅
Simulação do Android 14+ com `adb shell appops set com.example.habit_app SCHEDULE_EXACT_ALARM deny|allow`.

| Caso | `appops get` | `dumpsys alarm` | Chegada |
|---|---|---|---|
| Permitido (`reminder_test`) | `allow` | `origWhen=14:42:00.000 window=0 exactAllowReason=permission` | 14:42:01, **+1 s** |
| Recusado (`reminder_test`) | `deny` | `origWhen=14:50:00.000 window=+47s751ms`, sem `exactAllowReason` | 14:50:51, **+51 s** (fim da janela) |
| Recusado → permitido → voltar à app (`exact_alarm_resume_test`) | `deny` → `allow` | antes: `origWhen=15:17:00.000 window=+22m2s675ms`. Depois de `appops allow`, HOME e `am start`: **`window=0 exactAllowReason=permission`** | o teste confirma `rescheduled=true` |

Notas:
- **A reinstalação repõe o appop.** Quando a versão anterior não declarava a permissão, a reinstalação repôs o appop no valor por omissão (concedido no Android 13). O `deny` tem de ser aplicado **depois** de instalada a versão que declara `SCHEDULE_EXACT_ALARM`.
- **O primeiro `onResume` não reagendou.** Ao voltar à app, o Flutter recebeu `inactive, hidden, paused, hidden, inactive`, sem nunca chegar a `resumed` porque a janela não tinha foco, e o listener com `onResume` não disparou. A app passou a usar **`onShow`** (`hidden` → `inactive`), que não depende do foco. O teste falha se o reagendamento não acontecer.
- **Revogar a permissão** com a app aberta faz o Android parar a app e cancelar os alarmes exatos. No arranque seguinte, a primeira carga da lista reagenda tudo no modo certo.
