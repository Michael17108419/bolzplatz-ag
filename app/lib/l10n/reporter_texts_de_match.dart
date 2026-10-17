// The German texts of the radio reporter (step 10d2), part three: cards,
// injuries, changes, stoppage time, delays, half time, the final whistle and
// quiet phases. Keys and placeholders are explained in reporter_strings.dart.

const Map<String, List<String>> reporterMatchDe = {
  // ---------------------------------------------------------------- cards
  "yellow.own": [
    "Gelb für {p}. Kann man geben. Muss man aber nicht.",
    "Die gelbe Karte für unseren {p}. Der Schiri ist heute streng.",
    "{p} sieht Gelb. Das war ein taktisches Foul, und alle wissen es.",
    "Gelb {p}. Jetzt bitte vorsichtig, mein Lieber.",
    "Verwarnung für {p}. Er schaut, als hätte er den Ball gespielt. Hat "
        "er nicht.",
    "{p} holt sich Gelb ab. Etwas übermotiviert, der Gute.",
    "Gelb für {p}! Ach komm, Schiri, das war doch nichts!",
  ],
  "yellow.opp": [
    "Gelb für {p}. Völlig verdient, das war ein Tritt.",
    "Endlich! Gelb für {p}. Das hätte schon früher kommen müssen.",
    "{p} sieht Gelb. Der hat unseren Mann umgemäht.",
    "Die gelbe Karte für {p} von {team}. Weiter so, Schiri.",
    "Verwarnung {p}. Der hat jetzt was zu verlieren.",
    "Gelb für {p}. Er beschwert sich. Natürlich beschwert er sich.",
    "{p} wird verwarnt. Wer so reingeht, braucht sich nicht zu wundern.",
  ],
  "second.own": [
    "Gelb-Rot für {p}! Was macht er denn? Wir sind nur noch zu zehnt!",
    "Die zweite Gelbe für {p}! Das war so unnötig wie ein Kropf!",
    "{p} fliegt! Gelb-Rot! Ich könnte ihn schütteln!",
    "Platzverweis {p}, Gelb-Rot. Wer schon Gelb hat, muss sich das "
        "verkneifen!",
    "Gelb-Rot! {p} trottet vom Platz und darf früh duschen.",
  ],
  "second.opp": [
    "Gelb-Rot für {p}! {team} nur noch zu zehnt!",
    "Die zweite Gelbe für {p}! Tschüss!",
    "{p} muss runter, Gelb-Rot. Selbst schuld.",
    "Platzverweis! {p} sieht Gelb-Rot. Jetzt sind wir in Überzahl!",
    "Gelb-Rot für {p}. Er geht, und keiner bei uns weint.",
  ],
  "red.own": [
    "ROT! Rot für {p}! Das ist ein Schock!",
    "Glatt Rot für {p}! Das war zu viel, das muss man ehrlich sagen.",
    "Platzverweis {p}! Rot! Was hat er sich dabei gedacht?",
    "Rot für {p}! Er schüttelt den Kopf, aber das hilft jetzt auch nicht.",
    "Die Rote Karte für {p}! Wir müssen zu zehnt weitermachen!",
  ],
  "red.opp": [
    "ROT! Rot für {p}! Völlig zu Recht!",
    "Glatt Rot für {p}! Das war brutal, das war Absicht!",
    "Platzverweis {p}! {team} in Unterzahl!",
    "Rot für {p}! Der Schiri hat genau hingesehen!",
    "Die Rote Karte für {p}. Er protestiert. Er geht trotzdem.",
  ],
  "mem.cards.own": [
    "Schon die vierte Karte für uns. Wir sind heute die Holzfäller.",
    "Langsam wird's eng mit den Karten. Wir müssen uns zusammenreißen.",
    "Vier Karten für uns. Der Schiri hat schon einen Krampf im Arm.",
    "Unsere Karten-Sammlung wächst. Das wird teuer in der "
        "Mannschaftskasse.",
  ],
  "mem.cards.opp": [
    "Die vierte Karte für {team}. Das ist keine Mannschaft, das ist eine "
        "Abrissbirne.",
    "{team} sammelt Karten. Hoffentlich bald eine rote.",
    "Schon wieder eine Karte für {team}. Die treten heute alles, was "
        "sich bewegt.",
    "Vier Karten für {team}. Das ist kein Fußball mehr, das ist Kampfsport.",
  ],
  "wit.card.temper": [
    "{p} diskutiert noch. {p} diskutiert immer.",
    "Bei {p} ist die Zündschnur kürzer als ein Streichholz.",
    "{p} läuft rot an. Farblich passend zur nächsten Karte.",
    "Der Kapitän muss {p} wegziehen, sonst gibt's gleich die nächste.",
    "{p} schimpft auf den Schiri. Das hat noch nie jemandem geholfen.",
  ],
  "wit.card.aggression": [
    "{p} geht in jeden Zweikampf, als wäre es der letzte.",
    "Wenn {p} grätscht, wackelt die Tribüne.",
    "{p} spielt nicht auf Ball, {p} spielt auf Knochen.",
    "Man sagt, {p} hat im Training schon den Co-Trainer umgegrätscht.",
    "{p} hat die Zweikampfquote eines Mähdreschers.",
  ],

  // ------------------------------------------------------------- injuries
  "injury.own": [
    "{p} bleibt liegen. Das sieht nicht gut aus. Rund {days} Tage, "
        "schätzt die Bank.",
    "Oh nein, {p} hält sich das Knie. Die Betreuer kommen. Er fällt wohl "
        "{days} Tage aus.",
    "Verletzung bei {p}. Er humpelt vom Platz. {days} Tage Pause, heißt "
        "es.",
    "{p} hat Schmerzen. Ich hoffe, es ist nichts Schlimmes. Erste "
        "Prognose: {days} Tage.",
    "Das tut beim Zusehen weh. {p} muss behandelt werden, {days} Tage "
        "fällt er aus.",
  ],
  "injury.opp": [
    "{p} von {team} bleibt liegen. Gute Besserung, ehrlich.",
    "Verletzung bei {p}. Er muss behandelt werden.",
    "{p} hält sich den Oberschenkel. Das wird wohl nichts mehr.",
    "{team} muss sich um {p} kümmern. Das sah übel aus.",
    "{p} humpelt. Ob das echt ist? Ich will nichts unterstellen.",
  ],

  // -------------------------------------------------------------- changes
  "sub.own": [
    "Wechsel bei uns: {p} kommt für {q}.",
    "{q} geht runter, {p} kommt rein. Frische Beine!",
    "Der Trainer reagiert: {p} für {q}.",
    "{p} ersetzt {q}. Mal sehen, was er bewegt.",
    "Wechsel {team}: {q} raus, {p} rein. {q} klatscht ab, ohne "
        "hinzuschauen.",
    "{p} darf ran! {q} hat Feierabend.",
  ],
  "sub.own.late": [
    "Späte Einwechslung: {p} für {q}. Ein paar Minuten zum Glänzen.",
    "{p} kommt für {q}. Zeit gewinnen, das nennt man taktisch.",
    "{q} schleicht vom Platz, ganz langsam. {p} kommt. Die Uhr tickt.",
    "Noch ein Wechsel: {p} für {q}. Frisch gegen Müde.",
  ],
  "sub.opp": [
    "Wechsel bei {team}: {p} für {q}.",
    "{team} wechselt: {q} geht, {p} kommt.",
    "{p} kommt für {q}. {team} reagiert.",
    "Neuer Mann bei {team}: {p} ersetzt {q}.",
    "{q} geht vom Platz und lässt sich Zeit dabei. {p} kommt.",
    "{team} bringt {p} für {q}. Mal sehen.",
  ],
  "sub.opp.late": [
    "{team} wechselt spät: {p} für {q}. Und {q} geht sehr, sehr langsam.",
    "{p} kommt für {q}. Zeitspiel mit Ansage.",
    "Später Wechsel bei {team}: {p} für {q}.",
  ],
  "captain.own": [
    "Unser Kapitän {p} verlässt den Platz. Die Binde wandert weiter.",
    "Ohne {p} fehlt uns die Stimme. Wer redet jetzt mit dem Schiri?",
    "{p} geht, und mit ihm die Kapitänsbinde.",
    "Der Kapitän ist weg. Jetzt müssen andere vorangehen.",
  ],
  "captain.opp": [
    "Der Kapitän von {team}, {p}, muss runter.",
    "{team} ohne Kapitän {p}. Mal sehen, wer jetzt brüllt.",
    "{p} gibt die Binde ab. {team} verliert den Anführer.",
    "Kapitän {p} geht. Das schwächt {team}.",
  ],
  "tactic.own": [
    "Unser Trainer stellt um. Das Papier an der Seitenlinie raschelt.",
    "Taktische Änderung bei uns. Der Trainer gestikuliert wie ein "
        "Fluglotse.",
    "Umstellung bei {team}. Mal sehen, ob die Spieler mitkriegen, was "
        "gemeint ist.",
    "Der Trainer schreit Anweisungen auf den Platz. Neue Ordnung!",
  ],
  "tactic.opp": [
    "{team} stellt um. Der Trainer drüben hat einen Zettel gezückt.",
    "Taktische Änderung bei {team}. Wir müssen aufpassen.",
    "Bei {team} wird umgebaut. Die Bank ist in Aufruhr.",
    "Der Trainer von {team} reagiert. Er hat wohl einen Plan B. Oder "
        "einen Plan C.",
  ],

  // -------------------------------------------------------- stoppage time
  "added.half": [
    "Die vierte Offizielle hebt die Tafel: {n} Minuten Nachspielzeit in "
        "Halbzeit eins.",
    "{n} Minuten gibt's oben drauf bis zur Pause.",
    "Nachspielzeit: {n} Minuten. Dann gibt's Tee.",
    "{n} Minuten Nachschlag vor der Pause.",
  ],
  "added.lead": [
    "{n} Minuten Nachspielzeit! {n}! Woher nimmt der Schiri die?",
    "Die Tafel zeigt {n} Minuten. Wir führen. Bitte die Uhr schneller "
        "laufen lassen!",
    "{n} Minuten noch. Hinten dicht machen, Ball weg, Gebete sprechen.",
    "Nachspielzeit {n} Minuten. Jede Sekunde fühlt sich an wie eine "
        "Woche.",
    "{n} Minuten oben drauf. Ich zähle mit, jede einzelne.",
  ],
  "added.behind": [
    "{n} Minuten Nachspielzeit! Da geht noch was! Alles nach vorne!",
    "Die Tafel zeigt {n}. Genug Zeit für ein Wunder. Für zwei vielleicht.",
    "{n} Minuten! Kommt, Jungs, ein Tor, nur ein Tor!",
    "Nachspielzeit {n} Minuten. Noch ist nichts verloren!",
    "{n} Minuten noch. Der Torwart rückt bestimmt gleich mit auf.",
  ],
  "added.level": [
    "{n} Minuten Nachspielzeit. Wer will den Sieg mehr?",
    "Die Tafel zeigt {n} Minuten. Alles ist möglich.",
    "{n} Minuten oben drauf. Jetzt entscheidet sich's.",
    "Nachspielzeit: {n} Minuten. Ein Tor, und es ist vorbei.",
    "{n} Minuten noch, und es steht unentschieden. Spannender geht's "
        "kaum.",
  ],

  // ---------------------------------------------------------- time wasting
  "waste.keeper_eight_seconds.own": [
    "Unser Torwart hält den Ball zu lange! Acht Sekunden, Ecke für {opp}! "
        "Das war zu clever.",
    "Achtsekundenregel! Unser Keeper hat den Ball gestreichelt statt "
        "gespielt. Ecke {opp}.",
    "{p} trödelt mit dem Ball in der Hand. Der Schiri zählt bis acht. "
        "Ecke!",
    "Zeitspiel von unserem Torwart wird bestraft. Ecke für {opp}. "
        "Peinlich.",
  ],
  "waste.keeper_eight_seconds.opp": [
    "Der Torwart von {team} hält den Ball zu lange! Ecke für uns! Ha!",
    "Acht Sekunden sind um, {p} hat den Ball noch! Ecke für uns!",
    "Zeitspiel von {p} wird bestraft! Ecke! Gerechtigkeit!",
    "Der Schiri zählt runter, {p} will es nicht hören. Ecke für uns!",
  ],
  "waste.goal_kick_countdown.own": [
    "{p} lässt sich beim Abstoß ewig Zeit. Der Schiri gibt Ecke für "
        "{opp}! Übertrieben!",
    "Zu langsam beim Abstoß! Ecke für {opp}. Das war zu viel des Guten.",
    "{p} trödelt am Fünfer, der Schiri zählt runter. Ecke!",
    "Abstoß-Countdown abgelaufen. Ecke für {opp}. Wir haben uns "
        "verzockt.",
  ],
  "waste.goal_kick_countdown.opp": [
    "{p} bummelt beim Abstoß! Der Schiri gibt Ecke für uns!",
    "Zeitspiel beim Abstoß bestraft! Ecke für uns!",
    "{team} will Zeit schinden, der Schiri sagt nein. Ecke für uns!",
    "{p} sucht beim Abstoß noch die Schnürsenkel. Ecke für uns!",
  ],
  "waste.throw_in_countdown.own": [
    "{p} trödelt beim Einwurf, fünf Sekunden sind um. Einwurf für {opp}.",
    "Einwurf weg! {p} hat zu lange gewartet.",
    "Zu lange gezögert, {p}. Der Einwurf geht an {opp}.",
    "Der Schiri zählt beim Einwurf runter, {p} zählt nicht mit. Ball weg.",
  ],
  "waste.throw_in_countdown.opp": [
    "{p} trödelt beim Einwurf! Jetzt werfen wir ein!",
    "Fünf Sekunden um, {p} hat noch den Ball in der Hand. Einwurf für "
        "uns!",
    "Zeitspiel beim Einwurf bestraft! Ball für uns!",
    "{p} sucht beim Einwurf ewig, der Schiri wird ungeduldig. Einwurf "
        "für uns.",
  ],

  // ------------------------------------------------------------ half time
  "break.lead": [
    "Halbzeit! Wir führen mit {ours}! Ich gönne mir jetzt einen Kaffee.",
    "Pause! {ours} aus unserer Sicht. So kann's weitergehen!",
    "Halbzeitpfiff, {ours}. Gute erste Hälfte, aber noch ist nichts "
        "gewonnen.",
    "Pause beim Stand von {ours}. Die Kabine wird heute fröhlich.",
    "Der Schiri bittet zum Tee. {ours} für uns, und das ist verdient.",
  ],
  "break.behind": [
    "Halbzeit. {ours} aus unserer Sicht. Da muss jetzt was passieren.",
    "Pause beim Stand von {ours}. Der Trainer wird gleich laut.",
    "Halbzeitpfiff, {ours}. In der Kabine fliegen gleich die Teetassen.",
    "Pause. {ours}. Ich habe schon bessere Halbzeiten gesehen. Viel "
        "bessere.",
    "Halbzeit, {ours}. Kopf hoch, fünfundvierzig Minuten sind noch zu "
        "spielen.",
  ],
  "break.level": [
    "Halbzeit! {score}, alles offen.",
    "Pause beim Stand von {score}. Ein Spiel mit angezogener Handbremse.",
    "Halbzeitpfiff, {score}. Die zweite Hälfte muss mehr bringen.",
    "Pause, {score}. Ich hole mir eine Bratwurst. Sie holen sich bitte "
        "auch was.",
    "Halbzeit bei {score}. Beide Trainer haben viel zu besprechen.",
  ],
  "extra": [
    "Verlängerung! Dreißig Minuten mehr, und keiner hat mehr Luft.",
    "Es geht in die Verlängerung! Die Waden machen zu, die Herzen auf.",
    "Verlängerung! Ich habe kein Butterbrot mehr, aber egal!",
    "Noch nichts entschieden: Verlängerung! Die Trainer massieren "
        "persönlich.",
    "Ab in die Verlängerung. Wer jetzt einen Krampf hat, hat Pech.",
  ],

  // ------------------------------------------------------- the final whistle
  "full.win": [
    "Abpfiff! Wir haben gewonnen! {ours}! Ich liebe diese Mannschaft!",
    "Aus, aus, das Spiel ist aus! Sieg, {ours}!",
    "Schluss! Drei Punkte! {ours}! Heute Abend wird gefeiert!",
    "Der Schiri pfeift ab, {ours}. Ein Sieg, und was für einer!",
    "Ende! {ours}! Die Fans singen, die Spieler tanzen, ich weine ein "
        "bisschen.",
  ],
  "full.win.big": [
    "Abpfiff! {ours}! Das war eine Machtdemonstration!",
    "Schluss, {ours}! Wir haben sie auseinandergenommen!",
    "Aus! {ours}! Ich habe heute alle Superlative verbraucht!",
    "Ende, {ours}! So einen Tag vergisst man nicht!",
  ],
  "full.loss": [
    "Abpfiff. Wir haben verloren, {ours}. Das tut weh.",
    "Aus. {ours}. Heute hat es nicht gereicht.",
    "Schluss. Niederlage, {ours}. Kopf hoch, nächste Woche ist auch noch "
        "ein Spiel.",
    "Der Schiri pfeift ab, {ours}. Ich brauche jetzt Ruhe.",
    "Ende. {ours}. Die Spieler schleichen zur Kurve. Die Kurve klatscht. "
        "Ein bisschen.",
  ],
  "full.loss.big": [
    "Abpfiff. {ours}. Ich habe keine Worte. Wirklich keine.",
    "Aus. {ours}. Das war ein rabenschwarzer Tag.",
    "Schluss, {ours}. Ich empfehle allen Hörern einen Spaziergang.",
    "Ende, {ours}. Darüber wird in der Kabine noch lange geredet. Laut.",
  ],
  "full.draw": [
    "Abpfiff! {score}. Ein Punkt. Kann man mit leben.",
    "Aus! Unentschieden, {score}. Gerecht? Ach, wer weiß das schon.",
    "Schluss! {score}. Beide Teams teilen sich die Punkte.",
    "Ende, {score}. Ich hätte gerne mehr gehabt, aber gut.",
    "Der Schiri pfeift ab, {score}. Ein Punkt ist ein Punkt.",
  ],
  "full.draw.goalless": [
    "Abpfiff. 0:0. Neunzig Minuten Fußball, null Tore. Ich bin trotzdem "
        "erschöpft.",
    "Aus, 0:0. Die Torhüter waren die einzigen, die heute nicht frieren "
        "mussten. Oder doch?",
    "Schluss. 0:0. Für Taktikfans ein Fest, für alle anderen ein "
        "Nickerchen.",
    "Ende, 0:0. Wir halten die Null. Vorne auch.",
  ],
  "local.fulltime": [
    "Im Vereinsheim wird gleich der Grill angeworfen. Freibier gibt's "
        "trotzdem nicht.",
    "Die Spieler helfen jetzt beim Abbauen der Tore. So ist das hier.",
    "Der Platzwart schaut schon nervös auf den Rasen. Montag ist "
        "Jugendtraining.",
    "Die Zuschauer gehen zu Fuß nach Hause. Die meisten wohnen ja um "
        "die Ecke.",
    "Der Vorsitzende verteilt Schulterklopfer. Mehr gibt das Budget "
        "nicht her.",
  ],

  // ---------------------------------------------------------- quiet phases
  "calm.level": [
    "Ballgeschiebe im Mittelfeld. Beide warten auf den Fehler des anderen.",
    "Es ist ruhig gerade. Zu ruhig. Ich traue dem Frieden nicht.",
    "Querpass, Querpass, Rückpass. Spannend wie eine Steuererklärung.",
    "Beide Mannschaften neutralisieren sich. Fachleute nennen das "
        "taktische Disziplin, ich nenne es zäh.",
    "{score}, und auf dem Platz passiert gerade nicht viel.",
    "Das Spiel hat eine kleine Pause eingelegt, ohne den Schiri zu "
        "fragen.",
    "Viel Kampf, wenig Kunst im Moment.",
    "Ein Spiel zwischen zwei Strafräumen. Die Torhüter frieren.",
  ],
  "calm.level.late": [
    "Es steht {score}, die Zeit läuft. Wer traut sich?",
    "Keiner will den letzten Fehler machen. Das merkt man.",
    "{score} in der Schlussphase. Ein Tor, und das Ding ist entschieden.",
    "Die Beine werden schwer, die Köpfe auch.",
    "Es liegt was in der Luft. Oder es bleibt beim {score}.",
  ],
  "calm.lead": [
    "Wir lassen den Ball laufen. {team} hat alles im Griff.",
    "{ours} für uns, und wir verwalten das ganz entspannt.",
    "Ruhige Phase. Mir ist das recht, wir führen ja.",
    "Ballbesitz {team}, der Gegner rennt hinterher. Herrlich.",
    "Wir spielen das jetzt ganz erwachsen runter. Hoffentlich.",
    "Ballstafetten in der eigenen Hälfte. Der Gegner wird ungeduldig.",
    "Die Fans singen, der Ball läuft, {ours}. Kann so bleiben.",
  ],
  "calm.lead.late": [
    "Die Uhr ist unser Freund. Tick, tack.",
    "Wir führen {ours} und spielen auf Zeit. Nicht schön, aber effektiv.",
    "Noch ein paar Minuten. Bitte, bitte nichts mehr passieren lassen.",
    "Die Spieler nehmen sich Zeit für jeden Einwurf. Ich auch.",
    "Ich schaue häufiger auf die Uhr als auf den Platz.",
  ],
  "calm.behind": [
    "Wir finden gerade kein Mittel. {opp} steht gut.",
    "{ours} aus unserer Sicht, und es fehlt die zündende Idee.",
    "Ruhige Phase. Und das hilft uns gar nicht.",
    "Wir schieben den Ball hin und her, {opp} lässt uns machen.",
    "Es muss was passieren. Irgendwas. Bitte.",
    "{opp} verteidigt das souverän. Wir rennen an, prallen ab.",
    "Ideenlos. Ich sag's, wie es ist.",
  ],
  "calm.behind.late": [
    "Die Zeit läuft gegen uns. Jede Minute tut weh.",
    "{ours}. Noch ist es nicht vorbei, aber es wird eng.",
    "{opp} spielt auf Zeit, und wir haben keine Antwort.",
    "Alles nach vorne, aber vorne ist zu.",
    "Ich bete still. Laut hilft auch nicht.",
  ],
  "local.calm": [
    "Am Rand bellt ein Hund. Der Linienrichter erschreckt sich.",
    "Der Ball ist über den Zaun. Ein Ersatzspieler holt ihn aus dem "
        "Maisfeld.",
    "Vom Vereinsheim weht Grillduft herüber. Die Konzentration leidet. "
        "Meine jedenfalls.",
    "Ein Zuschauer ruft dem Schiri etwas zu, das ich hier nicht "
        "wiederholen darf.",
    "Der Platzwart läuft mit dem Rechen an der Seitenlinie entlang. Der "
        "hat auch nichts Besseres zu tun.",
    "Ein Traktor fährt hinter dem Sportplatz vorbei. Der ist schneller "
        "als unser Innenverteidiger.",
    "Die Bratwurst ist alle. Das sorgt auf den Rängen für mehr Unruhe "
        "als das Spiel.",
    "Auf der Tribüne – also auf den drei Bänken – wird gefachsimpelt.",
    "Ein Spieler bittet um eine Trinkpause. Der Kasten Wasser steht "
        "neben dem Opel vom Trainer.",
    "Das Flutlicht geht an. Zwei der vier Masten funktionieren.",
    "Die Kinder hinter dem Tor spielen gerade das bessere Spiel.",
    "Der Schiri bindet sich die Schuhe. Alle warten. Keiner beschwert "
        "sich. Das ist Amateurfußball.",
  ],
};
