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
      ? 'Cada exame tira 50 perguntas ao acaso. Sem contas, sem anúncios.'
      : 'Each exam draws 50 random questions. No accounts, no ads.';

  String get versionBadge => isPt ? 'VERSÃO 1.0 • 2026' : 'VERSION 1.0 • 2026';

  String get portuguese => 'Português';
  String get english => 'English';

  String get examPt => isPt ? 'Exame PT' : 'PT exam';
  String get examEn => isPt ? 'Exame EN' : 'EN exam';

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

  String countsLine(int ptCount, int enCount) =>
      '$ptCount PT • $enCount EN';

  String unseenLine(int n) => isPt
      ? '$n por ver neste ciclo'
      : '$n unseen in this cycle';

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
      ? '50 perguntas por exame • 45 minutos • Pausa guarda o progresso • Explicações no fim'
      : '50 questions per exam • 45 minutes • Pause keeps progress • Explanations at the end';

  String get privacy => isPt
      ? 'Sem contas, anúncios, analítica ou telemetria.'
      : 'No accounts, ads, analytics or telemetry.';

  String get remaining => isPt ? 'RESTANTE' : 'LEFT';
  String get questionLabel => isPt ? 'PERGUNTA' : 'QUESTION';
  String get prev => isPt ? 'Anterior' : 'Back';
  String get pause => isPt ? 'Pausar' : 'Pause';
  String get next => isPt ? 'Responder e avançar' : 'Answer and next';
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
  String get resumeBanner => isPt
      ? 'Tens um exame em pausa'
      : 'You have a paused exam';
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
  String get veryGood =>
      isPt ? 'Muito bom. Revisa o que falhou.' : 'Very good. Review what you missed.';
  String get goodEffort => isPt
      ? 'Bom esforço. Foca nos pontos fracos.'
      : 'Good effort. Focus on the weak spots.';
  String get loading => isPt ? 'A carregar a base…' : 'Loading the bank…';
  String get uiLang => isPt ? 'Idioma da interface' : 'Interface language';

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
