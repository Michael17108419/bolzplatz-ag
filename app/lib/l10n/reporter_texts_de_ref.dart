// The German texts of the radio reporter, part four (step 10e1): the
// referee at kick-off, fouls, advantage, protest and keepers by name. Keys
// and placeholders are explained in reporter_strings.dart; `{ref}` is the
// referee, `{k}` the keeper who faced the shot.

const Map<String, List<String>> reporterRefereeDe = {
  // ------------------------------------------------- referee at kick-off
  "ref.intro": [
    "Schiedsrichter heute: {ref}. Unauffällig, hoffen wir.",
    "Pfeifen darf {ref}. Viel Glück, Herr Schiedsrichter.",
    "Die Pfeife hat heute {ref}. Ein Mann ohne Fanclub.",
    "{ref} leitet die Partie. Er hat die Regeln dabei, wir hoffen, er "
        "hat sie gelesen.",
    "Unparteiischer heute: {ref}. Bitte bleiben Sie es.",
  ],
  "ref.intro.strictness.hi": [
    "Schiedsrichter ist {ref}. Der hat die Karten schneller in der Hand "
        "als andere ihr Handy.",
    "{ref} pfeift. Bei ihm reicht ein böser Blick für Gelb.",
    "Achtung, {ref} leitet. Der Mann verteilt Karten wie ein Croupier.",
    "Mit {ref} wird's teuer. Der zückt Gelb schon beim Seitenwechsel.",
  ],
  "ref.intro.strictness.lo": [
    "{ref} pfeift heute. Bei ihm muss man schon jemanden umtreten, um "
        "Gelb zu sehen.",
    "Schiedsrichter {ref}, bekannt für eine lockere Hand bei Karten.",
    "Mit {ref} wird's ruppig. Der lässt viel laufen, auch Knöchel.",
    "{ref} ist heute dran. Seine Gelbe Karte hat angeblich noch "
        "Originalverpackung.",
  ],
  "ref.intro.penalties.hi": [
    "{ref} pfeift, und der zeigt gern auf den Punkt. Stürmer, fallt "
        "bitte vorsichtig.",
    "Schiedsrichter {ref}. Kein Schiri gibt mehr Elfmeter. Die Abwehr "
        "sollte die Hände in die Taschen stecken.",
    "Mit {ref} ist der Strafraum ein Minenfeld. Jeder Kontakt kann ein "
        "Elfer sein.",
    "{ref} leitet. Elfmeter sind bei ihm so häufig wie Bratwürste.",
  ],
  "ref.intro.penalties.lo": [
    "{ref} pfeift. Bei ihm gibt's Elfmeter nur mit notarieller "
        "Beglaubigung.",
    "Schiedsrichter {ref}, der zeigt fast nie auf den Punkt. Stürmer, "
        "bleibt lieber stehen.",
    "Mit {ref} muss man im Strafraum schon zu Boden geprügelt werden.",
    "{ref} leitet heute. Seine letzte Elfmeterentscheidung ist Jahre her.",
  ],
  "ref.intro.advantage.hi": [
    "{ref} pfeift, und der lässt gern laufen. Vorteil ist sein zweiter "
        "Vorname.",
    "Schiedsrichter {ref}. Bei ihm geht das Spiel weiter, auch wenn "
        "jemand liegt.",
    "Mit {ref} wird's flüssig. Der pfeift nur, wenn es sein muss.",
    "{ref} leitet. Er liebt den Vorteil mehr als seine Pfeife.",
  ],
  "ref.intro.advantage.lo": [
    "{ref} pfeift heute. Jedes Foul, jeder Kontakt, Pfiff. Stop and go.",
    "Schiedsrichter {ref}. Der pfeift so oft, dass die Pfeife Überstunden "
        "macht.",
    "Mit {ref} gibt's keinen Spielfluss, aber viele Freistöße.",
    "{ref} leitet. Vorteil kennt er nur aus dem Wörterbuch.",
  ],
  "ref.intro.home_bias.hi": [
    "{ref} pfeift. Man sagt ihm nach, er höre gern auf das Heimpublikum.",
    "Schiedsrichter {ref}. Gäste, hier wird's schwer, der mag es laut und "
        "heimisch.",
    "Mit {ref} hat die Heimmannschaft einen zwölften Mann. Sagen böse "
        "Zungen.",
    "{ref} leitet. Seine Heimsiegquote ist auffällig. Rein zufällig, "
        "natürlich.",
  ],
  "ref.intro.home_bias.lo": [
    "{ref} pfeift. Der lässt sich vom Publikum nicht beeindrucken, gar "
        "nicht.",
    "Schiedsrichter {ref}. Ob Heim oder Gast, bei ihm sind alle gleich "
        "verdächtig.",
    "Mit {ref} hilft kein Pfeifkonzert. Der hört nur auf sich selbst.",
    "{ref} leitet. Heimvorteil? Nicht mit ihm.",
  ],
  "ref.intro.errors.hi": [
    "{ref} pfeift. Sagen wir es freundlich: Er ist für Überraschungen "
        "gut.",
    "Schiedsrichter {ref}. Seine Entscheidungen sind wie das Wetter: "
        "schwer vorherzusagen.",
    "Mit {ref} ist alles möglich. Wirklich alles.",
    "{ref} leitet heute. Halten Sie Ihre Nerven bereit.",
  ],
  "ref.intro.errors.lo": [
    "{ref} pfeift, einer der Besten. Der liegt fast nie daneben.",
    "Schiedsrichter {ref}, ein Mann mit Adleraugen.",
    "Mit {ref} gibt's wenig zu meckern. Fast schon langweilig.",
    "{ref} leitet. Wenn der pfeift, war da was.",
  ],
  "ref.intro.authority.hi": [
    "{ref} pfeift. Bei ihm wird nicht diskutiert, nur genickt.",
    "Schiedsrichter {ref}. Wer bei ihm meckert, meckert nicht lange.",
    "Mit {ref} ist Ruhe auf dem Platz. Der Mann hat Präsenz.",
    "{ref} leitet. Ein Blick, und die Rudelbildung löst sich auf.",
  ],
  "ref.intro.authority.lo": [
    "{ref} pfeift heute. Mal sehen, wie lange er sich das Gemecker "
        "anhört.",
    "Schiedsrichter {ref}. Bei ihm darf man ein bisschen mehr sagen. Bis "
        "es knallt.",
    "Mit {ref} wird viel diskutiert. Der ist zu nett für diesen Job.",
    "{ref} leitet. Die Spieler werden ihn heute ausgiebig belehren.",
  ],

  // ------------------------------------------------------------ advantage
  "adv.own": [
    "Foul von {o} an {p}! Aber der Schiri lässt laufen, Vorteil für uns!",
    "{p} wird umgerissen, der Ball läuft weiter. Vorteil! Weiter, weiter!",
    "{o} tritt {p} um, doch der Schiri zeigt nach vorne. Vorteil!",
    "Klares Foul an {p}, aber Vorteil! Gut gesehen, Schiri!",
    "{p} stolpert nach dem Foul von {o}, der Ball ist noch da. Weiter!",
  ],
  "adv.opp": [
    "{o} foult {p}, aber der Schiri lässt laufen. Vorteil {team}!",
    "Foul von uns an {p}, und der Schiri gibt Vorteil. Mist!",
    "{p} wird von {o} gelegt, das Spiel läuft weiter. Aufpassen!",
    "Unser {o} reißt {p} um, aber Vorteil für {team}. Das kann teuer "
        "werden!",
    "Vorteil {team}, der Schiri lässt nach dem Foul von {o} laufen.",
  ],
  "adv.dogso.own": [
    "Notbremse von {o} an {p}! Aber der Schiri lässt laufen, die Chance "
        "lebt!",
    "{o} zieht {p} am Trikot, doch der Ball rollt weiter. Vorteil, "
        "Großchance!",
    "Das ist eigentlich Rot für {o}! Aber Vorteil, und wir sind trotzdem "
        "durch!",
    "Notbremse! Aber der Schiri wartet ab. Klug, klug!",
  ],
  "adv.dogso.opp": [
    "Unser {o} reißt {p} um, eine Notbremse! Doch der Schiri lässt "
        "laufen!",
    "{o} zieht die Notbremse, aber {team} hat trotzdem den Ball. Vorteil!",
    "Das wäre Rot für {o} gewesen. Aber Vorteil, und es brennt weiter!",
    "Notbremse von uns! Der Schiri lässt laufen. Jetzt bloß kein Tor!",
  ],
  "adv.goal.own": [
    "Und der Vorteil hat sich gelohnt! Der Schiri klatscht innerlich mit!",
    "Vorteil, Tor! So muss das sein, Schiri!",
    "Der Schiri hat laufen lassen, und wir haben getroffen. Danke!",
    "Das war der Vorteil des Tages!",
  ],
  "adv.goal.opp": [
    "Und der Vorteil zahlt sich für {team} aus. Hätte er nur gepfiffen!",
    "Vorteil, Tor. Für die anderen. Grrr.",
    "Der Schiri lässt laufen, {team} trifft. Das tut doppelt weh.",
    "Da hätten wir lieber einen Freistoß gegen uns gehabt.",
  ],
  "adv.nocard": [
    "Und weil das Tor gefallen ist, bleibt die Notbremse ohne Karte. "
        "Neue Regel, liebe Hörer.",
    "Tor nach Notbremse mit Vorteil: Da gibt's seit dieser Saison nicht "
        "mal mehr Gelb.",
    "Die Karte für die Notbremse spart sich der Schiri. Das Tor reicht "
        "als Strafe.",
    "Keine Karte, das Tor ist Strafe genug. So will es die Regel.",
  ],
  "adv.wasted.own": [
    "Der Vorteil verpufft. Den Freistoß hätten wir lieber genommen.",
    "Vorteil, und dann? Nichts. Da war der Pfiff mehr wert.",
    "So viel zum Vorteil. Der Ball ist weg.",
    "Der Schiri wollte es gut meinen. Hat nicht geklappt.",
    "Vorteil gegeben, Vorteil verschenkt.",
  ],
  "adv.wasted.opp": [
    "Der Vorteil bringt {team} nichts. Glück gehabt.",
    "Vorteil verpufft. Puh.",
    "Da hätte der Schiri auch pfeifen können. Uns soll's recht sein.",
    "Der Vorteil verläuft im Sand. Wunderbar.",
    "{team} macht aus dem Vorteil nichts. Danke dafür.",
  ],

  // ----------------------------------------------------------------- fouls
  "foul.dogso.own": [
    "NOTBREMSE! {o} reißt {p} um, der war durch!",
    "{p} wäre allein vor dem Tor gewesen, aber {o} holt ihn von den "
        "Beinen!",
    "Das ist eine glasklare Notbremse von {o}!",
    "{o} zieht die Notbremse gegen {p}. Das gibt Ärger!",
  ],
  "foul.dogso.opp": [
    "Unser {o} legt {p} um, und {p} war durch. Notbremse.",
    "{o} reißt {p} zu Boden. Das war die letzte Rettung, aber teuer.",
    "Notbremse von unserem {o}. Taktisch klug, moralisch fragwürdig.",
    "{p} wäre durch gewesen, {o} sagt nein. Mit allen Mitteln.",
  ],
  "foul.whistle.own": [
    "Foul an {p}, {o} war zu spät.",
    "{o} erwischt {p} am Knöchel. Pfiff.",
    "{p} geht zu Boden, {o} hat zugelangt.",
    "Taktisches Foul von {o} an {p}.",
    "{o} hält {p} fest. Freistoß.",
  ],
  "foul.whistle.opp": [
    "Unser {o} foult {p}. Musste das sein?",
    "{o} kommt zu spät gegen {p}. Pfiff.",
    "{p} wird von {o} gelegt. Unnötig.",
    "Taktisches Foul von {o}. Klug gemacht, aber teuer?",
    "{o} zupft an {p}. Der Schiri hat es gesehen.",
  ],

  // ------------------------------------------------ cards with a reason
  "yellow.dissent.own": [
    "Gelb für {p} wegen Meckerns! Nur der Kapitän darf reden, {p}!",
    "{p} diskutiert mit dem Schiri und sieht Gelb. Selbst schuld.",
    "Meckern kostet Gelb, {p} weiß das jetzt auch.",
    "{p} redet sich in die Kartei. Gelb für die große Klappe.",
    "Gelb für {p}. Er hat dem Schiri erklärt, wie Fußball geht. Der "
        "Schiri wollte es nicht wissen.",
  ],
  "yellow.dissent.opp": [
    "Gelb für {p} wegen Meckerns! Das kommt davon.",
    "{p} quatscht den Schiri voll und kassiert Gelb. Herrlich.",
    "Nur der Kapitän darf reden, {p}. Jetzt mit Gelb notiert.",
    "{p} sieht Gelb für seine Rede. Kurz, aber teuer.",
    "Gelb gegen {p}. Wer meckert, bekommt Post.",
  ],
  "yellow.advantage.own": [
    "Jetzt kommt die Gelbe nach: {p} wird für das Foul von vorhin "
        "verwarnt.",
    "Nachträglich Gelb für {p}. Der Schiri vergisst nichts.",
    "Der Schiri hat sich {p} gemerkt. Gelb, mit Verspätung.",
    "Gelb für {p}, der Vorteil ist vorbei, die Rechnung kommt.",
  ],
  "yellow.advantage.opp": [
    "Gelb für {p} nach dem Vorteil. Hat er sich verdient.",
    "Der Schiri holt die Karte nach: Gelb für {p}.",
    "Nachträglich Gelb gegen {p}. Gut aufgepasst, Schiri.",
    "Vorteil vorbei, Gelb für {p}. Gerechtigkeit mit Verzögerung.",
  ],
  "yellow.dogso_box.own": [
    "Elfmeter und nur Gelb für {p}. Er wollte den Ball spielen, sagt "
        "der Schiri.",
    "Gelb für {p}, kein Rot. Im Strafraum mit Ballversuch reicht das.",
    "Glück für {p}: Elfmeter gegen uns, aber nur Gelb.",
    "{p} sieht Gelb. Die Notbremse im Strafraum kostet heute nur den "
        "Elfer.",
  ],
  "yellow.dogso_box.opp": [
    "Elfmeter und Gelb für {p}. Rot wäre uns lieber gewesen, aber gut.",
    "Nur Gelb für {p}. Ballversuch im Strafraum, sagt der Schiri.",
    "Gelb gegen {p}, dazu Elfmeter. Wir nehmen das.",
    "{p} kommt mit Gelb davon. Den Elfer gibt's trotzdem.",
  ],
  "red.dogso.own": [
    "ROT für {p}! Notbremse, keine Diskussion!",
    "Glatt Rot für {p} wegen Notbremse. Bitter, aber korrekt.",
    "{p} muss runter. Die Notbremse kostet ihn den Rest des Tages.",
    "Rot! {p} hat die Notbremse gezogen und zahlt den Preis.",
  ],
  "red.dogso.opp": [
    "ROT für {p}! Notbremse, und zwar eine dicke!",
    "Glatt Rot gegen {p}! Das war die letzte Rettung, und die kostet.",
    "{p} fliegt wegen Notbremse! {team} nur noch zu zehnt!",
    "Rot für {p}. Notbremse, Platzverweis, Dusche.",
  ],
  "second.dissent.own": [
    "Gelb-Rot für {p} wegen Meckerns! Das ist einfach dumm.",
    "{p} redet sich vom Platz! Zweite Gelbe wegen Meckerns!",
    "Unfassbar, {p} fliegt fürs Meckern. Die Kabine wird laut.",
  ],
  "second.dissent.opp": [
    "Gelb-Rot für {p} wegen Meckerns! Danke, {p}!",
    "{p} quatscht sich vom Platz! Herrlich!",
    "Zweite Gelbe fürs Meckern, {p} muss gehen. Selbst schuld.",
  ],

  // -------------------------------------------------------------- protest
  "dissent.captain.own": [
    "Unser Kapitän {p} geht zum Schiri und redet ruhig mit ihm. So "
        "macht man das.",
    "{p} hebt die Hand, alle anderen bleiben weg. Nur der Kapitän "
        "spricht.",
    "Kapitän {p} hält die Jungs zurück und klärt das mit dem Schiri.",
    "{p} nimmt den Schiri zur Seite. Ein Gespräch unter Erwachsenen.",
    "Die Binde verpflichtet: {p} diskutiert, die anderen schweigen.",
  ],
  "dissent.captain.opp": [
    "Der Kapitän von {team}, {p}, will mit dem Schiri reden. Darf er.",
    "{p} redet auf den Schiri ein. Als Kapitän darf er das.",
    "{team} schickt den Kapitän vor. {p} gestikuliert, der Schiri nickt.",
    "{p} diskutiert. Der Schiri hört zu und bleibt dabei.",
    "Kapitän {p} beschwert sich. Ordnungsgemäß, aber erfolglos.",
  ],
  "dissent.protest.own": [
    "{p} stürmt auf den Schiri zu! Nein, {p}, nur der Kapitän darf das!",
    "Rudelbildung! {p} vorneweg, der Schiri greift in die Tasche …",
    "{p} hat was zu sagen. Leider nicht der Kapitän.",
    "{p} brüllt den Schiri an. Das ist keine gute Idee.",
    "Und {p} rennt zum Schiri. Bitte, {p}, lass es.",
  ],
  "dissent.protest.opp": [
    "{p} geht den Schiri an! Mal sehen, ob das was kostet.",
    "Rudelbildung bei {team}, {p} mittendrin!",
    "{p} redet auf den Schiri ein. Er ist nicht der Kapitän.",
    "{p} fuchtelt mit den Armen. Der Schiri schaut genau hin.",
    "Wilde Szenen, {p} will den Schiri belehren.",
  ],

  // ----------------------------------------------------- keepers by name
  "save.own.k": [
    "{k} hält. Natürlich hält {k}.",
    "Der Keeper {k} ist da. Schade.",
    "{k} pariert sicher. Der hat heute Spaß.",
    "Gehalten von {k}. Der Mann ist eine Wand.",
  ],
  "save.opp.k": [
    "Gehalten! {k}, unser Held!",
    "{k} ist da! Stark gehalten!",
    "Parade {k}! So geht das!",
    "{k} fischt ihn raus! Wunderbar!",
  ],
  "save.own.big.k": [
    "NEIN! {k} hält das Ding! Wie macht der das?",
    "Unglaublich, {k}! Der hat einen Pakt mit dem Pfosten!",
    "{k} fliegt und hält! Ich hasse und bewundere diesen Mann!",
  ],
  "save.opp.big.k": [
    "WAHNSINN, {k}! Was für eine Parade!",
    "{k} rettet uns! {k}! {k}! {k}!",
    "Den hält {k} mit den Fingerspitzen! Weltklasse!",
  ],
};
