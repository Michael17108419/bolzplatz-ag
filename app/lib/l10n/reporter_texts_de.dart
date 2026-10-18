// The German texts of the radio reporter (step 10d2), part one: lanes,
// kick-off and the steps of an attack. Keys and placeholders are explained
// in reporter_strings.dart. Claude writes, Michael checks them in the game.

import 'reporter_texts_de_match.dart';
import 'reporter_texts_de_ref.dart';
import 'reporter_texts_de_var.dart';
import 'reporter_texts_de_shots.dart';

const Map<String, List<String>> reporterTextsDe = {
  ...reporterPlayDe,
  ...reporterShotsDe,
  ...reporterMatchDe,
  ...reporterRefereeDe,
  ...reporterVideoDe,
};

const Map<String, List<String>> reporterPlayDe = {
  // ------------------------------------------------------------ lanes
  "lane.0": [
    "über links",
    "auf der linken Seite",
    "am linken Flügel",
    "die linke Linie entlang",
    "links außen",
  ],
  "lane.1": [
    "halblinks",
    "im linken Halbraum",
    "links neben der Mitte",
    "durch den linken Halbraum",
  ],
  "lane.2": [
    "durch die Mitte",
    "zentral",
    "mitten durchs Zentrum",
    "durchs Herz des Spielfelds",
    "über die Mitte",
  ],
  "lane.3": [
    "halbrechts",
    "im rechten Halbraum",
    "rechts neben der Mitte",
    "durch den rechten Halbraum",
  ],
  "lane.4": [
    "über rechts",
    "auf der rechten Seite",
    "am rechten Flügel",
    "die rechte Linie entlang",
    "rechts außen",
  ],

  // ---------------------------------------------------------- kick-off
  "kickoff": [
    "Hallo und herzlich willkommen! {home} gegen {away}, der Ball liegt "
        "auf dem Punkt – und los geht's!",
    "Der Schiedsrichter schaut auf die Uhr, hebt die Pfeife … Anpfiff! "
        "{home} gegen {away}, wir sind live dabei.",
    "Einen wunderschönen guten Tag! {home} empfängt {away}, und wir haben "
        "die besten Plätze. Anpfiff!",
    "Die Mannschaften stehen, die Fans singen, der Kaffee in der Kabine "
        "ist kalt. {home} gegen {away} – es geht los!",
    "Liebe Hörerinnen und Hörer, schnallen Sie sich an: {home} gegen "
        "{away}. Der Ball rollt!",
    "Anstoß! {home} gegen {away}. Neunzig Minuten Hoffnung, Wut und "
        "vermutlich ein paar Fehlpässe.",
    "Und da ist der Pfiff! {home} gegen {away}, ich habe Gänsehaut, und "
        "das liegt nicht nur an der Klimaanlage hier oben.",
    "Willkommen zu {home} gegen {away}. Die Taktiktafeln sind beschriftet, "
        "die Nerven blank. Anpfiff!",
    "Es ist angerichtet: {home} gegen {away}. Ich verspreche Ihnen nichts, "
        "aber ich hoffe auf alles. Los!",
    "Der Ball rollt bei {home} gegen {away}! Und ich sage Ihnen: Heute "
        "liegt etwas in der Luft. Vermutlich Bratwurstfett.",
  ],
  "local.kickoff": [
    "Rund zweihundert Zuschauer sind da, die Hälfte davon Verwandte. Der "
        "Bratwurststand meldet schon Engpässe.",
    "Der Platzwart hat die Linien heute frisch gekreidet. Fast gerade. "
        "Respekt.",
    "Die Ersatzbank ist eine Bierzeltgarnitur, der Trainer steht im "
        "Vereinsanorak. So muss Fußball.",
    "Am Kassenhäuschen gibt's Lose für die Tombola. Hauptpreis: ein "
        "Kasten Bier und ein Händedruck vom Vorsitzenden.",
    "Der Stadionsprecher ist auch der Kassenwart. Er hat die Aufstellung "
        "fast fehlerfrei vorgelesen.",
    "Hinter dem Tor parken die Autos. Wer heute einen Fernschuss wagt, "
        "riskiert einen Versicherungsfall.",
    "Die Kabinen riechen nach Franzbranntwein und Hoffnung. Das ist "
        "Amateurfußball, meine Damen und Herren.",
    "Der Vereinshund liegt an der Eckfahne und hat schon jetzt mehr "
        "Ballkontakte als der Linksverteidiger.",
    "Heute kommentiere ich von der Leiter neben dem Vereinsheim. Gute "
        "Sicht, wackeliger Stand.",
    "Die Getränke gibt's heute im Pfandbecher. Der Vorstand nennt das "
        "Nachhaltigkeit, ich nenne es Sparkurs.",
  ],

  // ------------------------------------------------------- short pass
  "step.short_pass.won": [
    "{p} {where}, kurzer Pass.",
    "{p} hat den Ball, spielt kurz weiter.",
    "Kurzes Zuspiel von {p}.",
    "{p} legt quer, alles ganz ruhig.",
    "{p} {where}, Doppelpass angedeutet.",
    "Ballstafette, {p} ist dabei.",
    "{p} spielt kurz, schnell, einfach.",
    "{p} nimmt an und gibt sofort ab.",
  ],
  "step.short_pass.won.pretty": [
    "Direktpass {p}! Wie an der Schnur gezogen.",
    "{p} mit der Hacke! Das war frech.",
    "Doppelpass mit {p}, das sieht nach Training aus!",
    "{p} lässt prallen, Kombination wie im Lehrbuch.",
    "One-Touch von {p}, der Ball läuft wie von selbst.",
  ],
  "step.short_pass.won.fast": [
    "{p} schnell weiter, zack!",
    "Tempo! {p} spielt direkt.",
    "Ruckzuck: {p} mit dem schnellen Pass.",
    "{p} hält sich nicht auf, sofort weiter.",
  ],
  "step.short_pass.won.press": [
    "{p} unter Druck, kriegt den Ball aber noch weg.",
    "{o} ist dran, doch {p} spielt ab.",
    "Eng gegen {p}, aber der Pass kommt an.",
    "{p} wird bedrängt – und behauptet sich.",
  ],
  "step.short_pass.won.clear": [
    "{p} ganz frei, spielt in Ruhe.",
    "Niemand stört {p}. Einladung angenommen.",
    "{p} hat alle Zeit der Welt.",
  ],
  "step.short_pass.lost": [
    "{p} spielt kurz – zu kurz.",
    "Fehlpass {p}.",
    "{p} sucht den Mitspieler, findet {o}.",
    "Der Pass von {p} kommt nicht an.",
  ],

  // ----------------------------------------------------- through ball
  "step.through_ball.won": [
    "{p} mit dem Steilpass {where}!",
    "Jetzt der Ball in die Tiefe von {p}!",
    "{p} sieht die Lücke – und spielt sie!",
    "Steil geht's! {p} schickt den Ball hinter die Kette.",
    "{p} öffnet das Spiel mit dem Pass in den Lauf.",
    "Schnittstellenpass von {p}!",
    "{p} spielt den tödlichen Pass {where}!",
    "Da ist der Ball in die Spitze, gespielt von {p}!",
  ],
  "step.through_ball.won.pretty": [
    "Was für ein Pass von {p}! Mit Auge, mit Gefühl, mit Ansage!",
    "{p} spielt den Ball durch ein Nadelöhr! Ein Traum!",
    "Zauberpass {p}! Die Abwehr schaut hinterher wie beim Tennis.",
    "{p} mit dem Pass, den man nicht trainieren kann. Den hat man oder "
        "eben nicht.",
    "Sensationell, {p}! Der Ball fällt genau in den Lauf.",
  ],
  "step.through_ball.won.fast": [
    "Blitzschnell der Steilpass von {p}!",
    "{p} spielt sofort in die Tiefe, keine Zeit verlieren!",
    "Und schon ist der Ball hinter der Abwehr – {p}!",
    "{p} schaltet am schnellsten: Steilpass!",
  ],
  "step.through_ball.won.press": [
    "{p} bedrängt von {o} – und trotzdem der Pass in die Tiefe!",
    "Mit {o} im Nacken spielt {p} noch steil!",
    "Unter Druck, aber {p} findet die Lücke!",
    "{o} will den Pass verhindern, {p} spielt ihn trotzdem!",
  ],
  "step.through_ball.won.clear": [
    "{p} hat Platz und sieht den Laufweg. Steilpass!",
    "Ungestört schickt {p} den Ball in die Tiefe.",
    "{p} darf sich den Pass aussuchen – und nimmt den in die Spitze.",
  ],
  "step.through_ball.lost": [
    "{p} versucht es steil – zu weit.",
    "Der Steilpass von {p} ist zu ungenau.",
    "{p} will in die Tiefe, {o} ahnt es.",
    "Den Pass in die Spitze von {p} fängt {o} ab.",
  ],

  // -------------------------------------------------------- long ball
  "step.long_ball.won": [
    "{p} schlägt den langen Ball {where}!",
    "Langer Ball von {p}, hoch und weit!",
    "{p} mit dem Diagonalball!",
    "Ein Schlag von {p} über das halbe Feld!",
    "{p} drischt ihn nach vorne – und es passt!",
    "Weiter Ball von {p}, Spielverlagerung!",
    "{p} sucht den Weg über die Luft.",
    "Flugball von {p} {where}!",
  ],
  "step.long_ball.won.pretty": [
    "Was für ein Ball von {p}! Fünfzig Meter auf den Fuß!",
    "{p} mit dem Diagonalball – präzise wie ein Postbote!",
    "Ein Pass wie aus dem Bilderbuch, {p} legt ihn genau hin!",
    "{p} schlägt den Ball mit Gefühl über alle hinweg. Herrlich!",
    "Den hat {p} mit dem Lineal gezogen!",
  ],
  "step.long_ball.won.fast": [
    "{p} schlägt sofort lang!",
    "Schnell umgeschaltet, {p} mit dem langen Ball!",
    "Ohne Umweg: {p} hoch nach vorne!",
    "{p} sieht den Raum und schlägt ihn sofort lang!",
  ],
  "step.long_ball.won.press": [
    "{p} bedrängt, schlägt den Ball einfach weit – und er kommt an!",
    "Mit {o} am Hacken drischt {p} ihn nach vorne. Passt!",
    "Befreiungsschlag von {p} – nein, das ist ein Pass!",
    "{p} unter Druck, langer Ball, und plötzlich ist Platz!",
  ],
  "step.long_ball.won.clear": [
    "{p} hat Zeit, schaut hoch, langer Ball.",
    "Keiner greift {p} an, also kommt der lange Ball.",
    "{p} legt sich den Ball zurecht und schlägt ihn weit.",
  ],
  "step.long_ball.lost": [
    "Langer Ball von {p} – ins Nichts.",
    "{p} schlägt ihn hoch, {o} köpft weg.",
    "Der weite Ball von {p} ist eine Spende für den Gegner.",
    "{p} drischt, {o} sammelt ein.",
  ],

  // ------------------------------------------------------------ cross
  "step.cross.won": [
    "Flanke {p} {where}!",
    "{p} bringt den Ball in die Mitte!",
    "Hereingabe von {p}!",
    "{p} flankt!",
    "Der Ball kommt von {p} scharf vors Tor!",
    "{p} zieht die Flanke in den Strafraum!",
    "Jetzt die Flanke von {p}!",
    "{p} schlägt den Ball an den Elfmeterpunkt!",
  ],
  "step.cross.won.pretty": [
    "Was für eine Flanke von {p}! Genau zwischen Torwart und Abwehr!",
    "{p} zirkelt den Ball rein, mit Schnitt, mit Absicht, mit Liebe!",
    "Eine Flanke wie gemalt von {p}!",
    "{p} mit dem Außenrist! Die Flanke dreht sich zum Tor!",
    "Maßflanke {p}! Die muss man nur noch …",
  ],
  "step.cross.won.fast": [
    "{p} flankt sofort, ohne Ballannahme!",
    "Direkte Hereingabe von {p}!",
    "{p} bringt ihn flach und scharf rein!",
    "Ganz schnell die Flanke von {p}!",
  ],
  "step.cross.won.press": [
    "{o} kommt zu spät, {p} bringt die Flanke noch rein!",
    "Bedrängt von {o} – aber die Flanke kommt!",
    "{p} flankt im Fallen!",
    "Gegen {o} kriegt {p} den Ball noch hoch!",
  ],
  "step.cross.won.clear": [
    "{p} hat alle Zeit, schaut, flankt.",
    "Keiner bei {p}! Ganz in Ruhe die Hereingabe.",
    "{p} steht völlig frei und darf flanken.",
  ],
  "step.cross.lost": [
    "Flanke {p} – zu hoch.",
    "{p} flankt, {o} ist dazwischen.",
    "Die Hereingabe von {p} segelt ins Aus.",
    "{p} bringt ihn rein, {o} klärt.",
  ],

  // ---------------------------------------------------------- dribble
  "step.dribble.won": [
    "{p} {where}, geht ins Dribbling!",
    "{p} zieht an {o} vorbei!",
    "{p} mit Tempo {where}!",
    "{p} lässt {o} stehen!",
    "{p} geht ins Eins-gegen-eins – und gewinnt es!",
    "{p} tankt sich durch!",
    "{p} treibt den Ball {where} nach vorne!",
    "{p} schüttelt {o} ab!",
  ],
  "step.dribble.won.pretty": [
    "Übersteiger {p}! {o} sucht noch den Ball!",
    "{p} tunnelt {o}! Das gibt's doch nicht!",
    "Was macht {p} da? Zwei Haken, und {o} sitzt auf dem Hosenboden!",
    "{p} tanzt {o} aus wie auf der Hochzeit seiner Schwester!",
    "Ein Trick, noch ein Trick, und {o} braucht eine Wegbeschreibung!",
    "{p} mit der Sohle, mit der Hüfte, mit allem! Vorbei an {o}!",
  ],
  "step.dribble.won.fast": [
    "{p} zündet den Turbo {where}!",
    "Antritt {p}! Weg ist er!",
    "{p} läuft {o} einfach davon!",
    "Mit Vollgas {where}: {p}!",
  ],
  "step.dribble.won.press": [
    "{o} zerrt am Trikot, aber {p} bleibt dran!",
    "{p} setzt sich gegen {o} durch, mit Kraft und Wille!",
    "Zwei Gegenspieler um {p}, und er kommt trotzdem durch!",
    "{p} wird gefoult – nein, er bleibt stehen und geht weiter!",
  ],
  "step.dribble.won.clear": [
    "{p} hat Platz {where} und nutzt ihn.",
    "Keiner stellt sich {p} in den Weg. Er läuft und läuft.",
    "{p} trabt {where} nach vorne, die Abwehr guckt zu.",
  ],
  "step.dribble.lost": [
    "{p} will vorbei – {o} sagt nein.",
    "{p} dribbelt sich fest.",
    "Ein Haken zu viel von {p}.",
    "{p} gegen {o}, und {o} gewinnt.",
  ],

  // --------------------------------------------------------- memory
  "mem.again.dribble": [
    "Und schon wieder {p} {where}! Die Seite gehört heute ihm.",
    "Zum dritten Mal so: {p} {where}. Hat da jemand den Gegenspieler "
        "abgemeldet?",
    "{p} {where}, wie bestellt. Das ist heute seine Autobahn.",
    "Wieder {p}! Irgendwer muss sich da mal kümmern.",
    "{p} hat {where} heute ein Dauerabo.",
  ],
  "mem.again.cross": [
    "Wieder eine Flanke von {p} {where}. Er hat da offenbar einen "
        "Liegestuhl aufgestellt.",
    "{p} {where}, Flanke Nummer viele. Da muss doch mal einer hingehen!",
    "Und wieder darf {p} {where} flanken. Das ist keine Abwehr, das ist "
        "ein Spalier.",
    "{p} flankt {where} wie am Fließband.",
  ],
  "mem.again.through_ball": [
    "Schon wieder findet {p} die Lücke. Der Mann hat Röntgenaugen.",
    "{p} spielt heute einen Steilpass nach dem anderen. Die Abwehr lernt "
        "nichts dazu.",
    "Und wieder der Pass in die Tiefe von {p}. Man sollte ihm einen "
        "Bewacher abstellen.",
    "{p} öffnet die Abwehr wie eine Konservendose. Zum wiederholten Mal.",
  ],
  "wit.step.dribbler": [
    "Das ist der Grund, warum {p} im Training nie den Ball abgibt.",
    "{p} spielt nicht Fußball, {p} spielt mit dem Gegner.",
    "Wenn {p} dribbelt, schauen sogar die Ordner hin.",
    "{p} hat den Ball am Fuß festgeklebt. Anders kann ich mir das nicht "
        "erklären.",
    "Dribbelkunst von {p}. Sein Berater klatscht bestimmt auf der Tribüne.",
  ],

  // --------------------------------------------------------- counter
  "counter.own": [
    "Ballgewinn {p} gegen {o} – und jetzt schnell! Konter!",
    "{p} erobert den Ball! Wir sind in Überzahl, los, los, los!",
    "Da ist der Ball! {p} schnappt ihn sich, und {team} schaltet um!",
    "{p} spitzelt {o} den Ball weg! Konter {team}!",
    "Jetzt aber! {p} gewinnt das Duell, und vorne ist Platz ohne Ende!",
    "{o} verliert den Ball an {p}, und {team} rennt!",
    "Konter! {p} hat den Ball, und die Abwehr von {opp} steht noch beim "
        "Kaffee!",
  ],
  "counter.opp": [
    "Oh nein, Ballverlust {o}! {p} schaltet um, Konter {team}!",
    "{p} nimmt {o} den Ball ab, und jetzt wird's eng für uns!",
    "Konter {team}! Bei uns sind alle vorne, hinten ist Ebbe!",
    "Achtung, Achtung! {p} hat den Ball und Platz ohne Ende!",
    "Das war leichtsinnig von {o}. {p} sagt danke, Konter!",
    "{team} kontert, und bei uns rennt die halbe Mannschaft hinterher!",
    "Ballverlust im Mittelfeld, und {team} schaltet blitzschnell um. "
        "Zurück, zurück!",
  ],
  "open.counter.own": [
    "Drei gegen zwei, jetzt bloß nicht verstolpern!",
    "Wir sind in Überzahl!",
    "Der Konter läuft!",
    "Platz, Platz, nichts als Platz!",
    "Jetzt aber schnell!",
  ],
  "open.counter.opp": [
    "Die laufen auf unser Tor zu!",
    "Das wird gefährlich!",
    "Wir sind in Unterzahl hinten!",
    "Bitte, bitte, irgendwer zurück!",
    "Das riecht nach Ärger!",
  ],

  // ------------------------------------------------- scene openers
  "open.own": [
    "Jetzt wird's interessant!",
    "Achtung, da geht was!",
    "Moment, Moment!",
    "Und jetzt!",
    "Da kommt was!",
  ],
  "open.own.e2": [
    "Jetzt, jetzt, jetzt!",
    "Komm, komm, komm!",
    "Halten Sie sich fest!",
    "Das ist die Chance!",
    "Hier passiert was!",
    "Ich stehe auf!",
  ],
  "open.own.e3": [
    "JETZT! Das ist es!",
    "Die ganze Bank ist aufgesprungen!",
    "Ich halte es nicht aus!",
    "Alles nach vorne, letzte Chance!",
    "Das ganze Stadion steht!",
    "Herzschrittmacher bitte anschalten!",
  ],
  "open.opp": [
    "Vorsicht!",
    "Aufpassen jetzt!",
    "Das sieht nicht gut aus.",
    "Oh, oh.",
    "Da brennt's!",
  ],
  "open.opp.e2": [
    "Nein, nein, nein!",
    "Das wird gefährlich!",
    "Bitte nicht!",
    "Alle Mann zurück!",
    "Ich kann nicht hinsehen!",
  ],
  "open.opp.e3": [
    "Nicht jetzt, bitte nicht jetzt!",
    "Ich halte mir die Augen zu!",
    "Das darf doch nicht wahr sein!",
    "Alle Mann in den Strafraum, alle!",
    "Mein Puls! Mein Puls!",
  ],
};
