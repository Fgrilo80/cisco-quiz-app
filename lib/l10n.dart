/// UI strings. Default language is Portuguese.
class S {
  const S(this.code);

  final String code;

  bool get isPt => code != 'en';

  static const pt = S('pt');
  static const en = S('en');

  static S of(String code) => code == 'en' ? en : pt;

  String get appTitle => 'Cisco Quiz';

  String get tagline => isPt
      ? 'Domine as certificações Cisco'
      : 'Master your Cisco certifications';

  String get subtitle => isPt
      ? 'Prática com feedback imediato, ou exame de 50 perguntas. Sem contas, sem anúncios.'
      : 'Practice with instant feedback, or a 50-question exam. No accounts, no ads.';

  String get versionBadge => isPt ? 'VERSÃO 1.1 • 2026' : 'VERSION 1.1 • 2026';

  String get portuguese => 'Português';
  String get english => 'English';

  String get practiceMode => isPt ? 'Prática' : 'Practice';
  String get examMode => isPt ? 'Exame' : 'Exam';

  String get practiceHint => isPt
      ? 'Mostra certo/errado e a explicação a seguir a cada resposta.'
      : 'Shows right/wrong and the explanation after each answer.';

  String get examHint => isPt
      ? '50 perguntas, 45 minutos. Sem revelar até ao fim.'
      : '50 questions, 45 minutes. No reveal until the end.';

  String get examPt => isPt ? 'Exame PT' : 'PT exam';
  String get examEn => isPt ? 'Exame EN' : 'EN exam';
  String get practicePt => isPt ? 'Prática PT' : 'PT practice';
  String get practiceEn => isPt ? 'Prática EN' : 'EN practice';

  String startPt({required bool exam}) => exam ? examPt : practicePt;
  String startEn({required bool exam}) => exam ? examEn : practiceEn;

  String get entryLevel => isPt ? 'ENTRY LEVEL' : 'ENTRY LEVEL';
  String get associate => 'ASSOCIATE';
  String get professional => 'PROFESSIONAL';

  String get ccstFull => 'Cisco Certified Support Technician';
  String get ccnaFull => 'Cisco Certified Network Associate';
  String get ccnpFull => 'Cisco Certified Network Professional';

  String get ccstFocus =>
      isPt ? 'Suporte e troubleshooting' : 'Support & troubleshooting';
  String get ccnaFocus =>
      isPt ? 'Routing, switching, security' : 'Routing, switching, security';
  String get ccnpFocus => isPt
      ? 'Enterprise, security, automation'
      : 'Enterprise, security, automation';

  String get ccstLevel => isPt ? 'Fácil a médio' : 'Easy to medium';
  String get ccnaLevel => isPt ? 'Fácil a avançado' : 'Easy to advanced';
  String get ccnpLevel => isPt ? 'Médio a expert' : 'Medium to expert';

  String questionsInBank(int n) =>
      isPt ? '$n perguntas na base' : '$n questions in the bank';

  String countsLine(int ptCount, int enCount) => '$ptCount PT • $enCount EN';

  String unseenLine(int n) =>
      isPt ? '$n por ver neste ciclo' : '$n unseen in this cycle';

  String get refreshTitle =>
      isPt ? 'Atualizar base (opcional)' : 'Refresh bank (optional)';

  String get refreshHint => isPt
      ? 'A app já inclui uma cópia offline. Podes ir buscar a versão mais recente no GitHub.'
      : 'The app already includes an offline copy. You can fetch the latest version from GitHub.';

  String get refreshNow => isPt ? 'Atualizar agora' : 'Refresh now';

  String get refreshing => isPt ? 'A atualizar…' : 'Refreshing…';

  String refreshOk(int total) => isPt
      ? 'Base atualizada. $total perguntas no total.'
      : 'Bank updated. $total questions in total.';

  String get refreshFail => isPt
      ? 'Não foi possível atualizar. A usar a cópia local.'
      : 'Could not refresh. Using the local copy.';

  String get bankUrlLabel => isPt ? 'URL da base' : 'Bank URL';

  String get footer => isPt
      ? 'Prática: feedback imediato • Exame: 50 perguntas, 45 min, revisão no fim • Labs CLI • Pausa guarda o progresso'
      : 'Practice: instant feedback • Exam: 50 questions, 45 min, review at the end • CLI labs • Pause keeps progress';

  String get privacy => isPt
      ? 'Sem contas, anúncios, analítica ou telemetria.'
      : 'No accounts, ads, analytics or telemetry.';

