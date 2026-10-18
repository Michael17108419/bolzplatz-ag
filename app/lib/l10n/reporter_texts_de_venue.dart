// The German texts of the radio reporter, part six (step 10e4): the
// ground, the crowd, derbies and the trip of the guests. `{crowd}` is the
// attendance, `{stadium}` the ground, `{derby}` the name of a great
// rivalry, `{km}` the road kilometres of the guests.

const Map<String, List<String>> reporterVenueDe = {
  // ---------------------------------------------------------------- crowd
  "crowd.sold": [
    "Ausverkauft! {crowd} Zuschauer in der {stadium}, kein Platz mehr frei, "
        "nicht mal auf dem Klo.",
    "{crowd} Fans, die {stadium} platzt aus allen Nähten. Was für eine "
        "Kulisse!",
    "Die {stadium} ist voll bis unters Dach: {crowd} Zuschauer. Gänsehaut!",
    "Ausverkauftes Haus, {crowd} Menschen. Wer jetzt noch kommt, steht "
        "draußen.",
  ],
  "crowd.high": [
    "{crowd} Zuschauer in der {stadium}. Fast voll, ordentlich Lärm.",
    "Gut gefüllt heute: {crowd} Fans in der {stadium}.",
    "{crowd} Zuschauer sind gekommen. Die Stimmung stimmt.",
    "Die {stadium} ist gut besucht, {crowd} Leute. Die Kurve singt schon.",
  ],
  "crowd.mid": [
    "{crowd} Zuschauer in der {stadium}. Luft nach oben, wie man so sagt.",
    "Halb voll oder halb leer? {crowd} Fans verlieren sich in der "
        "{stadium}.",
    "{crowd} sind da. Die anderen haben wohl was Besseres vor.",
    "Die {stadium} mit {crowd} Zuschauern. Man hört jeden Zwischenruf.",
  ],
  "crowd.low": [
    "{crowd} Zuschauer. Man kann sie fast persönlich begrüßen.",
    "Gähnende Leere in der {stadium}: {crowd} Unentwegte.",
    "{crowd} Fans, darunter vermutlich die Familie des Torwarts.",
    "Viel Platz auf den Rängen, {crowd} Zuschauer. Die Würstchen bleiben "
        "warm.",
  ],
  "crowd.final": [
    "Finale! {crowd} Zuschauer im großen Stadion der Hauptstadt. Mehr geht "
        "nicht.",
    "{crowd} Menschen, zwei Kurven, ein Pokal. Endspielstimmung!",
    "Das Finale vor {crowd} Zuschauern. Wer hier gewinnt, wird unsterblich. "
        "Zumindest bis nächste Saison.",
  ],

  // --------------------------------------------------------------- derbies
  "derby.named": [
    "Und heute ist {derby}! Da zählt keine Tabelle, nur die Ehre.",
    "{derby}! Die halbe Stadt hat sich freigenommen.",
    "Es ist {derby}. Freundschaften pausieren für neunzig Minuten.",
    "{derby} – das Spiel, für das man das ganze Jahr lebt.",
  ],
  "derby.named.3": [
    "Heute ist {derby}, das heißeste Spiel des Jahres! Polizei mit "
        "Großaufgebot, Fans mit Großmaul.",
    "{derby}! Wer heute verliert, traut sich morgen nicht zum Bäcker.",
    "Es ist {derby}. Hier gibt es keine Freundschaftsspiele, nur Kriege "
        "mit Ball.",
  ],
  "derby.3": [
    "Stadtderby! Die Fans kennen sich, die Spieler kennen sich, und keiner "
        "mag den anderen.",
    "Ein Derby in derselben Stadt. Wer heute verliert, muss sich das ein "
        "Jahr lang anhören.",
    "Heute geht's um die Vorherrschaft in der Stadt. Und um Gratisbier für "
        "die Sieger.",
  ],
  "derby.2": [
    "Ein Nachbarschaftsderby! Die Anreise war kurz, die Abneigung ist lang.",
    "Derby heute. Man wohnt nah beieinander und kann sich trotzdem nicht "
        "leiden.",
    "Nachbarn unter sich. Da wird jeder Zweikampf persönlich.",
  ],
  "derby.1": [
    "Ein kleines Regionalderby. Ein bisschen Würze ist drin.",
    "Regionalderby heute, die Gäste haben viele Fans mitgebracht.",
    "Man kennt sich aus der Gegend. Das gibt Zündstoff.",
  ],

  // ---------------------------------------------------------------- travel
  "travel.own": [
    "Wir sind {km} Kilometer im Bus gesessen. Die Beine sind schwer, die "
        "Hintern platt.",
    "{km} Kilometer Anreise für uns. Hoffentlich haben die Jungs im Bus "
        "geschlafen.",
    "Eine lange Fahrt, {km} Kilometer. Ob das in den Knochen steckt?",
    "Unser Bus war {km} Kilometer unterwegs. Mal sehen, wie frisch die "
        "Beine sind.",
  ],
  "travel.opp": [
    "Die Gäste sind {km} Kilometer angereist. Seit sechs Uhr im Bus, das "
        "merkt man vielleicht.",
    "{km} Kilometer Anreise für {team}. Hoffentlich war die Raststätte "
        "schlecht.",
    "Lange Fahrt für die Gäste: {km} Kilometer. Müde Beine sind unser "
        "zwölfter Mann.",
    "{team} hat {km} Kilometer im Bus hinter sich. Das kann sich rächen.",
  ],

  // ------------------------------------------------- weather and ground
  "weather.sunny": [
    "Strahlender Sonnenschein. Die Torhüter haben ihre Kappen dabei.",
    "Bestes Fußballwetter, Sonne satt. Keine Ausreden heute.",
    "Die Sonne lacht. Ob sie das nach dem Spiel auch noch tut?",
  ],
  "weather.cloudy": [
    "Grauer Himmel, typisch deutscher Fußballnachmittag.",
    "Bewölkt, aber trocken. Der Rasen ist bereit.",
  ],
  "weather.rain": [
    "Es regnet. Der Ball wird schnell, die Grätschen werden lang.",
    "Nieselregen. Wer jetzt kein Regencape hat, wird zum Schwamm.",
    "Regen über dem Stadion. Technik wird heute zur Glückssache.",
  ],
  "weather.heavy_rain": [
    "Es schüttet wie aus Eimern! Der Platzwart hat schon zweimal gebetet.",
    "Starkregen. Kurzpassspiel heute? Viel Glück.",
    "Land unter! Der Ball bleibt in den Pfützen stecken.",
  ],
  "weather.snow": [
    "Es schneit! Der orange Ball kommt zum Einsatz.",
    "Schneegestöber. Die Spieler tragen Handschuhe und Leidensmienen.",
    "Weiße Pracht über dem Platz. Romantisch für die Zuschauer, die Hölle "
        "für Techniker.",
  ],
  "weather.heat": [
    "Brütende Hitze. Trinkpausen werden heute wichtiger als Taktik.",
    "Über dreißig Grad. Die Beine werden schwer, die Trikots nass.",
    "Hitzeschlacht! Wer heute neunzig Minuten Vollgas gibt, hat ein "
        "Kamelgen.",
  ],
  "weather.wind": [
    "Stürmischer Wind. Lange Bälle landen heute sonst wo.",
    "Es pfeift ganz schön über den Platz. Fernschüsse sind Lotterie.",
    "Windig heute. Die Eckfahnen stehen waagerecht.",
  ],
  "ground.wet": [
    "Der Platz ist nass und schnell. Ausrutscher garantiert.",
    "Nasser Rasen. Der Ball springt flach und tückisch.",
    "Rutschiger Boden heute, die Stollen werden gebraucht.",
  ],
  "ground.heavy": [
    "Der Platz ist ein Acker. Kombinationsfußball? Vergiss es.",
    "Tiefer Boden, Matsch bis zu den Knöcheln. Heute gewinnt, wer kämpft.",
    "Das ist kein Rasen mehr, das ist ein Kartoffelfeld.",
    "Schlammschlacht! Nach zehn Minuten sehen alle gleich aus.",
  ],
  "ground.frozen": [
    "Der Boden ist gefroren. Das wird eine Rutschpartie.",
    "Hart wie Beton, der Platz. Jeder Sturz tut doppelt weh.",
    "Gefrorener Rasen. Der Ball springt wie ein Flummi.",
  ],
};
