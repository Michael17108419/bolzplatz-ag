// The German texts of the radio reporter, part seven (steps 10f3, 10f5):
// team talks in the dressing room, keys `talk.<kind>.<how>.<side>` with
// kind `calm`, `fire` or `praise` and how `good`, `flat` or `bad`; changes
// of the coach, keys `coach.<what>.<side>`.

const Map<String, List<String>> reporterTeamDe = {
  // ----------------------------------------------------------------- calm
  "talk.calm.good.own": [
    "Unser Trainer hat in der Kabine die Ruhe reingebracht. Die Jungs kommen "
        "mit klarem Kopf raus.",
    "Ruhige Worte vom Chef, man sieht es den Gesichtern an: Die sind bei "
        "der Sache.",
    "Der Trainer hat die Nerven gestreichelt. Jetzt wird's sachlich.",
  ],
  "talk.calm.flat.own": [
    "Ruhige Ansprache in unserer Kabine. Ob das was bringt? Die Gesichter "
        "sagen: abwarten.",
    "Unser Trainer predigt Ruhe. Die Hälfte hat zugehört, die andere war "
        "auf dem Klo.",
  ],
  "talk.calm.bad.own": [
    "Beruhigen? Jetzt? Unser Trainer redet die Jungs in den Schlaf.",
    "Der Chef hat Ruhe gepredigt, die Mannschaft kommt raus wie nach dem "
        "Mittagsschlaf.",
  ],
  "talk.calm.good.opp": [
    "Drüben kommen sie sehr gefasst aus der Kabine. Da hat einer die "
        "richtigen Worte gefunden.",
    "{team} wirkt aufgeräumt. Der Trainer hat offenbar beruhigt.",
  ],
  "talk.calm.flat.opp": [
    "{team} kommt raus wie rein. Viel gesagt wurde da wohl nicht.",
  ],
  "talk.calm.bad.opp": [
    "Bei {team} hat der Trainer Ruhe verordnet. Die schlafen gleich ein. "
        "Uns soll's recht sein.",
  ],

  // ----------------------------------------------------------------- fire
  "talk.fire.good.own": [
    "Da muss es in der Kabine gekracht haben! Unsere Jungs kommen raus wie "
        "die Stiere.",
    "Der Trainer hat die Tür zugeknallt und ist laut geworden. Das hat gewirkt, "
        "die brennen!",
    "Man hört bis hier oben, dass es in unserer Kabine laut war. Jetzt "
        "geht's los!",
  ],
  "talk.fire.flat.own": [
    "Der Chef hat gebrüllt, aber so richtig angezündet wirkt keiner.",
    "Laute Worte in unserer Kabine. Der Funke ist noch nicht übergesprungen.",
  ],
  "talk.fire.bad.own": [
    "Unser Trainer hat getobt, und jetzt sind einige zu heiß. Das gibt "
        "Karten, wetten?",
    "Die Kabinenpredigt war zu viel des Guten. Die rennen jetzt wie kopflose "
        "Hühner.",
  ],
  "talk.fire.good.opp": [
    "{team} kommt wie verwandelt aus der Kabine. Da hat der Trainer "
        "Feuer gemacht.",
    "Drüben ist jetzt Zug drin. Die Kabinenpredigt hat gesessen.",
  ],
  "talk.fire.flat.opp": [
    "Bei {team} war es laut in der Kabine. Gebracht hat es bisher nichts.",
  ],
  "talk.fire.bad.opp": [
    "Der Trainer von {team} hat seine Leute zu heiß gemacht. Die treten "
        "gleich nach allem, was sich bewegt.",
  ],

  // --------------------------------------------------------------- praise
  "talk.praise.good.own": [
    "Lob vom Chef in der Kabine. Die Jungs gehen mit breiter Brust raus.",
    "Der Trainer hat alle in den Arm genommen. Das Selbstvertrauen ist "
        "spürbar.",
    "Schulterklopfen in unserer Kabine. So macht Fußball Spaß.",
  ],
  "talk.praise.flat.own": [
    "Ein paar nette Worte vom Trainer. Ob die jemand gebraucht hat?",
    "Lob in der Kabine, freundlich zur Kenntnis genommen.",
  ],
  "talk.praise.bad.own": [
    "Loben? Nach der Halbzeit? Unser Trainer hat ein anderes Spiel gesehen "
        "als wir.",
    "Der Chef verteilt Lob, und die Mannschaft guckt sich verwirrt an. Das "
        "ging nach hinten los.",
  ],
  "talk.praise.good.opp": [
    "{team} kommt bestens gelaunt aus der Kabine. Da gab es Lob.",
  ],
  "talk.praise.flat.opp": [
    "Drüben gab es wohl ein paar freundliche Worte. Wirkung: überschaubar.",
  ],
  "talk.praise.bad.opp": [
    "Der Trainer von {team} hat gelobt, wo es nichts zu loben gab. Die "
        "wirken jetzt satt. Danke!",
  ],

  // ---------------------------------------------------------------- coach
  "coach.deep.own": [
    "Unser Trainer lässt tiefer stehen. Respekt vor dem Gegner, oder Angst?",
    "Wir ziehen uns zurück und lauern. Kontern ist auch Fußball.",
  ],
  "coach.deep.opp": [
    "{team} stellt sich hinten rein. Die haben Respekt vor uns!",
    "Der Trainer drüben lässt tief verteidigen. Da müssen wir Geduld haben.",
    "{team} mauert von Beginn an. Das wird ein Geduldsspiel.",
  ],
  "coach.chase.own": [
    "Unser Trainer wirft alles nach vorn! Pressing, Tempo, alles oder "
        "nichts.",
    "Jetzt wird umgestellt: hoch pressen, schnell spielen. Hinten wird's "
        "luftig.",
  ],
  "coach.chase.opp": [
    "Der Trainer drüben stellt um: {team} läuft jetzt hoch an.",
    "{team} macht auf, die wollen den Ausgleich. Platz für unsere Konter!",
    "Drüben wird gewunken und gebrüllt. {team} geht volles Risiko.",
  ],
  "coach.hold.own": [
    "Unser Trainer zieht die Handbremse. Hinten dicht, die Uhr ist unser "
        "Freund.",
    "Wir parken den Bus. Schön ist anders, aber Punkte sind Punkte.",
  ],
  "coach.hold.opp": [
    "{team} zieht sich zurück und verwaltet. Der Trainer drüben will das "
        "über die Zeit bringen.",
    "Drüben wird der Bus geparkt. Jetzt müssen wir das Bollwerk knacken.",
    "{team} spielt auf Zeit. Zehn Mann am eigenen Strafraum.",
  ],
  "coach.open.own": [
    "Die Führung ist weg, unser Trainer schaltet wieder auf normal.",
  ],
  "coach.open.opp": [
    "Der Bus ist ausgeparkt: {team} muss nach dem Ausgleich wieder "
        "mitspielen.",
  ],
  "coach.ten.own": [
    "In Unterzahl stellt unser Trainer um: hinten dicht, vorne hoffen.",
  ],
  "coach.ten.opp": [
    "{team} stellt nach dem Platzverweis um, zehn Mann ziehen sich zurück.",
    "Der Trainer drüben reagiert auf die Rote: Abwehrriegel.",
  ],
  "coach.panic.own": [
    "Was macht unser Trainer da? Die Umstellung versteht auf der Tribüne "
        "keiner.",
    "Hektik an unserer Bank. Das sieht nach Panik aus, nicht nach Plan.",
  ],
  "coach.panic.opp": [
    "Was macht der Trainer drüben? Eine Umstellung, die keiner versteht. "
        "Uns soll's recht sein.",
    "Panik an der Bank von {team}. Da wird wild durcheinander gewechselt.",
    "Der Trainer von {team} hat offenbar sein Taktikbuch verlegt.",
  ],

  // ---------------------------------------------------- cards for delay
  "yellow.delay.own": [
    "Gelb für {p} wegen Zeitspiel. Der Trainer hat es so gewollt, der Schiri "
        "nicht.",
    "{p} trödelt zu auffällig: Gelb. Clever ist anders.",
  ],
  "yellow.delay.opp": [
    "Gelb für {p}, der wollte den Ball am liebsten mit nach Hause nehmen.",
    "Endlich! Gelb wegen Zeitspiel für {p}. Das hat gedauert.",
  ],
};
