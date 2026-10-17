// The German texts of the radio reporter (step 10d2), part two: shots,
// goals, saves, misses, set pieces and lost balls. Keys and placeholders are
// explained in reporter_strings.dart.

const Map<String, List<String>> reporterShotsDe = {
  // --------------------------------------------- the moment before the shot
  "shot.close_range.0": [
    "{p} an der Strafraumkante, zieht ab …",
    "{p} legt sich den Ball zurecht, sechzehn Meter …",
    "Schuss {p} von der Strafraumgrenze …",
    "{p} fackelt nicht lange, Schuss aus achtzehn Metern …",
    "{p} nimmt Maß von der Kante …",
    "{p} schaut kurz hoch und schießt …",
  ],
  "shot.close_range.1": [
    "{p} im Strafraum, Schuss …",
    "{p} kommt zum Abschluss, zwölf Meter …",
    "{p} dreht sich und schießt …",
    "{p} steht frei im Sechzehner – und …",
    "{p} hat nur noch den Torwart vor sich …",
    "Abschluss {p}, aus elf Metern …",
    "{p} nimmt ihn direkt …",
  ],
  "shot.close_range.2": [
    "{p} am Fünfer, den muss er …",
    "{p} aus drei Metern …",
    "{p} steht ganz allein vor dem Tor …",
    "Der Ball liegt {p} vor den Füßen, Fünfmeterraum …",
    "{p} muss nur noch den Fuß hinhalten …",
    "{p} am langen Pfosten …",
  ],
  "shot.close_range": [
    "{p} kommt zum Schuss …",
    "Abschluss {p} …",
    "{p} zieht ab …",
    "{p} probiert's …",
  ],
  "shot.long_shot": [
    "{p} fasst sich ein Herz, aus der Distanz …",
    "{p} zieht aus fünfundzwanzig Metern ab …",
    "Fernschuss {p} …",
    "{p} probiert es einfach mal von weit weg …",
    "{p} hat keinen Bock mehr auf Kombinieren, Schuss aus der zweiten "
        "Reihe …",
    "{p} legt sich den Ball vor und hält drauf …",
    "Da steht keiner bei {p}, also: Vollspann aus der Distanz …",
  ],
  "shot.header.1": [
    "{p} steigt hoch, Kopfball …",
    "Kopfball {p} …",
    "{p} schraubt sich hoch …",
    "{p} mit dem Kopf …",
    "{p} hechtet in die Flanke …",
  ],
  "shot.header.2": [
    "{p} am Fünfer mit dem Kopf …",
    "{p} köpft aus kurzer Distanz …",
    "{p} nickt ein … oder?",
    "{p} steht völlig blank, Kopfball …",
  ],
  "shot.header": [
    "Kopfball {p} …",
    "{p} kommt mit dem Kopf dran …",
    "{p} drückt die Stirn gegen den Ball …",
  ],
  "shot.header.set": [
    "Der Ball kommt rein, {p} steigt hoch …",
    "Getümmel im Strafraum, {p} mit dem Kopf …",
    "{p} setzt sich im Luftkampf durch, Kopfball …",
    "Die Flanke senkt sich, {p} ist da …",
    "Hoch in den Strafraum, {p} köpft …",
  ],
  "free.up": [
    "{p} läuft an, Freistoß direkt …",
    "{p} schaut auf die Mauer, schaut aufs Tor, Anlauf …",
    "Freistoß {p}, über die Mauer …",
    "{p} zirkelt ihn …",
    "{p} legt sich den Ball zurecht, nimmt fünf Schritte Anlauf …",
  ],

  // --------------------------------------------------------- half chances
  "half.own": [
    "{p} versucht es, aber der Ball holpert am Tor vorbei.",
    "Halbchance {p}, mehr Wunsch als Wirklichkeit.",
    "{p} schießt, der Ball rollt dem Torwart in die Arme. Immerhin aufs "
        "Tor.",
    "{p} probiert es aus spitzem Winkel. Na ja.",
    "Abschluss {p} – ein Rückpass zum gegnerischen Torwart.",
    "{p} zieht ab, der Ball fliegt Richtung Parkplatz.",
    "Ein Schüsschen von {p}. Da hat der Torwart mehr Spaß als Arbeit.",
    "{p} mit dem Versuch, die Fans klatschen aus Höflichkeit.",
  ],
  "half.opp": [
    "{p} versucht es, kein Problem für uns.",
    "Harmloser Schuss von {p}.",
    "{p} zieht ab, deutlich drüber. Gut so.",
    "Halbchance {team}, {p} trifft den Ball nicht richtig.",
    "{p} probiert's, unser Torwart fängt sicher.",
    "{p} schießt aus der Drehung, vorbei. Kein Grund zur Panik.",
    "Ein Versuch von {p}, eher für die Statistik.",
    "{p} schießt, und unser Keeper gähnt.",
  ],

  // ---------------------------------------------------------------- goals
  "goal.own.e1": [
    "Tor! Tor für {team}!",
    "Drin! Der ist drin!",
    "Und der Ball zappelt im Netz! Tor für {team}!",
    "Tooor! Ganz ruhig, ganz sicher, ganz wunderbar!",
    "Treffer! {team} trifft!",
    "Da ist das Ding! Tor!",
  ],
  "goal.own.e2": [
    "TOOOR! TOOOR für {team}!",
    "Ja! JA! Der ist drin!",
    "Tooor! Ich fasse es nicht, der Ball ist im Netz!",
    "DRIIIN! Was für ein Moment!",
    "Tor, Tor, Tor! {team}!",
    "Der sitzt! Der sitzt! TOOOR!",
  ],
  "goal.own.e3": [
    "TOOOOOOR! TOOOOOOR! ICH HAB KEINE STIMME MEHR!",
    "JAAAA! DRIIIN! Das Stadion explodiert!",
    "TOR! TOR! TOR! Ich umarme gerade meinen Techniker!",
    "WAAAHNSINN! Der ist drin! Der ist wirklich drin!",
    "TOOOR! Was ist hier los? Meine Damen und Herren, was ist hier los?",
    "JAAA! Das ist Fußball! Genau dafür sind wir alle hier!",
  ],
  "goal.opp.e1": [
    "Tor für {team}. Mist.",
    "Und da ist es passiert. {team} trifft.",
    "Der ist drin. Leider.",
    "Tor {team}. Das war zu einfach.",
    "Gegentor. Da hat keiner aufgepasst.",
    "Der Ball ist im Netz – im falschen.",
  ],
  "goal.opp.e2": [
    "Nein! Tor für {team}!",
    "Oh nein, der ist drin!",
    "Verdammt! {team} trifft!",
    "Das darf nicht wahr sein, Tor {team}!",
    "Bitter, bitter. Tor für {team}.",
    "Der schlägt ein. Ich muss mich kurz setzen.",
  ],
  "goal.opp.e3": [
    "NEIN! NEIN! Tor für {team}! Ich glaub's nicht!",
    "Das ist brutal. Tor {team}. In dieser Phase!",
    "Mir fehlen die Worte. Tor für {team}.",
    "Nein, nein, nein! Der ist drin! Was für ein Schlag!",
    "Totenstille bei uns. Tor {team}.",
    "Das tut weh. Das tut richtig weh. Tor für {team}.",
  ],
  "scorer.own": [
    "Torschütze: {p}! Was für ein Kerl!",
    "{p} hat getroffen! Lasst ihn hochleben!",
    "Der Name des Torschützen: {p}! Merken Sie sich den!",
    "{p}! Natürlich {p}!",
    "Getroffen hat {p}, und er rennt Richtung Kurve!",
    "{p} war's! Er reißt sich das Trikot vom Leib – Gelbgefahr, egal!",
    "Torschütze {p}, der lässt sich feiern.",
    "{p}! Ich könnte ihn knutschen!",
  ],
  "scorer.opp": [
    "Getroffen hat {p}.",
    "Torschütze: {p}. Der hatte zu viel Platz.",
    "{p} war's. Niemand hat ihn gestört.",
    "Der Torschütze heißt {p}. Den Namen wollte ich heute eigentlich "
        "nicht sagen.",
    "{p} trifft und jubelt vor unserer Kurve. Das hätte er sich sparen "
        "können.",
    "{p} hat getroffen. Man muss es anerkennen.",
    "Das Tor erzielt {p}, sauber gemacht, leider.",
  ],
  "scorer": [
    "Torschütze: {p}.",
    "Getroffen hat {p}.",
    "{p} war's.",
  ],
  "assist.own": [
    "Die Vorlage kam von {q}, bitte auch klatschen!",
    "{q} hat ihn aufgelegt, ganz feine Arbeit.",
    "Vorbereitet von {q}, der Mann für die unsichtbaren Dinge.",
    "Und die Vorlage: {q}! Ein Fleißkärtchen für {q}!",
    "{q} mit der Vorarbeit. Ohne ihn kein Tor.",
    "Vorlagengeber {q}, der jubelt fast mehr als der Schütze.",
  ],
  "assist.opp": [
    "Vorbereitet hat {q}.",
    "Die Vorlage kam von {q}. Den hätte man stören müssen.",
    "{q} legt auf, viel zu einfach.",
    "Die Vorarbeit leistete {q}.",
    "{q} mit dem Pass, den keiner verhindert hat.",
  ],
  "assist": [
    "Vorlage: {q}.",
    "Aufgelegt hat {q}.",
  ],

  // ------------------------------------------------------ what a goal means
  "ctx.lead.own": [
    "Wir führen! {score}!",
    "Die Führung für {team}! {score}!",
    "Endlich vorne! {score}!",
    "{score}. Das fühlt sich gut an.",
    "Führung, {score}, und das völlig verdient!",
  ],
  "ctx.lead.opp": [
    "{team} geht in Führung. {score}.",
    "Rückstand für uns. {score}.",
    "{score}. Jetzt müssen wir kommen.",
    "Wir liegen hinten, {score}. Kopf hoch!",
    "{team} führt mit {score}. Das war so nicht geplant.",
  ],
  "ctx.lead.early.own": [
    "Nach wenigen Minuten führen wir! {score}! Manche sitzen noch beim "
        "Bierholen!",
    "Blitzstart! {score}, bevor die Leute überhaupt Platz genommen haben!",
    "Was für ein Start! {score}!",
  ],
  "ctx.lead.early.opp": [
    "Kaltstart. {score}, und wir haben den Ball noch nicht mal berührt.",
    "{score} nach ein paar Minuten. Hat jemand den Anpfiff verschlafen?",
    "Frühes Gegentor, {score}. Das nennt man dann einen Weckruf.",
  ],
  "ctx.lead.late.own": [
    "In der Schlussphase! Wir führen {score}! Jetzt bloß nichts mehr "
        "anbrennen lassen!",
    "Das könnte der Sieg sein! {score}, kurz vor Schluss!",
    "Spät, aber nicht zu spät! {score}! Ich bin heiser!",
    "{score}! So spät! Das ist das Tor des Tages!",
  ],
  "ctx.lead.late.opp": [
    "Kurz vor Schluss geht {team} in Führung. {score}. Grausam.",
    "{score}. Das war's dann wohl. Oder?",
    "So spät noch. {score}. Ich brauche einen Schnaps.",
    "Das Gegentor in der Schlussphase, {score}. Das tut doppelt weh.",
  ],
  "ctx.equal.own": [
    "Der Ausgleich! {score}! Alles wieder offen!",
    "Ausgleich! {score}! Es geht wieder von vorne los!",
    "Wir sind wieder da! {score}!",
    "{score}! Der Ausgleich, und den haben wir uns verdient!",
    "Gleichstand! {score}! Jetzt wird's spannend!",
  ],
  "ctx.equal.opp": [
    "Der Ausgleich für {team}. {score}.",
    "Alles wieder auf Anfang, {score}.",
    "{score}. Die Führung ist weg.",
    "{team} gleicht aus, {score}. Das war unnötig.",
    "{score}. Wir müssen wieder von vorne anfangen.",
  ],
  "ctx.equal.late.own": [
    "Der späte Ausgleich! {score}! Ich habe nie daran gezweifelt! Fast "
        "nie!",
    "Last-Minute-Ausgleich! {score}! Wer jetzt schon gegangen ist, ist "
        "selber schuld!",
    "{score}! In letzter Sekunde! Ich liebe diesen Sport!",
    "Ausgleich kurz vor Schluss! {score}! Das Stadion bebt!",
  ],
  "ctx.equal.late.opp": [
    "Der späte Ausgleich für {team}. {score}. Das ist bitter.",
    "{score}, so kurz vor Schluss. Zwei Punkte weg, einfach so.",
    "Ausgleich in der Schlussphase, {score}. Ich könnte heulen.",
    "{score}. Wir hatten es in der Hand.",
  ],
  "ctx.extend.own": [
    "Wir legen nach! {score}!",
    "Das nächste Tor! {score}!",
    "{score}! Jetzt läuft's!",
    "Und noch einer! {score}!",
    "{score}! Da kann man sich langsam zurücklehnen. Langsam.",
  ],
  "ctx.extend.opp": [
    "{team} legt nach. {score}.",
    "{score}. Das wird schwer.",
    "Das nächste Gegentor, {score}.",
    "{score}. Wo ist unsere Abwehr? Ich frage für einen Freund.",
    "{team} baut aus, {score}. Langsam wird's eng.",
  ],
  "ctx.extend.late.own": [
    "Die Entscheidung! {score}! Das ist durch!",
    "{score} kurz vor Schluss! Den Deckel drauf!",
    "Das war's! {score}! Ab jetzt wird nur noch gefeiert!",
  ],
  "ctx.extend.late.opp": [
    "Das ist wohl die Entscheidung. {score}.",
    "{score}. Der Deckel ist drauf, leider auf unserem Topf.",
    "Aus und vorbei. {score}.",
  ],
  "ctx.cut.own": [
    "Der Anschlusstreffer! {score}! Da geht noch was!",
    "Nur noch ein Tor! {score}!",
    "{score}! Wir leben noch!",
    "Anschluss! {score}! Jetzt alles nach vorne!",
  ],
  "ctx.cut.opp": [
    "Der Anschlusstreffer für {team}. {score}. Jetzt nicht nervös werden.",
    "{score}. Es wird noch mal eng.",
    "{team} kommt ran, {score}. Das muss nicht sein.",
    "Nur noch ein Tor Vorsprung, {score}. Konzentration!",
  ],
  "ctx.rout.own": [
    "{score}! Das wird eine Gala!",
    "{score}! Kann man das Ergebnis noch steigern? Wir arbeiten dran!",
    "{score}! Die Gegner suchen schon den Bus!",
    "{score}! Das ist eine Demonstration!",
  ],
  "ctx.rout.opp": [
    "{score}. Das ist eine Lehrstunde.",
    "{score}. Ich möchte mich bei allen Hörern entschuldigen.",
    "{score}. Kann man das Spiel abbrechen? Aus Mitleid?",
    "{score}. Das wird eine lange Busfahrt.",
  ],

  // -------------------------------------------------------- goal memory
  "mem.brace": [
    "Das zweite Tor von {p} heute!",
    "Doppelpack {p}!",
    "{p} schon wieder! Zweites Tor!",
    "Zwei Tore für {p}. Heute ist sein Tag.",
    "{p} schnürt den Doppelpack!",
  ],
  "mem.hattrick": [
    "HATTRICK {p}! Drei Tore! Den Ball darf er mit nach Hause nehmen!",
    "Dreierpack {p}! Unfassbar!",
    "{p} mit dem Hattrick! Sowas sieht man nicht alle Tage!",
    "Das dritte Tor von {p}! Holt den Mann vom Platz, bevor er "
        "unbezahlbar wird!",
  ],

  // ---------------------------------------------------------- goal wit
  "wit.goal.header_monster": [
    "Ein Kopfball von {p}. Der Mann hat einen Schädel wie ein Rammbock.",
    "{p} köpft, wie andere schießen. Kopfballungeheuer!",
    "Wenn der Ball in der Luft ist, gehört er {p}. Immer.",
    "{p} mit der Stirn – die ist härter als der Pfosten.",
  ],
  "wit.goal.long_shooter": [
    "Aus der Distanz! Das ist das Markenzeichen von {p}.",
    "{p} und Fernschüsse, das ist eine Liebesgeschichte.",
    "Wer {p} aus zwanzig Metern schießen lässt, hat selbst schuld.",
    "{p} schießt aus der Distanz, als wäre es ein Elfmeter.",
  ],
  "wit.goal.goal_poacher": [
    "Typisch {p}: Steht da, wo der Ball hinfällt. Riecht er das?",
    "{p}, der Abstauber vom Dienst. Fünf Meter, ein Kontakt, Tor.",
    "{p} läuft neunzig Minuten nicht und trifft trotzdem. Kunst!",
    "Torjäger-Instinkt pur. {p} weiß, wo der Ball landet, bevor der Ball "
        "es weiß.",
  ],
  "wit.goal.media_hunger": [
    "{p} läuft sofort zur Kamera. Der Jubel war garantiert einstudiert.",
    "Und {p} formt mit den Händen ein Herz. Für die Kamera, nicht für uns.",
    "{p} jubelt mit dem eigenen Hashtag. Den kennt man schon vom Training.",
    "{p} sucht die Fernsehkamera. Gefunden. Pose. Fertig.",
    "{p} zeigt auf seinen Namen auf dem Rücken. Als ob wir den nicht "
        "kennen würden.",
  ],
  "wit.goal.egoism": [
    "Nebenbei: Links war einer frei. Aber {p} hat ihn nicht gesehen. Nie.",
    "{p} jubelt allein. Die Mitspieler kommen erst später, verständlich.",
    "Abspielen war für {p} nie eine Option. Heute zahlt es sich aus.",
    "{p} küsst das eigene Wappen. Das auf seinem Schienbeinschoner.",
  ],
  "wit.goal.party": [
    "Und das, obwohl {p} gestern bis drei Uhr im Club gesichtet wurde.",
    "{p} trifft! Die Nacht war offenbar nicht zu lang.",
    "{p} jubelt mit dem Tanz aus der Disco. Den kennt man inzwischen.",
    "Sein Restalkohol hat {p} heute offenbar beflügelt.",
  ],
  "wit.goal.consistency": [
    "{p} trifft! Nächste Woche trifft er wahrscheinlich wieder die "
        "Eckfahne.",
    "Ausgerechnet {p}. Man weiß nie, welchen {p} man bekommt. Heute den "
        "guten.",
    "{p}, der Mann der Wundertüten. Heute war ein Treffer drin.",
    "Diesmal hat's geklappt, {p}. Bitte notieren, man weiß ja nie.",
  ],

  // ---------------------------------------------------------------- saves
  "save.own": [
    "Gehalten. Der Torwart von {opp} ist auf dem Posten.",
    "Pariert! Mist.",
    "Der Keeper hat ihn. Schade.",
    "Gute Parade, das muss man anerkennen.",
    "Gehalten! Der Schuss war zu zentral.",
    "Der Torwart von {opp} lenkt ihn über die Latte.",
  ],
  "save.own.big": [
    "NEIN! Wie hat er den gehalten? Wie?",
    "Was für eine Parade! Ich raufe mir die Haare!",
    "Gehalten! Der Torwart von {opp} macht sich riesig! Das gibt's nicht!",
    "Den muss er machen! Aber der Keeper fliegt und hat die Finger dran!",
    "Unglaublich! Mit dem Fuß gerettet! Der Torwart hat heute Pakt mit "
        "dem Teufel!",
    "Neeein! Der hält alles, der Mann! Alles!",
  ],
  "save.opp": [
    "Gehalten! Unser Torwart ist da!",
    "Sicher gefangen. Ganz ruhig, alles im Griff.",
    "Parade! Danke, Torwart!",
    "Unser Keeper hält, als wäre es Training.",
    "Abgewehrt! Gut aufgepasst.",
    "Unser Mann im Tor faustet ihn weg.",
  ],
  "save.opp.big": [
    "WAHNSINN! Was für eine Parade von unserem Keeper!",
    "Den hält er! Den hält er wirklich! Ich will seine Hände vergolden!",
    "Weltklasse-Reflex! Unser Torwart rettet uns!",
    "Unfassbar! Mit den Fingerspitzen an den Pfosten!",
    "Der Keeper ist ein Krake! Acht Arme, mindestens!",
    "Gehalten! Das war eigentlich ein Tor! Unser Torwart sagt Nein!",
  ],
  "mem.keeper.own": [
    "Unser Torwart hat heute mehr zu tun als der Bratwurstverkäufer.",
    "Die nächste Parade unseres Keepers. Der hält uns hier im Spiel.",
    "Wenn wir heute was holen, gehört das Denkmal unserem Torwart.",
    "Unser Keeper wird zum Mann des Spiels. Freiwillig hat er sich das "
        "nicht ausgesucht.",
  ],
  "mem.keeper.opp": [
    "Der Torwart von {team} hält heute einfach alles. Hat der Magneten "
        "in den Handschuhen?",
    "Schon wieder der Keeper von {team}. Wir schießen uns warm, er "
        "wird heiß.",
    "Der Mann im Tor von {team} hat heute Spaß. Wir eher nicht.",
    "Wieder pariert. Der Torwart von {team} wird heute Abend auf "
        "Händen getragen.",
  ],

  // -------------------------------------------------------------- blocked
  "block.own": [
    "Geblockt! Da war noch ein Bein dazwischen.",
    "Abgefälscht, Ecke? Nein, abgeblockt.",
    "Der Schuss klatscht an einen Verteidiger.",
    "Ein Bein, ein Körper, eine Mauer. Geblockt.",
    "Da wirft sich einer rein. Kein Durchkommen.",
    "Geblockt! Der Abwehrspieler von {opp} hat Schmerzen und Ruhm.",
  ],
  "block.opp": [
    "Geblockt! Da wirft sich einer von uns rein!",
    "Der Ball prallt an unserem Verteidiger ab. Der wird morgen blaue "
        "Flecken haben, egal!",
    "Abgeblockt! Das ist Einsatz!",
    "Unser Mann wirft sich in den Schuss. Heldentat!",
    "Kein Durchkommen, geblockt!",
    "Mit dem Körper dazwischen. Danke!",
  ],

  // ---------------------------------------------------------------- misses
  "miss.own": [
    "Vorbei. Knapp, aber vorbei.",
    "Drüber!",
    "Neben das Tor. Schade.",
    "Der Ball fliegt am Pfosten vorbei.",
    "Daneben. Das war nicht genau genug.",
    "Über die Latte. Die Tauben auf dem Dach haben sich erschreckt.",
    "Vorbei! Ach, Mensch.",
  ],
  "miss.own.big": [
    "NEIN! Den muss er machen! Den MUSS er machen!",
    "Das gibt's nicht! Aus drei Metern drüber!",
    "Ich fasse es nicht! Wie kann man den verschießen?",
    "Pfosten! PFOSTEN! Das Ding war doch schon drin!",
    "Neben das leere Tor! Meine Oma hätte den reingemacht, mit dem "
        "Rollator!",
    "Die hundertprozentige! Und vorbei! Ich muss kurz in mein Kissen "
        "beißen.",
    "Latte! Das Ding knallt an die Latte und springt raus!",
  ],
  "miss.opp": [
    "Vorbei! Glück gehabt.",
    "Drüber. Gut so.",
    "Daneben! Durchatmen.",
    "Am Tor vorbei. Bitte weiter so.",
    "Der geht drüber. Puh.",
    "Vorbei, und unser Torwart schaut cool hinterher.",
    "Daneben! Der Schütze hält sich die Hände vors Gesicht. Wir nicht.",
  ],
  "miss.opp.big": [
    "PUH! Den hätte er machen müssen! Glück, pures Glück!",
    "Pfosten! Der Fußballgott ist heute bei uns!",
    "Vorbei! Aus kurzer Distanz! Ich atme wieder!",
    "Was für ein Dusel! Der war eigentlich drin!",
    "Latte! Ich hab schon nicht mehr hingeschaut!",
    "Daneben, aus fünf Metern! Danke, danke, danke!",
    "Der war hundertprozentig! Und vorbei! Ich schicke dem Schützen eine "
        "Karte zu Weihnachten.",
  ],

  // --------------------------------------------------------- miss memory
  "mem.miss2": [
    "Zweiter Fehlschuss von {p}. Langsam wird's peinlich.",
    "{p} schon wieder vorbei. Wo ist das Visier?",
    "Das war die zweite Chance für {p}. Und die zweite Nicht-Chance.",
    "{p} sammelt heute Fehlversuche.",
    "Wieder {p}, wieder vorbei. Man sollte das Tor größer machen. Für "
        "ihn.",
  ],
  "mem.miss3": [
    "Mal wieder {p}. Er schießt heute auf alles außer aufs Tor.",
    "{p} trifft heute nichts. Vielleicht trifft er am Abend wenigstens "
        "den Bus.",
    "Fehlschuss Nummer drei von {p}. Ich höre schon die Pfiffe.",
    "{p} hat heute die Zielgenauigkeit eines Rasensprengers.",
    "Wieder {p}. Wieder daneben. Man könnte die Uhr danach stellen.",
  ],
  "wit.miss.egoism": [
    "Da waren zwei Mitspieler frei. {p} hat sich für den dritten "
        "entschieden: sich selbst.",
    "{p} schießt, weil {p} immer schießt. Die Mitspieler winken noch.",
    "Abspielen? {p} kennt das Wort, er mag es nur nicht.",
    "Egoistisch, {p}. Sehr egoistisch. Und auch noch vorbei.",
  ],
  "wit.miss.party": [
    "Vielleicht war die Nacht doch etwas zu lang, {p}.",
    "{p} zielt, als ob sich das Tor bewegt. Bei ihm tut es das "
        "vielleicht.",
    "{p} schießt drüber. Die Augenringe sind von hier oben zu sehen.",
    "Für {p} wäre heute eher die Disco das richtige Terrain gewesen.",
  ],
  "wit.miss.consistency": [
    "Das ist {p}: Mal Weltklasse, mal Kreisliga. Heute eher Kreisliga.",
    "Bei {p} weiß man nie. Heute weiß man es leider.",
    "{p} hat seine Form im Bus vergessen.",
    "Der launische {p}. Gestern ein Tor des Monats, heute ein Ball auf "
        "die Laufbahn.",
  ],
  "wit.miss.pressure": [
    "Die Nerven, {p}, die Nerven!",
    "{p} zittert. Man sieht es bis hier oben.",
    "In der wichtigen Phase flattert {p} das Bein.",
    "Zu viel Druck für {p}. Der Schuss war ein Hilferuf.",
  ],

  // ----------------------------------------------------- pressure memory
  "mem.pressure.own": [
    "Wir drücken jetzt! {opp} kommt kaum noch raus!",
    "Angriff auf Angriff! {opp} schwimmt!",
    "Die nächste Chance für uns! Das Tor muss doch mal fallen!",
    "Einbahnstraßenfußball, und zwar in die richtige Richtung!",
    "{opp} wird eingeschnürt! Das ist Druck!",
  ],
  "mem.pressure.opp": [
    "{team} drückt. Wir kommen hinten nicht mehr raus.",
    "Die nächste Chance für {team}. Das ist kein Spiel mehr, das ist eine "
        "Belagerung.",
    "Wir stehen nur noch hinten drin. Bitte einen Entlastungsangriff!",
    "{team} rennt an, wir schwimmen. Gefährlich.",
    "Das ist ein Sturmlauf von {team}. Hält die Mauer?",
  ],

  // --------------------------------------------------------- penalties
  "pen.award.own": [
    "ELFMETER! Elfmeter für uns! Der Schiri zeigt auf den Punkt!",
    "Foul im Strafraum! Strafstoß für {team}!",
    "Er pfeift Elfmeter! Völlig zu Recht, das war ein Foul wie im "
        "Lehrbuch!",
    "Elfmeter! Die Fans von {opp} pfeifen, das hilft ihnen auch nicht!",
    "Strafstoß für uns! Jetzt die Nerven behalten!",
  ],
  "pen.award.opp": [
    "Elfmeter für {team}. Das war … nun ja, vertretbar.",
    "Strafstoß {team}. Ich hätte den nicht gegeben, aber ich bin ja "
        "auch nicht neutral.",
    "Der Schiri zeigt auf den Punkt. Elfmeter gegen uns. Mist.",
    "Elfmeter für {team}! Da war ein Bein zu viel.",
    "Foul im Strafraum, Elfmeter für {team}. Jetzt bitte, Torwart!",
  ],
  "pen.up": [
    "{p} legt sich den Ball hin. Der Torwart tänzelt auf der Linie …",
    "Es ist ganz still. {p} läuft an …",
    "{p} schaut den Torwart an, der Torwart schaut zurück. Anlauf …",
    "Der Schiri pfeift, {p} läuft an, verzögert …",
    "{p} am Punkt. Elf Meter, ein Mann, ein Ball …",
    "Alle halten den Atem an. {p} …",
  ],
  "pen.goal.own": [
    "DRIIIN! Eiskalt verwandelt!",
    "Tor! Der Torwart in der einen Ecke, der Ball in der anderen!",
    "Verwandelt! Sicher wie die Bank von England!",
    "Tooor! Ins Netz gehämmert, keine Chance!",
    "Drin! Ganz cool, ganz lässig!",
  ],
  "pen.goal.opp": [
    "Verwandelt. Unser Torwart war in der falschen Ecke.",
    "Drin. Sicher geschossen, leider.",
    "Tor. Der Elfmeter sitzt.",
    "Der ist drin. Keine Chance für unseren Keeper.",
    "Verwandelt. Da war nichts zu machen.",
  ],
  "pen.save.own": [
    "GEHALTEN! Nein! Der Torwart hat die Ecke geahnt!",
    "Pariert! Das darf nicht wahr sein!",
    "Der Keeper hält den Elfmeter! Ich fasse es nicht!",
    "Gehalten! Viel zu unplatziert!",
    "Der Torwart hat ihn! Ein Elfmeter, so unentschlossen wie mein "
        "Steuerberater.",
  ],
  "pen.save.opp": [
    "GEHALTEN! Unser Torwart hält den Elfmeter! Was für ein Held!",
    "Pariert! Unser Keeper hat gezuckt und gewonnen!",
    "Den hält er! Den hält er! Ich will ihn adoptieren!",
    "Elfmeter gehalten! Die ganze Mannschaft stürzt sich auf unseren "
        "Torwart!",
    "Gehalten! Das ist eine Heldentat!",
  ],
  "pen.miss.own": [
    "Drüber! Über das Tor! Wie kann man …",
    "Vorbei! Elfmeter verschossen!",
    "Pfosten! Der Elfmeter knallt an den Pfosten!",
    "Daneben! Ich muss mich setzen.",
    "In den Nachthimmel! Der Ball landet vermutlich im Nachbarort.",
  ],
  "pen.miss.opp": [
    "Drüber! Elfmeter verschossen! Gerechtigkeit!",
    "Vorbei! Der Fußballgott hat entschieden!",
    "Pfosten! Ich liebe diesen Pfosten!",
    "Daneben! Ha!",
    "Verschossen! Ich verkneife mir jetzt jedes Lachen. Fast.",
  ],

  // -------------------------------------------- corners and free kicks
  "corner.own": [
    "Ecke für uns. {p} geht zur Fahne.",
    "Eckball {team}, {p} legt sich den Ball hin.",
    "Ecke! Alle Großen nach vorne!",
    "{p} tritt die Ecke.",
    "Eckstoß für {team}. Jetzt die Köpfe hoch!",
    "Wieder Ecke für uns. {p} zirkelt.",
  ],
  "corner.opp": [
    "Ecke für {team}. Aufpassen bei den Kopfbällen.",
    "Eckball {team}, {p} tritt ihn.",
    "Ecke gegen uns. Alle Mann zurück!",
    "{p} mit der Ecke für {team}.",
    "Eckstoß {team}. Jeder nimmt sich einen.",
    "Wieder Ecke für {team}. Wir müssen den Ball mal klären.",
  ],
  "mem.corners.own": [
    "Die nächste Ecke! Wir haben heute ein Abo auf die Eckfahne.",
    "Ecke Nummer viele. Irgendwann muss einer reingehen.",
    "Eckenverhältnis klar für uns. Tore zählen leider mehr.",
    "So viele Ecken, die Eckfahne will schon Gehaltserhöhung.",
  ],
  "mem.corners.opp": [
    "Schon wieder Ecke für {team}. Wir verteidigen zu viel ins Aus.",
    "{team} sammelt Ecken wie andere Leute Briefmarken.",
    "Wieder eine Ecke gegen uns. Das Risiko steigt.",
    "Ecke um Ecke für {team}. Haltet durch!",
  ],
  "free.own": [
    "Freistoß für uns! {p} steht schon am Ball.",
    "Foul an uns, Freistoß {team}. {p} übernimmt.",
    "Freistoß {team} in aussichtsreicher Position. {p} legt sich den Ball "
        "zurecht.",
    "Der Schiri pfeift, Freistoß für uns. {p} schaut aufs Tor.",
    "Freistoß, und {p} hat schon diesen Blick.",
    "Freistoß für {team}. Die Mauer von {opp} wird gestellt.",
  ],
  "free.opp": [
    "Freistoß für {team}. Mauer stellen!",
    "Foul von uns, Freistoß {team}. {p} steht am Ball.",
    "Freistoß {team}, gefährliche Position.",
    "{p} legt sich den Ball zum Freistoß hin. Bitte nicht.",
    "Freistoß {team}. Unser Torwart dirigiert die Mauer.",
    "Der Schiri gibt Freistoß für {team}. Diskutabel, aber er pfeift.",
  ],

  // -------------------------------------------------------- lost balls
  "lost.cross.own": [
    "Die Flanke von {p} – und {o} köpft sie weg.",
    "{p} flankt, {o} steht genau richtig.",
    "Flanke {p}, zu weit, zu hoch, zu nichts.",
    "{p} bringt ihn rein, {o} fängt ab.",
    "Die Hereingabe von {p} landet beim Gegner. Bei {o}, um genau zu sein.",
    "{p} flankt in die Wolken. {o} sagt danke.",
  ],
  "lost.cross.opp": [
    "Flanke {p} – {o} klärt! Gut gemacht!",
    "{p} bringt ihn rein, unser {o} ist da!",
    "Die Flanke von {p} wird von {o} abgefangen.",
    "{o} köpft die Flanke von {p} weg. Ruhe bewahren.",
    "{p} flankt, aber {o} steht im Weg. Wunderbar.",
    "Die Hereingabe von {p} ist harmlos, {o} hat sie.",
  ],
  "lost.through_ball.own": [
    "{p} versucht den Steilpass, {o} liest ihn.",
    "Der Pass in die Tiefe von {p} – abgefangen von {o}.",
    "{p} sieht eine Lücke, die {o} schon geschlossen hat.",
    "{p} spielt steil, {o} fängt ab. Gut gedacht, schlecht gemacht.",
    "Steilpass {p}, und {o} ist dazwischen.",
  ],
  "lost.through_ball.opp": [
    "Steilpass {p}, aber {o} liest das! Klasse!",
    "{o} fängt den Pass von {p} ab!",
    "{p} will durchstecken, unser {o} ist dazwischen!",
    "Der Pass in die Tiefe von {p} – {o} hat aufgepasst!",
    "{o} riecht den Steilpass von {p}. Abgefangen!",
  ],
  "lost.dribble.own": [
    "{p} will an {o} vorbei. Will.",
    "{p} dribbelt, {o} grätscht. Ball weg.",
    "Ein Haken zu viel, {p}! {o} schnappt sich den Ball.",
    "{p} läuft sich an {o} fest.",
    "{o} nimmt {p} den Ball vom Fuß. Einfach so.",
    "{p} gegen {o}, und {o} gewinnt das Duell.",
  ],
  "lost.dribble.opp": [
    "{p} will vorbei, aber {o} bleibt stehen! Ballgewinn!",
    "{o} nimmt {p} den Ball ab! Sauber!",
    "Grätsche {o}! {p} liegt, der Ball ist unser!",
    "{p} dribbelt in unseren {o} hinein. Ball erobert!",
    "Klasse Zweikampf von {o} gegen {p}!",
    "{o} stellt {p} und gewinnt den Ball.",
  ],
  "lost.long_ball.own": [
    "Langer Ball von {p}, {o} köpft ihn weg.",
    "{p} schlägt ihn weit, {o} hat ihn.",
    "Der lange Ball von {p} landet bei {o}. Geschenkt.",
    "{p} drischt nach vorne, {o} sammelt ein.",
    "Hoch und weit von {p}, und {o} köpft ihn zurück.",
  ],
  "lost.long_ball.opp": [
    "Der lange Ball von {p} – {o} ist da!",
    "{p} schlägt ihn weit, unser {o} köpft ihn raus.",
    "Langer Ball {p}, kein Problem für {o}.",
    "{o} fängt den langen Ball von {p} ab.",
    "Der Flugball von {p} landet bei unserem {o}. Danke.",
  ],
  "mem.loses": [
    "Schon wieder verliert {p} den Ball. Heute läuft bei ihm gar nichts.",
    "{p} und der Ball, das wird heute keine Freundschaft mehr.",
    "Wieder Ballverlust {p}. {o} freut sich schon auf das nächste "
        "Duell.",
    "{p} spielt heute den Ball mehr zum Gegner als zum Mitspieler.",
    "{o} hat {p} heute im Griff. Das ist kein Duell, das ist eine "
        "Abholstation.",
  ],
};