  String get remaining => isPt ? 'RESTANTE' : 'LEFT';
  String get questionLabel => isPt ? 'PERGUNTA' : 'QUESTION';
  String get prev => isPt ? 'Anterior' : 'Back';
  String get pause => isPt ? 'Pausar' : 'Pause';
  String get next => isPt ? 'Responder e avançar' : 'Answer and next';
  String get saveAndNext => isPt ? 'Guardar e avançar' : 'Save and next';
  String get finish => isPt ? 'Finalizar exame' : 'Finish exam';
  String get selectFirst => isPt
      ? 'Seleciona uma opção antes de avançar.'
      : 'Pick an option before moving on.';
  String get firstQ =>
      isPt ? 'Estás na primeira pergunta.' : 'You are on the first question.';
  String get correct => isPt ? 'Resposta correta!' : 'Correct!';
  String get incorrect => isPt ? 'Resposta incorreta' : 'Incorrect';
  String get correctAnswer => isPt ? 'Resposta correta:' : 'Correct answer:';
  String get explanation => isPt ? 'Explicação' : 'Explanation';
  String get paused => isPt ? 'Exame em pausa' : 'Exam paused';
  String get pausedHint => isPt
      ? 'O cronómetro está parado. O progresso fica guardado neste dispositivo.'
      : 'The timer is frozen. Progress is kept on this device.';
  String get resume => isPt ? 'Retomar' : 'Resume';
  String get home => isPt ? 'Início' : 'Home';
  String get goHomeConfirm => isPt
      ? 'Voltar ao início? Podes retomar este exame mais tarde.'
      : 'Go back home? You can resume this exam later.';
  String get cancel => isPt ? 'Cancelar' : 'Cancel';
  String get timeUp => isPt
      ? 'Tempo esgotado. O exame vai ser finalizado.'
      : 'Time is up. The exam will be finished.';
  String get emptyBank => isPt
      ? 'Não há perguntas para este exame.'
      : 'There are no questions for this exam.';
  String get loadFail => isPt
      ? 'Não foi possível carregar a base de perguntas. Tenta atualizar ou reinstalar a app.'
      : 'Could not load the question bank. Try refreshing or reinstalling the app.';
  String get resumeBanner =>
      isPt ? 'Tens um exame em pausa' : 'You have a paused exam';
  String get resumeBannerAction => isPt ? 'Continuar' : 'Continue';
  String get discardPaused => isPt ? 'Descartar' : 'Discard';
  String get newExamReplaces => isPt
      ? 'Começar um novo exame descarta o que está em pausa. Continuar?'
      : 'Starting a new exam discards the paused one. Continue?';
  String get points => isPt ? 'PONTOS' : 'SCORE';
  String get hits => isPt ? 'ACERTOS' : 'CORRECT';
  String get misses => isPt ? 'ERROS' : 'WRONG';
  String get timeUsed => isPt ? 'TEMPO' : 'TIME';
  String get doneTitle => isPt ? 'Exame concluído' : 'Exam complete';
  String get doneTitlePractice =>
      isPt ? 'Prática concluída' : 'Practice complete';
  String doneHeading({required bool exam}) =>
      exam ? doneTitle : doneTitlePractice;
  String get doneSub =>
      isPt ? 'Aqui está o teu desempenho' : 'Here is how you did';
  String get redo => isPt ? 'Novo conjunto' : 'New set';
  String get summaryTitle =>
      isPt ? 'Resumo por pergunta' : 'Per-question review';
  String get summaryHint =>
      isPt ? 'Toca para ver a explicação' : 'Tap to see the explanation';
  String get unanswered => isPt ? 'Não respondida' : 'Unanswered';
  String get yourAnswer => isPt ? 'A tua resposta' : 'Your answer';
  String get keepPracticing =>
      isPt ? 'Continua a praticar.' : 'Keep practicing.';
  String get excellent => isPt
      ? 'Excelente. Estás pronto para o exame.'
      : 'Excellent. You are exam-ready.';
  String get veryGood => isPt
      ? 'Muito bom. Revisa o que falhou.'
      : 'Very good. Review what you missed.';
  String get goodEffort => isPt
      ? 'Bom esforço. Foca nos pontos fracos.'
      : 'Good effort. Focus on the weak spots.';
  String get loading => isPt ? 'A carregar a base…' : 'Loading the bank…';
  String get uiLang => isPt ? 'Idioma da interface' : 'Interface language';

  String get labsTitle => 'Labs';
  String get labsSubtitle => isPt
      ? 'Terminal IOS interativo — comandos show, não Packet Tracer.'
      : 'Interactive IOS terminal — show commands, not Packet Tracer.';
  String get labsIntro => isPt
      ? 'Cada lab tem um terminal onde escreves comandos Cisco (? , enable, exit, show…). Descobre a resposta no output e escolhe a opção. Serve no telemóvel (scroll e teclado grande) e no Windows.'
      : 'Each lab has a terminal where you type Cisco commands (?, enable, exit, show…). Find the answer in the output and pick an option. Works on phone (scroll and large input) and Windows.';
  String get labHint => isPt ? 'Comando útil' : 'Useful command';
  String get labAnswer => isPt ? 'A tua resposta' : 'Your answer';
  String get labCheck => isPt ? 'Verificar' : 'Check';
  String get labBack => isPt ? 'Voltar aos labs' : 'Back to labs';
  String get labsOpen => isPt ? 'Abrir Labs' : 'Open Labs';

  String scoreComment(double pct) {
    if (pct >= 0.85) return excellent;
    if (pct >= 0.70) return veryGood;
    if (pct >= 0.50) return goodEffort;
    return keepPracticing;
  }

  String certTitle(String cert) {
    switch (cert) {
      case 'ccst':
        return 'CCST';
      case 'ccnp':
        return 'CCNP';
      default:
        return 'CCNA';
    }
  }
}
