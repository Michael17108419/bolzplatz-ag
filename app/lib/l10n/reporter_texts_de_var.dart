// The German texts of the radio reporter, part five (step 10e2): the VAR
// and wrong decisions without one. `var.*` keys are decisions of the video
// assistant (league 1 and 2, big cup from the round of 16), `ref.*` keys
// wrong decisions that stand. Keys and placeholders are explained in
// reporter_strings.dart.

const Map<String, List<String>> reporterVideoDe = {
  // ------------------------------------------------------------- checks
  "var.check": [
    "Moment … der Schiri greift ans Ohr. Der Kölner Keller meldet sich.",
    "Halt, halt! Da wird geprüft. Alle starren auf den Schiri.",
    "Der VAR schaut sich das an. Und schaut. Und schaut.",
    "Check läuft. Irgendwo in Köln trinkt jemand kalten Kaffee und "
        "spult zurück.",
    "Der Schiri zeichnet ein Rechteck in die Luft … nein, noch nicht. "
        "Er hört zu.",
  ],
  "var.check.goal": [
    "Moment! Der VAR schaut sich das Tor noch mal an.",
    "Nicht so schnell jubeln, der Kölner Keller prüft.",
    "Der Schiri hat den Finger am Ohr. Das Tor wird überprüft.",
    "Alle warten. Das Tor ist noch nicht sicher.",
  ],
  "var.check.offside": [
    "Der VAR legt die Linien an … kalibrierte Striche, Zentimeterarbeit.",
    "Jetzt wird gemessen. Schulter, Fußspitze, Nasenspitze.",
    "Die Linien werden gezogen. Ganz Köln hält den Atem an.",
    "Abseits oder nicht? Der Keller zoomt rein.",
  ],
  "var.check.penalty": [
    "Moment, der Elfmeter wird überprüft!",
    "Der Schiri geht an den Bildschirm. Das kann dauern.",
    "Review! Der Schiri schaut sich die Szene am Monitor an.",
    "War das wirklich ein Foul? Der VAR hat Zweifel.",
  ],
  "var.check.penalty_given": [
    "Moment! Der Schiri wird an den Bildschirm gerufen … da war was im "
        "Strafraum!",
    "Der VAR meldet sich. Der Schiri läuft zum Monitor.",
    "Halt! Der Keller hat ein Foul im Strafraum gesehen.",
  ],
  "var.check.red_given": [
    "Der Schiri wird an den Monitor gerufen. Da war was hinter seinem "
        "Rücken!",
    "Moment, der VAR hat eine Szene abseits des Balls entdeckt.",
    "Review! Der Schiri schaut sich eine Tätlichkeit an.",
  ],
  "var.check.red_downgraded": [
    "Der VAR meldet sich zur Roten Karte. Der Schiri schaut nochmal hin.",
    "Moment, die Rote wird überprüft!",
    "Der Schiri geht an den Monitor. Vielleicht war Rot zu hart.",
  ],
  "var.check.identity": [
    "Moment! Der VAR meldet sich. Hat der Schiri den Richtigen erwischt?",
    "Verwechslungsgefahr! Der Keller prüft die Rote Karte.",
    "Halt, da stimmt was nicht. Der VAR schaut auf die Rückennummer.",
  ],
  "var.check.second_cancelled": [
    "Der VAR schaut sich die zweite Gelbe an. Das gibt's seit dieser "
        "Saison!",
    "Moment, Gelb-Rot wird überprüft!",
    "Der Schiri geht an den Monitor. War die zweite Gelbe korrekt?",
  ],

  // ------------------------------------------------------- VAR decisions
  "var.goal_overturned.own": [
    "KEIN TOR! Abseits! Um eine Fußspitze! Ich glaube es nicht!",
    "Das Tor wird zurückgenommen. Abseits. Die Linien lügen nicht, aber "
        "sie tun weh.",
    "Nein! Abseits, das Tor zählt nicht! Der Kölner Keller hat gesprochen.",
    "Aberkannt. Ein Zeh im Abseits. Wer hat diesen Videobeweis erfunden?",
    "Der Jubel war umsonst. Abseits, kein Tor.",
  ],
  "var.goal_overturned.opp": [
    "KEIN TOR! Abseits! Danke, Köln!",
    "Das Tor wird zurückgenommen! Abseits! Der VAR ist heute unser "
        "Freund!",
    "Aberkannt! Abseits um Haaresbreite! Wir leben!",
    "Der Jubel drüben verstummt. Abseits, kein Tor. Herrlich.",
    "Die Linien sagen Abseits. Ich liebe Linien.",
  ],
  "var.goal_given.own": [
    "Die Fahne war falsch! Das Tor zählt doch! Danke, VAR!",
    "Der VAR korrigiert den Linienrichter: kein Abseits, TOR!",
    "Erst Abseits, jetzt Tor. Der Kölner Keller hat Herz.",
    "Das Tor zählt! Der Linienrichter sollte mal zum Augenarzt.",
  ],
  "var.goal_given.opp": [
    "Der VAR gibt das Tor. Die Fahne war falsch. Mist.",
    "Kein Abseits, das Tor zählt. Der Keller ist heute gegen uns.",
    "Erst Abseits, dann doch Tor. Für die anderen.",
    "Das Tor wird gegeben. Wir hatten uns schon gefreut.",
  ],
  "var.goal_confirmed.own": [
    "Das Tor zählt! Check abgeschlossen, alles sauber!",
    "Alles korrekt, kein Abseits. Jetzt dürfen wir richtig jubeln!",
    "Bestätigt! Der Jubel geht in die zweite Runde!",
    "Der Keller nickt. Tor!",
  ],
  "var.goal_confirmed.opp": [
    "Das Tor zählt. Leider alles sauber.",
    "Check abgeschlossen, das Tor bleibt. Mist.",
    "Kein Abseits, kein Foul. Das Gegentor steht.",
    "Der VAR findet nichts. Schade.",
  ],
  "var.penalty_overturned.own": [
    "Kein Elfmeter! Der Schiri nimmt ihn zurück. Das war eine Schwalbe, "
        "sagt der Monitor.",
    "Elfmeter zurückgenommen. Unser Mann ist zu leicht gefallen.",
    "Der VAR sagt Nein. Kein Strafstoß. Die Enttäuschung ist riesig.",
    "Elfer weg. Der Monitor zeigt: kaum Kontakt. Bitter.",
  ],
  "var.penalty_overturned.opp": [
    "Kein Elfmeter! Der Schiri nimmt ihn zurück! Gerechtigkeit!",
    "Elfmeter zurückgenommen! Das war eine Schwalbe, und der Monitor hat "
        "sie erwischt!",
    "Der VAR rettet uns! Kein Strafstoß!",
    "Elfer weg! Der Monitor zeigt die Wahrheit.",
  ],
  "var.penalty_given.own": [
    "ELFMETER! Nach Videobeweis! Da war ein klares Foul!",
    "Der Schiri zeigt auf den Punkt! Der VAR hat's gesehen!",
    "Strafstoß für uns nach Review! Danke, Köln!",
    "Elfmeter! Der Monitor lügt nicht!",
  ],
  "var.penalty_given.opp": [
    "Elfmeter gegen uns nach Videobeweis. Hat der Keller zu genau "
        "hingeschaut?",
    "Der Schiri zeigt auf den Punkt. Der VAR hat ein Foul gefunden. Mist.",
    "Strafstoß für die anderen nach Review. Bitter.",
    "Elfmeter gegen uns. Das hätte live keiner gepfiffen.",
  ],
  "var.red_given.own": [
    "ROT nach Videobeweis für {p}! Da hat er hinter dem Rücken des "
        "Schiris zugelangt.",
    "Der VAR hat {p} erwischt. Rote Karte. Dumm, einfach dumm.",
    "{p} fliegt nach Review. Die Kameras sehen alles, {p}.",
    "Rot für {p}. Der Ellenbogen war im Bild.",
  ],
  "var.red_given.opp": [
    "ROT für {p} nach Videobeweis! Die Kameras sehen alles!",
    "Der VAR erwischt {p}! Rote Karte!",
    "{p} fliegt! Die Tätlichkeit hinter dem Rücken des Schiris war im "
        "Bild!",
    "Rot nach Review für {p}. Gerechtigkeit aus dem Keller.",
  ],
  "var.red_downgraded.own": [
    "Keine Rote für {p}! Der Schiri nimmt sie zurück, nur Gelb!",
    "Der VAR hilft uns: Gelb statt Rot für {p}!",
    "Rot wird zu Gelb. {p} darf bleiben. Durchatmen!",
    "Der Monitor zeigt: kein Rot. {p} sieht nur Gelb.",
  ],
  "var.red_downgraded.opp": [
    "Die Rote für {p} wird zurückgenommen. Nur Gelb. Schade.",
    "Gelb statt Rot für {p}. Der VAR ist großzügig.",
    "{p} darf bleiben. Rot wird zu Gelb.",
    "Der Schiri korrigiert sich: nur Gelb für {p}.",
  ],
  "var.identity.own": [
    "Verwechslung! Nicht {o}, sondern {p} war's. Die Rote bekommt der "
        "Richtige.",
    "Der VAR korrigiert: {p} statt {o}. Immerhin der Richtige.",
    "Falscher Mann, richtige Karte. {p} muss runter, nicht {o}.",
  ],
  "var.identity.opp": [
    "Verwechslung beim Gegner! Nicht {o}, sondern {p} muss gehen.",
    "Der VAR sortiert: {p} war's, nicht {o}.",
    "Richtiger Mann, rote Karte: {p} fliegt.",
  ],
  "var.second_cancelled.own": [
    "Die zweite Gelbe wird zurückgenommen! {p} darf bleiben!",
    "Gelb-Rot weg! Der VAR rettet {p}!",
    "Kein Platzverweis für {p}. Die zweite Gelbe war falsch.",
  ],
  "var.second_cancelled.opp": [
    "Die zweite Gelbe für {p} wird zurückgenommen. Schade.",
    "Gelb-Rot weg. {p} darf weitermachen.",
    "Der VAR nimmt die zweite Gelbe gegen {p} zurück.",
  ],

  // ------------------------------------------- wrong decisions, no VAR
  "flag.up": [
    "Aber die Fahne ist oben …",
    "Moment, der Linienrichter hebt die Fahne!",
    "Die Fahne geht hoch. Abseits?",
    "Der Assistent winkt mit der Fahne …",
  ],
  "ref.offside_missed.own": [
    "Unter uns: Das war Abseits. Aber hier gibt's keinen VAR, und wir "
        "nehmen das gern.",
    "War das nicht Abseits? Egal, die Fahne bleibt unten. Glück muss man "
        "haben.",
    "Die Gäste toben, das war Abseits. Kein VAR in dieser Liga. Pech für "
        "sie.",
    "Abseits? Wir haben nichts gesehen. Ehrenwort.",
  ],
  "ref.offside_missed.opp": [
    "DAS WAR ABSEITS! Meterweit! Und kein VAR weit und breit!",
    "Der Linienrichter hat geschlafen. Zwei Meter Abseits, und das Tor "
        "zählt.",
    "Abseits! Ganz klar! Aber hier unten gibt's keine Kameras.",
    "Ein Skandal! Abseits, und keiner hebt die Fahne.",
  ],
  "ref.goal_disallowed.own": [
    "Abseits? NIEMALS! Das war ein reguläres Tor!",
    "Die Fahne ist oben. Das Tor zählt nicht. Ich bin fassungslos, das "
        "war nie Abseits.",
    "Ein klares Tor, und der Linienrichter winkt ab. Ohne VAR bleibt "
        "das so.",
    "Aberkannt! Wofür haben die eine Fahne, wenn sie sie falsch benutzen?",
  ],
  "ref.goal_disallowed.opp": [
    "Die Fahne ist oben! Kein Tor! Das war … sagen wir … knapp.",
    "Abseits, kein Tor. Ehrlich gesagt sah das regulär aus. Aber wir "
        "beschweren uns nicht.",
    "Der Linienrichter rettet uns. Ob zu Recht, weiß keiner. Ohne VAR "
        "ist das egal.",
    "Kein Tor! Wir haben Glück, und das ist auch mal schön.",
  ],
  "ref.penalty_soft.own": [
    "Ganz ehrlich? Ein sehr weicher Elfmeter. Aber wir nehmen ihn.",
    "Ob das ein Foul war? Wir diskutieren das nach dem Spiel.",
    "Der ging leicht zu Boden. Sehr leicht.",
    "Das gibt Diskussionen. Aber nicht von uns.",
  ],
  "ref.penalty_soft.opp": [
    "Das war NIE ein Elfmeter! Der ist ja über seine eigenen Füße "
        "gestolpert!",
    "Eine Schwalbe, und der Schiri fällt drauf rein!",
    "Was für ein Witz von Elfmeter!",
    "Da war doch kein Kontakt! Ich will die Bilder sehen!",
  ],
  "ref.penalty_missed.own": [
    "Das war Elfmeter! Klar und deutlich! Der Schiri winkt weiter!",
    "Unser Mann wird im Strafraum umgerissen, und es gibt nichts? NICHTS?",
    "Elfmeter! Elfmeter! Der Schiri hat Tomaten auf den Augen!",
    "Ein klares Foul im Strafraum, und keiner pfeift. Ohne VAR bleibt "
        "das so.",
  ],
  "ref.penalty_missed.opp": [
    "Das war … puh … durchaus elfmeterwürdig. Der Schiri lässt laufen. "
        "Glück gehabt.",
    "Unser Verteidiger hat ihn umgerissen. Kein Pfiff. Wir sagen nichts.",
    "Strafraum, Foul, kein Elfer. Heute ist der Fußballgott bei uns.",
    "Die Gäste fordern Elfmeter. Zu Recht, ehrlich gesagt.",
  ],
  "ref.red_missed.own": [
    "Hinter dem Rücken des Schiris tritt {p} nach. Keiner sieht's. "
        "Glück gehabt, {p}.",
    "Das war eine Tätlichkeit von {p}! Der Schiri hat's nicht gesehen. "
        "Puh.",
    "{p} teilt aus, der Schiri schaut woanders hin. Das hätte Rot sein "
        "müssen.",
    "Ohne VAR kommt {p} damit durch. Ein Ellenbogen, den keiner sah.",
  ],
  "ref.red_missed.opp": [
    "{p} haut einem von uns den Ellenbogen ins Gesicht, und der Schiri "
        "sieht nichts!",
    "Das war Rot für {p}! Hat denn keiner hingeschaut?",
    "Tätlichkeit von {p} hinter dem Rücken des Schiris. Ohne Kameras "
        "bleibt das ungesühnt.",
    "{p} tritt nach! Und nichts passiert! NICHTS!",
  ],
  "ref.red_harsh.own": [
    "Rot? Für DAS? Das war höchstens Gelb!",
    "Eine viel zu harte Rote gegen {p}. Ohne VAR können wir nur schimpfen.",
    "{p} fliegt, und keiner versteht warum. Das Sportgericht muss das "
        "richten.",
    "Der Schiri hat überreagiert. Rot für {p} ist ein Witz.",
  ],
  "ref.red_harsh.opp": [
    "Ganz ehrlich: Rot für {p} ist hart. Sehr hart. Aber wir nehmen die "
        "Überzahl.",
    "Das war eher Gelb. Aber der Schiri sieht Rot, und wir sagen danke.",
    "Hart, aber nicht unser Problem. {p} muss gehen.",
    "Ob das Rot war? Darüber reden die drüben noch lange.",
  ],
  "ref.second_harsh.own": [
    "Die zweite Gelbe war ein Witz! {p} hat den Ball gespielt!",
    "Gelb-Rot für {p}, und das war nie ein Foul. Ohne VAR bleibt's dabei.",
    "Eine Fehlentscheidung, die uns einen Mann kostet. Bitter.",
  ],
  "ref.second_harsh.opp": [
    "Die zweite Gelbe gegen {p} war … großzügig. Wir beschweren uns nicht.",
    "Hart für {p}. Aber Überzahl ist Überzahl.",
    "Gelb-Rot für {p}, und ehrlich gesagt war da wenig.",
  ],
  "ref.identity.own": [
    "Moment! Rot für {p}? Das war doch {o}! Verwechslung!",
    "Der Schiri schickt {p} vom Platz. Gefoult hat aber {o}. Kein VAR, "
        "keine Korrektur.",
    "Falscher Mann! {p} muss gehen, obwohl {o} es war. Das Sportgericht "
        "muss ran.",
  ],
  "ref.identity.opp": [
    "Rot für {p}? Gefoult hat eigentlich {o}. Der Schiri hat sich "
        "vertan.",
    "Verwechslung beim Gegner: {p} fliegt, {o} darf bleiben. Kurios.",
    "Falscher Mann, aber die Unterzahl gilt trotzdem.",
  ],
};
