ï»¿class TextDe implements mt.Protect {//}

	  /////////////////
	 /// INTERFACE ///
	////////////////

	public static var FUEL_TITLE = "DER TREIBSTOFFTANK IST LEER!!!";
	public static var FUEL_TEXT = "<p><b>Du besitzt keine Wasserstoffkapseln mehr!</b></p><p>ESCorp stellt dir heute um Mitternacht drei neue Kapseln <font color='#00FF00'>gratis</font> zur VerfÃ¼gung.</p><p>Wenn du mÃ¶chtest, kannst du allerdings sofort weiterspielen, wenn du die Interstellare Bank benutzt!</p>";
	public static var FUEL_BANK = "INTERSTELLARE BANK";

	public static var PAUSE_TEXT = [ "WAEHLE EINE KAPSEL AUS ODER DRUECKE AUF \"P\", UM DIE PAUSE ZU BEENDEN","DRUECKE AUF \"P\", UM DIE PAUSE ZU BEENDEN"];

	public static var WARNING_ZONE = "ZEIGER AUSSERHALB DES SPIELS!";
	public static var START_CLIC_GREEN = "KLICK AUF DIE GRUENE ZONE, UM ZU STARTEN";

	public static var WARNING_FAR = "Diese Koordinate kann nicht in einem Zug erreicht werden!\nDu musst dich von Feld zu Feld bewegen, um diesen Punkt zu erreichen.";
	public static var WARNING_CARDS = "Achtung! Du bist gerade dabei die vorgeschriebene Zone zu verlassen.\nDeine Standard-Kugel ist fÃ¼r diese Zone nicht stark genug.\n Besorge dir folgende Akkreditierungen:";
	public static var WARNING_CNX = "Die Verbindung wurde unterbrochen!\nDie Spieldaten wurden nicht gespeichert.";

	public static var ERROR_CRC = "Es ist ein Fehler beim Verbindungsaufbau aufgetreten. Dieser Fehler kann zustande kommen, wenn du AlphaBounce in zwei verschiedenen Tabs oder mit zwei verschiedenen Browsern aufrufst.";

	public static var CONNECTION_SERVER = "VERBINDUNG ZUM SERVER...";

	public static var PREF_FLAGS = ["TASTATURBEFEHLE","SICHTBARE BEWEGUNGEN","WARNZONE","KONTRASTREICHE KUGEL"];
	public static var PREF_TITLE = "EINSTELLUNGEN";
	public static var PREF_MOUSE = "MAUSEMPFINDLICHKEIT";
	public static var PREF_QUALITY = "GRAPHIK-QUALITAET";

	public static var CAPS_NAME = ["LEERE","EIS","FEUER","BLITZ"];


	  ////////////
	 /// GAME ///
	////////////

	public static var ITEM_NAMES =		[
		"Erstes Level",
		"Alpha-Akkreditierung",
		"Beta-Akkreditierung",
		"Ceta-Akkreditierung",
		"Bohrkugel",
		"Hilferuf",
		"Douglas",
		"Zentraler TrÃ¼mmerhaufen",
		"Schneidender TrÃ¼mmerhaufen",
		"Einzelner TrÃ¼mmerhaufen",
		"Rauchender TrÃ¼mmerhaufen",
		"Interessanter TrÃ¼mmerhaufen",
		"Winziger TrÃ¼mmerhaufen",
		"Unbedeutender TrÃ¼mmerhaufen",
		"RaumschiffvergrÃ¶Ãerung",
		"Seltsame Symbole",
		"Salmeen",
		"---",
		"Rakete",

		"HÃ¤ndlerkarte",
		"Blaue Rakete",
		"Schwarze Rakete",
		"Lycanisischer Stein",
		"Spignysos-Stein",
		"Roter Stern",
		"Orangener Stern",
		"Gelber Stern",
		"GrÃ¼ner Stern",
		"TÃ¼rkisfarbener Stern",
		"Blauer Stern",
		"Lilaner Stern",
		"Level Editor",
		"Medaillon - Rundes StÃ¼ck",
		"Medaillon - SichelfÃ¶rmiges StÃ¼ck",
		"Medaillon - HohlfÃ¶rmiges StÃ¼ck",
		"Moltarinisches Medaillon",
		"OX-Soldat Kugel",
		"OX-Delta Kugel",
		"Asphalt-Kugel",
		"Rote Rakete",
		"Ambro-X",
		"Radar ok",
		"Generator",

		"Anti-Materie-Kern",
		"Anti-Materie-Kern",
		"Anti-Materie-Kern",
		"Anti-Materie-Kern",

		"Strafbefehl wegen Flucht",
		"AtmosphÃ¤rischer Schild",
		"ÃuÃere Panzerung",
		"Hydraulische Stabilisatoren",
		"Reaktorwrackteil",
		"AtmosphÃ¤rentriebwerk",
		"Raumanzug",
		"Salmeens Cousin",
		"FURI Ausweis",
		"Karbonis-Ring Pass",

		"RaumschiffvergrÃ¶Ãerung 2",
		"Rosa Kristall A",
		"Rosa Kristall B",
		"Rosa Kristall C",
		"Rosa Kristall D",
		"Rosa Kristall E",
		"Pergament A",
		"Pergament B",
		"Pergament C",
		"Pergament D",
		"Pergament E",
		"Pergament F",
		"Pergament G",
		"Pergament H",
		"Synthogenetischer Beschleuniger",
		"RaumschiffvergrÃ¶Ãerung 3",
		"Saumirs Kugelverdoppler",
		"Dr Sactus' Raumfusionator",

		"Karbonit-Tafel",
		"Karbonit-Tafel",
		"Karbonit-Tafel",
		"Karbonit-Tafel",
		"Karbonit-Tafel",
		"Karbonit-Tafel",
		"Karbonit-Tafel",
		"Karbonit-Tafel",
		"Karbonit-Tafel",
		"Karbonit-Tafel",
		"Karbonit-Tafel",
		"Karbonit-Tafel",

		"Karbonit-Ingenieur",
		"Mine Fora 7R-Z",

		"Kartenelement PID no1",
		"Kartenelement PID no2",
		"Kartenelement PID no3",
		"Kartenelement PID no4",
		"Kartenelement PID no5",
		"Kartenelement PID no6",
		"Kartenelement PID no7",
		"Kartenelement PID no8",
		"Kartenelement PID no9",
		"Kartenelement PID no10",
		"Kartenelement PID no11",
		"Kartenelement PID no12",
		"Kartenelement PID no13",
		"Kartenelement PID no14",
		"Kartenelement PID no15",
		"Kartenelement PID no16",
		"Kartenelement PID no17",
		"Kartenelement PID no18",
		"Kartenelement PID no19",
		"Kartenelement PID no20",
		"Kartenelement PID no21",
		"Kartenelement PID no22",
		"Kartenelement PID no23",
		"Kartenelement PID no24",
		"Kartenelement PID no25",
		"Kartenelement PID no26",
		"Kartenelement PID no27",
		"Kartenelement PID no28",
		"Kartenelement PID no29",
		"Kartenelement PID no30",
		"Kartenelement PID no31",
		"Kartenelement PID no32",
		"Kartenelement PID no33",
		"Kartenelement PID no34",
		"Kartenelement PID no35",
		"Kartenelement PID no36",
		"Kartenelement PID no37",
		"Kartenelement PID no38",
		"Kartenelement PID no39",
		"Kartenelement PID no40",
		"Kartenelement PID no41",
		"Kartenelement PID no42",

		"Erden-Pass",
		"Schwieriger Modus",
	];

	public static var SHOP_ITEM_NAMES = [
		"Antrieb v1",
		"Antrieb v2",
		"Antrieb v3",
		"Antrieb v4",
		"Antrieb v5",
		"Antrieb v6",
		"Raketenkarte",
		"Sonnenbrille",
		"Optim. Rakete no1",
		"Optim. Rakete no2",
		"Optim. Rakete no3",
		"Eiskapsel",
		"Feuerkapsel",
		"Schwarzes Loch-Kapsel",
		"Solide Wasserstoff-Kapsel",
		"Seitenduesen",
		"Fluessigkuehlung",
		"Munitionsnachschub",
		"Notraumschiff",
		"Hilfsdrohne",
		"Drohne > Bohrwerkzeuge",
		"Drohne > UnterstÃ¼tzungsreaktor",
		"Drohne > Umwandlerin",
		"Drohne > Sammlerin",
		"Notradar",
		"Blitzkapsel",
		"Permanent synthetisierender Antrieb",
		"KI-WI-Antenne",

		"Landestuetzen",
		"Landestuetzenverlaengerung",
		"Spezielle Landestuetzenverlaengerung",
		"Ultimative Landestuetzenverlaengerung",
		"Atmosphaerentriebwerk - Turbo",
		"Atmosphaerentriebwerk - Turbo-X2",
		"Atmosphaerentriebwerk - Turbo-X3",

		"Zusaetzliche Mine no1",
		"Zusaetzliche Mine no2",
		"Zusaetzliche Mine no3",
	];

	public static var OPTION_NAMES = [
		"ANZIEHUNG",
		"BLOCKADE",
		"CREME",
		"DEGRESSION",
		"ERWEITERUNG",
		"FLAMME",
		"GEFRIERPUNKT",
		"HALO",
		"INKONTINENZ",
		"JUPITERS SPEER",
		"KAMIKAZE",
		"LASER",
		"MULTI-BALL",
		"NEUER BALL",
		"OEFFNUNG",
		"PRODUKTION",
		"QUASAR",
		"REGENERATION",
		"SAFETY",
		"TRANSFORMATION",
		"ULTRAVIOLETT",
		"VOLT",
		"WHISKY",
		"XANAX",
		"YOYO",
		"ZIEMLICH SCHNELL",
		"MISSILE",
	];

	  //////////////
	 /// ENDING ///
	//////////////

	public static var OUTRO_0 = "Nachdem du mehrere Monate im All herumgeirrt bist, kehrst du nun zur Erde zurÃ¼ck.\n\nDeine RÃ¼ckkehr hat fÃ¼r einen groÃen Medienrummel gesorgt und die ESCorp dazu verpflichtet seine Verpflichtungen dir gegenÃ¼ber einzuhalten.\n\nDu bist ab sofort frei und kannst tun und lassen, was du mÃ¶chtest...\n\n\n\n Was hast du als nÃ¤chstes vor?";

	public static var OUTRO_1 = "Nachdem du mehrere Monate im All herumgeirrt bist, kehrst du nun zur Erde zurÃ¼ck.\n\nDeine aufsehenerregenden EnthÃ¼llungen Ã¼ber die Machenschaften der ESCorp haben einen wahren Skandal in den Medien ausgelÃ¶st.\n\nDu bist ab sofort frei und kannst tun und lassen, was du mÃ¶chtest...\n\n\n\n Was hast du als nÃ¤chstes vor?";

	public static var OUTRO_2 = [
		[ 	"Ein ruhiges Leben fÃ¼hren",
			"Die ESCorp wird dein Raumschiff samt all seiner Verbesserungen beschlagnahmen.\nDein aktueller Spielstand geht dabei verloren.",
			"Der <font color='#ff0000'>schwierige Modus</font> von Alphabounce wird freigeschaltet."
		],
       [   "Du startest erneut ins Weltall",
           "Dabei wirst unverzÃ¼glich an den Ursprungspunkt Startpunkt gebeamt und behÃ¤ltst alle deine Raumschiffverbesserungen.",
           "Dein Radar und dein Antrieb bekommen eine permanentes Upgrade!"
		],
	];

	  //////////////
	 /// EDITOR ///
	//////////////

	public static var EDITOR_CLIC_SUPPR = "Klick + Entfernen: LÃ¶scht einen Stein.";

	public static var EDITOR_BUTS = [
		"ZURUECK",
		"STEINE LOESCHEN",
		"SPEICHERN",
		"MODERATION",
		"LEVEL ZURUECKSETZEN",
		"ANNEHMEN",
		"ALLES VERWERFEN"
	];

	  ////////////////
	 /// TRAVELER ///
	////////////////

	public static var TRAVELER_NAMES = [ "Walter", "Ben", "Jokarix", "Goshmael", "Mirmonide", "Korkan", "Gifu","Birman","Falgus","Moktin","Bifouak","Lacune","Gibarde","Blafaro","Kimper","Sochmo","Nicolu","Mangerin","Difidus","Stridan","Glochar","Mikou","Kilian","Daston","Possei","Spido","Corneli","Brifuk","Colcanis","Frederak","Coustini","Darnold","Fruncky","Jimic","Sachude","Bramhan","Nucrcela","Baguera","Ismael","Gorgonzi","Bashkod","Dangoren","Astefik","Mouroud","Babacar","Disnouie","Kisby","Bastiar","Amilou","Fromest","Ambrun","Caushmil","Poubreso","Flaurest","Moliur","Nasting","Boumbo","Kig","Sproutch","Zoobik","Morvoyeu","Shandwiz","Guilbard","Mocheron","Lakune","Stokoln","Tartantua","Saphyr","Gouperin","Chogrom","Kaskubi","Panzeman","Yuyu","Pirlui","Saxtan","Coulepron","Barzan","Jean-Cloud","Chourizou","Stupood","Drasteam","Weathy"];

	public static var TRAVELER_JOBS = [
		"Klempner",
		"Informatiker",
		"Megakrobat",
		"Serienkiller",
		"::stuff0::-::user::",
		"::stuff1::-::user::",
		"Geheimagent der ESCorp",
		"Fan des Singers ::singer::",

	];

	public static var TRAVELER_USER = [	"VerkÃ¤ufer",
		"Schlucker",
		"Tester",
		"Werfer",
		"Bastler",
		"JÃ¤ger",
	];

	public static var TRAVELER_STUFF_0 = [
		"Sahne",
		"GefÃ¼hle",
		"Rahmquark",
		"Bier",
		"Wasserstoffkapsel",
		"Stein",
		"Edelstein",
		"Plasmaenergie",
		"Kabel",
		"FlÃ¼ssigschuh",
		"FleischcrÃ¨me",
		"Raumschiffwrack",
		"DÃ¶ner",
		"Taschenlampen",
		"SNES-Cartridge",
		"Sushi",
		"Croissant",

	];

	public static var TRAVELER_STUFF_1 = [
		"Garnelen",
		"Rolltreppen",
		"Spargel",
		"Riesenspinnen",
		"Flatscreen",
		"Gebrauchtraumschiff",
		"Modellraumschiff",
		"HÃ¼ftgelenk",
		"Orangen",
		"Abziehbild",
	];

	public static var TRAVELER_MISS = [
		"Selbstvertrauen",
		"Geld",
		"Graue Materie",
		"Zeit fÃ¼r mich",
		"Freundinnen",
		"MÃ¶glichkeiten wahrgenommen zu werden",
		"Leute in meiner Umgebung",
	];


	public static var TRAVELER_SINGER = [
		"Tita Bolen",
		"Horny Harpendale",
		"Randy Borg",
		"Schuasta Michi",
		"Kurt Cobein",
		"60 cent",
	];

	public static var TRAVELER_INTRO = [
		"Guten Tag terrestrischer Gefangener,\n",
		"Guten Tag,\n",
		"Guten Tag Fremder,\n",
		"Herzlich willkommen Fremder,\n",
		"Ich habe deine Ankunft schon seit langem erwartet...\n",
		"Endlich mal Besuch!\n",
		"Hmmpf!\n",
		"Haalooo! Ist da jemand?\n",
		"Wer ist da?\n",
		"Hi!\n",
	];

	public static var TRAVELER_WHO = [
		"Ich heiÃe ::name:: und bin ::profession:: auf diesem Planeten.",
		"Ich heiÃe ::name::, du kannst mich siezen, wenn du mÃ¶chtest.",
		"Ich bin ein einfacher ::profession::.",
		"Man nennt mich ::name::, den ::profession::.",
		"Ich heiÃe ::name::, mÃ¶chtest du mein Freund sein?",
		"Ich heiÃe ::name:: und ich habe nicht mehr viel ::miss:: seitdem ich ::profession:: bin.",
		"Wer bist du? Ich bin ::name::, der ::profession::.",
	];

	public static var TRAVELER_LEAVE = [
		"Ich versuche schon seit Jahren ::start:: zu verlassen...",
		"Es gefÃ¤llt mir nicht mehr auf ::start::,",
		"::start:: ist wirklich kein angenehmer Ort, um hier zu leben,",
		"Auf ::start:: kann man nichts interessantes unternehmen,",
		"Glaubst du, dass du auf ::start:: leben kannst? Ich jedenfalls habe meine Dosis schon abbekommen...",
		"Es gibt hier nicht so viele Leute... Wenn das so weitergeht verliere ich noch meine Arbeit.",
	];


	public static var TRAVELER_DEST = [
		"Tief in mir weiÃ ich, dass mich ein besseres Leben auf ::end:: erwartet.",
		"Vielleicht kann ich auf ::end:: wieder bei Null beginnen.",
		"Ich habe schon immer davon getrÃ¤umt nach ::end:: zu gehen",
		"Mein Traum ist es nach ::end:: zu gehen",
	];

	public static var TRAVELER_DEST_COORD = [
		"Ich muss meinen SchlÃ¼sselanhÃ¤nger wiederfinden... Hab ihn wohl wÃ¤hrend meines Ausflugs in der NÃ¤he der Position ::pos:: verloren.",
		"Mein Ziel ist es eine neue Weltraumkolonie in der NÃ¤he von ::pos:: zu grÃ¼nden.",
		"Ich mÃ¶chte gern eine neues WeltraumgeschÃ¤ft in ::pos:: erÃ¶ffnen.",
		"Wenn du mich nach ::pos:: bringen kÃ¶nntest, dann kÃ¶nnte ich dort meinen Onkel wiederfinden. Er besitzt einen Satelitten-Burger-Drive-In.",
		"Ich habe von einer angesagten Astro-Disco in ::pos:: gehÃ¶rt.",
		"Ein paar ::stuff0::-Kisten wurden an der Position ::pos:: abgelegt. Ich mÃ¶chte da so schnell wie mÃ¶glich hin!",
		"Ich weiÃ aus sicherer Quelle, dass ::singer:: diese Woche ein Ãberraschungskonzert in ::pos:: geben wird.",
	];

	public static var TRAVELER_ASK_0 = [
		"Kannst du mich dorthin bringen?",
		"KÃ¶nntest du mich auf meiner Reise dorthin begleiten?",
		"KÃ¶nnte ich mit dir bis dorthin reisen?",
		"Kann ich mit dir gehen?",
	];

	public static var TRAVELER_ASK_1 = [
		"Ich brÃ¤uchte eines deiner Raumschiffe, um dorthin zu gelangen.",
		"Ich brÃ¤uchte ein Notraumschiff, um dir zu folgen. Ich bin zu groÃ, um im gleichen Raumschiff zu reisen.",
	];

	public static var TRAVELER_REWARD_MIN_0 = [
		"Wenn du mich dorthin bringst, gebe ich dir ::rmin:: Mineralien.",
		"Ich kann fÃ¼r den Flug ::rmin:: Mineralien bezahlen.",
	];

	public static var TRAVELER_REWARD_MIN_1 = [
		"Das sind meine ganzen Ersparnisse!",
		"Ich habe sonst nichts.",
		"Du musst ja nicht alles nehmen...",
		"Ich hoffe das ist genug.",
	];

	public static var TRAVELER_REWARD_KEUD = [
		"",
		"Ich kann dir fÃ¼r die Fahrt leider nichts bezahlen, aber ich bin mir sicher, dass du ein gutes Herz hast...",
	];

	public static var TRAVELER_REWARD_CAPS = [
		"Ich kann auch etwas zum Treibstoff beisteuern : ::rcap:: CHS !",
		"FÃ¼r den Treibstoff kann ich dir ::rcap:: CHS geben. Damit dÃ¼rften wir ein gutes StÃ¼ck vorankommen.",
	];

	public static var TRAVELER_NO_SLOT = "\nDu kannst mir leider nicht helfen...\nDanke trotzdem, dass du mich besucht hast. Es tut wirklich gut mit jemanden zu reden.";

	public static var TRAVELER_LEAVE_PLANET = [
		[	// 0 - MOLTEAR
			"Die WeltraummolekÃ¼le machen uns das Leben echt zur HÃ¶lle... Gestern haben sie meine WohnzimmertÃ¼r zugemauert.",
			"Die MolekÃ¼le breiten sich in der Gegend sehr schnell aus. Ich glaube es ist Zeit aufzubrechen.",
			"Es ist unertrÃ¤glich! Die MolekÃ¼le haben heute morgen erneut meine(n) ::stuff0:: (e/n/s) zerstÃ¶rt. Es gibt keinen Grund mehr fÃ¼r mich hierzubleiben.",
		],
		[	// 1 - SOUPALINE
			"Die Meeresluft auf Soupaline ist mir noch nie gut bekommen. AuÃerdem glaube ich, dass das Salz mir so langsam das Hirn wegfrisst."

		],
		[	// 2 - LYCANS
			"::start:: ist wirklich viel zu unsicher fÃ¼r mich. Erst gestern wurde der ::stuff0::-Lieferant aufgrund einer OberflÃ¤chenexplosion in der Orbit geschossen!",
			"Glaubst du, dass du auf ::start:: leben kannst? Hier gibt es jede Nacht um die 20 Explosionen",
			"Ich habe seit Anfang des Jahres 13 Shmolgs verloren... Und das aufgrund der Schwefelexplosionen auf ::start::.",
		],
		[""],	// 3 - SAMOSA
		[	// 4 - TIBOON
			"Sand, Sand und nichts weiter als Sand... Hier gibt es sonst nichts...",
			"Ich habe alle DÃ¼nen auf ::start:: erkundet, aber jetzt ist es an der Zeit etwas anderes zu machen.",
		],
		[	// 5 - BALIXT
			"Die Balixtiner sind ein unterdrÃ¼ckerisches und rachsÃ¼chtiges Volk. Die Situation hier ist unertrÃ¤glich!",
			"Franxis wurde gestern mit voller Wucht von einer Reduktrine getroffen. Ich habe ihn seitdem nicht mehr wiedergesehen!",
			"Der neue Gouverneur auf Balixt schreibt Fremden unertrÃ¤gliche Lebensbedingungen vor.",
		],
		[""],	// 6 - KARBONIS
		[	// 7 - SPIGNYSOS
			" Auf ::start:: ist tote Hose im Winter... wenn du verstehst, was ich meine...",
			"Hast du dieses grÃ¤Ãliche Wetter gesehen? Es kommt absolut nicht in Frage, dass ich noch eine Minute lÃ¤nger auf ::start:: bleibe!",
			"Gestern Nacht hat das Thermometer -50Â° angezeigt und ich habe einen Zeh verloren...",
			"Meine ::stuff0::(e/n/s) sind gestern Nacht vereist!",
		],
		[	// 8 - POFIAK
			"::start:: ist viel zu feucht fÃ¼r mich. Ich werde noch krank, wenn ich hier noch lÃ¤nger bleibe.",
			"Die permanenten Angriffe der psionischen Insekten haben mich dazu bewogen ::start:: zu verlassen.",

		],
		[""],	// 9 - SENEGARDE
		[	// 10 - DOURIV
			"Es kommen viel zu viele Minenarbeiter hierher. Wenn das so weiter geht, wird ::start:: vollstÃ¤ndig von autonomen Minen bevÃ¶lkert sein!",

		],
		[""],	// 11 - GRIMORN
		[	// 12 - DTRITUS
			"Die GeruchsqualitÃ¤t dieses Planeten lÃ¤sst doch sehr zu wÃ¼nschen Ã¼brig, und Ã¼berhaupt, Kinder essen, ist nicht so ganz mein Ding..."
		],
		[ 	// 13 - ASTEROBELT
			"Das Leben eines einsamen Eremiten, der auf einem Asteroiden lebt, interessiert mich nicht mehr wirklich."
		],
		[	// 14 - NALIKORS
			"Tag fÃ¼r Tag gibt es mehr RAID von seiten der ESCorp. Ich glaube, dass mein Leben hier in Gefahr ist.",
			"Ich bin gekommen, um bei F.U.R.I. mitzumachen. Allerdings habe ich bezÃ¼glich Kefrids GrÃ¶Ãenwahn immer mehr Zweifel...",
		],
		[	// 15 - HOLOVAN
			"Ich habe mein Meditationsseminar bei den Kemilianern vor 37 Jahren begonnen.",
			"Seitdem ich mein Studium beendet hat, hÃ¤lt mich nichts mehr auf Holovan zurÃ¼ck.",
		],
		[	// 16 - Khorlan
			"Ich mÃ¶chte durchs Universum reisen, so wie Salmeen!",
			"Orbital-NÃ¼sse haben mein Dorf komplett verwÃ¼stet. Allein mein Haus steht noch! Ich mÃ¶chte hier nicht mehr lÃ¤nger bleiben!",
		],
		[	// 17 - CILORILE
			"Aufgrund der WÃ¤chter-Steine dÃ¼rfen wir uns jeden Tag zwischen 9h und 9h20 und abends zwischen 18h30 und 18h50 nicht bewegen. Das ist doch kein Leben! Ich mÃ¶chte so schnell wie mÃ¶glich Cilorile verlassen!"
		],
		[""],	// 18 - TARCITURNE
		[""],	// 19 - CHAGARINA
	];

	public static var TRAVELER_DEST_PLANET = [
		[	// 0 - MOLTEAR
			"Diese WeltraummolekÃ¼le sehen wirklich interessant aus. Vielleicht kann ich ja ihr Verhalten vor Ort studieren."
		],
		[	// 1 - SOUPALINE
			"Ozean soweit das Auge reicht, einfach nur zum TrÃ¤umen..."
		],
		[	// 2 - LYCANS
			"GroÃe Weiten... Eigentlich zÃ¤hlt doch nur das!"
		],
		[""],	// 3 - SAMOSA
		[	// 4 - TIBOON
			"Hier hab ich's bestimmt gemÃ¼tlicher als auf diesem Planeten hier.",
		],
		[	// 5 - BALIXT
			"Die Balixtiner brauchen viele ArbeitskrÃ¤fte, um ihr Imperium aufzubauen. Bestimmt brauchen sie auch einen ::profession:: .",
			"Die Installation von Reduktrinen benÃ¶tigt viel Arbeitskraft. Ich werde dort bestimmt einen Job finden.",
		],
		[""],	// 6 - KARBONIS
		[	// 7 - SPIGNYSOS
			"Hier erstickt man, ich brauche ein bisschen frische Luft.",
			"Die OberflÃ¤che ist so hell, dass man kaum seine Augen Ã¶ffnen kann!"
		],
		[	// 8 - POFIAK
			"Ich brauch etwas GrÃ¼nzeug."

		],
		[""],	// 9 - SENEGARDE
		[	// 10 - DOURIV
			"Ich habe gehÃ¶rt, dass man sich dort nur bÃ¼cken braucht, um die Kristalle aufzuheben! Zieht dich das nicht an?",
			"Ich kann dort leicht ein VermÃ¶gen machen. Es scheint so, als ob die OberflÃ¤che von Kristallen Ã¼berquellen wÃ¼rde!",
		],
		[""],	// 11 - GRIMORN
		[	// 12 - DTRITUS
			"Ich habe gehÃ¶rt, dass man dort ganz leicht Karriere machen kann, indem man Kinder erschreckt!"
		],
		[ 	// 13 - ASTEROBELT
			""
		],
		[	// 14 - NALIKORS
			"F.U.R.I. angehÃ¶ren und ein paar Abenteuer erleben, das ist mal eine Erfahrung!"
		],
		[	// 15 - HOLOVAN
			"Mein Traum ist es, Kemilianern zu begegnen und mit ihnen zu leben."
		],
		[	// 16 - KHORLAN
			"Ich brauche eine bisschen GrÃ¼nzeug."
		],
		[	// 17 - CILORILE
			"Meeresluft ist wirklich etwas feines!"
		],
		[""],	// 18 - TARCITURNE
		[""],	// 19 - CHAGARINA
	];


	  //////////////////
	 /// ITEM GIVER ///
	//////////////////

	public static var ITEM_GIVER_SALMEEN_COUSIN = "Hallo Salmeen!\nIst schon ne Weile her, dass wir uns nicht gesehen haben! Brauchst du was? Wie ich sehe, hast du einen Freund dabei. Ich schau mal, ob ich finde, was ihr sucht.\n*Gregune Ã¶ffnet eine groÃe Kiste, die sich am Ende des Raums befindet*\nDas ist es! Es handelt sich um einen speziellen Raumanzug fÃ¼r Suptirnen. Hier hast du also ein paar Ãrmel, die dir nicht viel nÃ¼tzen werden, aber normalerweise mÃ¼sste der Raumanzug einwandfrei sein. Der Raumanzug ist mit einem Jetpack ausgerÃ¼stet. Mit ihm mÃ¼sstest du dich einfacher bewegen kÃ¶nnen. Viel GlÃ¼ck euch beiden und bis bald!";

	public static var ITEM_GIVER_BADGE_FURI = "Herzlich willkommen, Kollege!\nDer RCEH braucht jede Hilfe, um die menschliche Expansion aufzuhalten. Wir haben keine diskriminierenden Aufnahmekriterien und dass du selbst ein Mensch bist ist kein Hindernisgrund uns beizutreten. Du kannst ab sofort an den Gefangenenbefreiungsaktionen und am Raub von ESCorp-Material in diesem System teilnehmen.\nVielen Dank fÃ¼r deine Hilfe!";

	public static var ITEM_GIVER_SAUMIR = "Fremder Noyaguld! Ich bin Saumir.\nDie Kemilianer heiÃen dich bei ihnen willkommen. Unser Volk hat sich vor Tausenden von Jahren auf Holovan zurÃ¼ckgezogen. Wir mÃ¶chten uns aus den Tatelbs eurer Ethnien heraushalten. Junge Zivilisationen wie die deinige mÃ¼ssen Schritt fÃ¼r Schritt ihren eigenen Weg gehen, bevor sie imstande sind, das Ziel des groÃen Koshmerate zu verstehen.\nMÃ¶ge Kluc mit dir sein, Fremder! Nimm diesen Kugelverdoppler, er wird dir eine groÃe Hilfe sein.";

	public static var ITEM_GIVER_SACTUS = "Guten Tag, Gefangener.\nIch bin Doktor Sactus, aber du kannst mich auch einfach \"Doc\" nennen. Das hier ist mein Labor. Mit Hilfe der eisenhaltigen Materialien aus Grimorn baue ich hier alle meine Antriebsmotoren. Hier ist der Raumfusionator, du kannst ihn haben. DrÃ¼cke auf gar keinen Fall mit deinem Zeigefinger auf die Mouse, wenn du ihn verwendest, sonst wirst du in das Zentrum der Zambreze-Supernova gebeamt. Nun, das wÃ¼rde sich auf deine molekulare Struktur nicht vorteilhaft sein.\nIch hoffe du hast meinen Anweisungen gut zugehÃ¶rt! Ciao! ";
	public static var ITEM_GIVER_SAFORI_0 = "Mein Name ist Safori. Ich habe mich nach der Explosion meines Geburtsplaneten Karbonis auf Nalikors niedergelassen.\nJetzt sitze ich hier fest. Ich wÃ¼rde gern wieder meiner HauptbeschÃ¤ftigung nachgehen: Ich bin ein Archenieur. Ich kann jede Maschine, egal wie alt sie ist, nachbauen, sofern ich die BauplÃ¤ne und die benÃ¶tigten Materialien besitze... Leider gibt es hier kein einziges Projekt, an dem ich arbeiten kÃ¶nnte.\nVielen Dank fÃ¼r deinen Besuch und bis bald!";

	public static var ITEM_GIVER_SAFORI_1 = "Fantastisch!! Dank dieser Tafeln kann ich endlich meine Arbeit beginnen! Lass uns mal sehen... mmmmh, das sieht interessant aus. Es kÃ¶nnte sich um ein altes  Steuerungssystem handeln. Ja, ich habe alle benÃ¶tigten Teile, um es zu bauen. Beweg dich nicht!\n............\n............\n............\n............\n............\n\nVoilÃ  !\nDas hier ist fÃ¼r dich! Mit diesem neuen Steuerungssystem verbessert sich die Reichweite des Radars deines Raumschiffs.\nVielen Dank fÃ¼r die Tafeln, ich werde sie bei mir behalten!!!\nAuf dass sich Shamus TÃ¼ren dir Ã¶ffnen, mein Freund!";

	public static var ITEM_GIVER_COMBINAISON = "Guten Tag Gefangener, dein Raumanzug ist fertig. FÃ¼ll bitte das Formular DZ-578 aus und hinterlass bitte einen Fingerabdruck in den Bereichen A, B und C dieses Vordrucks.\n...\nVielen Dank\n...\nHier ist dein Raumanzug.\nViel GlÃ¼ck.";

	public static var ITEM_GIVER_TABLET_KARBONIS_0 = "Karbonis' GedÃ¤chtnis";
	public static var ITEM_GIVER_TABLET_KARBONIS_1 = [
		" flieÃt in unseren Adern",
		" ist in jedem von uns",
		" darf nicht verschwinden",
		" leuchtet in deinen Augen",
		" ist ein wahrer Schatz",
		" wird fÃ¼r immer aufbewahrt werden",
		" ist das wertvollste Gut Zonkers",
		" ist in Shamus Herzen eingeschrieben",
		" darf nicht in die falschen HÃ¤nde geraten",
		" wird an diesem Ort aufbewahrt",
		" ist in jedem dieser Asteoriden vergraben",
		" ist in der Lage durch Raum und Zeit zu reisen.",
	];
	public static var ITEM_GIVER_TABLET_KARBONIS_2 = "...\nNimm diese Tafel an dich und beschÃ¼tze sie.";
	public static var ITEM_GIVER_TABLET_KARBONIS_3 = "Du bist hier nicht willkommen.";

	public static var ITEM_GIVER_EMAP_0 = "Herzlich willkommen Erdling. Ich glaube, dass dieses alte Artefakt aus deiner Zivilisation dir helfen wird, deinen Weg wiederzufinden. Ich verkaufe es dir fÃ¼r ::price:: Mineralien. Was hÃ¤lst du davon?  ";

	public static var BUTTON_PEOPLE = [
		"AKZEPTIEREN",
		"ABLEHNEN",
		"WEGGEHEN",
		"ANZEIGEN",
	];


	  ///////////////////
	 /// FURI MEMBER ///
	///////////////////

	public static var FURI_HELLO = [
		"Guten Tag mein Freund!\n",
		"Guten Tag Kollege!\n",
		"Hallo!\n",
		"Herzlich willkommen bei mir!\n",
	];

	public static var FURI_ARGUE = [
		"WeiÃt du wie viele Planeten im Universum durch Menschen besetzt sind oder ausgebeutet werden? Mehr als 35 Millionen! 30% werden durch die ESCorp ausgebeutet. Die ESCorp wÃ¼tet gerade in unserem System.\n",
		"Seitdem die ESCorp damit begonnen hat ihre Gefangenen in dieses System zu schicken, wurden mehrere Planeten, wie zum Beispiel Tiboon oder Lycans, verwÃ¼stet. Mit ihren gefÃ¤hrlichen Experimenten haben sie sogar den einst blÃ¼henden Planeten Karbonis zur Explosion gebracht.\n",
		"Seit ihrer Ankunft hier, hat ESCorps Missachtung jeglicher Naturgesetze wahre Naturkatastrophen ausgelÃ¶st. Die Explosion von Karbonis, der GeburtenrÃ¼ckgang der Glurts auf Moltear oder die Verschmutzung der Ozeane auf Soupalinee, all diese TragÃ¶dien sind wirklich abscheulich.\n",
		"Die ESCorp hat ihre Bohrungs- und Gefangenenausbeutungsarbeiten in diesem System vor Ã¼ber 30 Jahren begonnen. Seit ihrer Ankunft hier, hat ihre Missachtung jeglicher Naturgesetze wahre Naturkatastrophen ausgelÃ¶st. Die ErwÃ¤rmung der solaren Winde, der GeburtenrÃ¼ckgang der Glurts auf Moltear, all diese TragÃ¶dien sind das Ergebnis der Expansion der Menschenrasse.\n"
	];
	public static var FURI_REWARD_MIN = "Ich kann dir helfen, Kollege! Nimm diese ::rmin:: Mineralien und setze sie klug ein.\nDas ist alles, was ich habe.";
	public static var FURI_REWARD_CAPS = "Ich habe etwas fÃ¼r deine Mission, mein Freund! Nimm diese ::rcaps:: CHS.\nDank dir kann der Kampf weitergehen!";

	public static var FURI_END_0 = "Die Foundation for the Unification in a Rational way of the Infinite (F.U.R.I), ";
	public static var FURI_END_1 = [
				"setzt sich fÃ¼r eine nachhaltige Weltraumnutzung ein, die allen VÃ¶lkern Zugang zu allen Rohstoffen ermÃ¶glicht, ohne dabei die kosmische BiodiversitÃ¤t zu zerstÃ¶ren.",
				"kÃ¤mpft aktiv gegen die unkontrollierte menschliche Expansion im Weltall. Dabei fÃ¼hrt F.U.R.I Sabotageaktionen gegen menschliche Konzerne wie die ESCorp durch",
			];

	public static var FURI_BETRAY = [
		"Hilfe!",
		"Du hast eine wahrlich traurige Entscheidung getroffen, mein Freund.",
		"Woher dieser ganze Hass?",
		"Ich gehe mal davon aus, dass die ESCorp dich gut fÃ¼r deine Dienste bezahlt...",
	];


	public static var FURI_LUCK = [
		"Ich wÃ¼nsche dir viel GlÃ¼ck!",
		"ErfÃ¼lle deine Bestimmung, Mensch, rette unser Universum!",
		"Auf dass sich Shamus TÃ¼ren dir Ã¶ffnen, mein Freund!",
	];

	//////////////
	/// GOSSIP ///
	//////////////

	public static var GOSSIP_CRYSTAL = "Als ich neulich einen gewÃ¶hnlichen Routineflug durch den Hyperraum gemacht habe sind mir ein paar  seltsame rosane Lichter in ::coord:: aufgefallen. Das ist bei dieser Geschwindigkeit nicht normal. Dort muss es irgend etwas interessantes geben.";


	public static var GOSSIP_NOYAUX_0 = [
		"Eine vollstÃ¤ndige Iron-Cricket-Mannschaft",
		"Die Weltraumkapsel meines Onkels",
		"Eine Flotte balixtinischer Raumschiffer",
		"Eine Staffel von 4 Gefangenenraumschiffen der ESCorp",
		"Eine galaktischer Wal, der geschÃ¤tzte 650 Tonnen wiegt",
	];

	public static var GOSSIP_NOYAUX_1 = "wurde auf mysteriÃ¶se Weise von einem schwarzen Punkt im Weltall aufgesagt. Die Einsatzbrigade meines Dorfes hat eine ganze Woche damit verbracht, den Sektor ::coord:: zu durchpflÃ¼gen, aber sie haben nichts gefunden.";

	public static var GOSSIP_TABLET = "Ich habe die Explosion auf Karbonis Ã¼berlebt, aber meine ganze Familie ist dort umgekommen. Die letzten Ãberbleibsel unserer Zivilisation schweben inzwischen im Weltraum umher... *schnief*. Als ich neulich den AsteroidengÃ¼rtel untersuchte, habe ich eine Karbonit-Tafel in ::coord:: gefunden. Ich konnte sie nicht mitnehmen, da sie viel zu schwer war!";

	public static var GOSSIP_ASPHALT = "Es heiÃt, dass die ESCorp im Stuklie-System an einer extrem mÃ¤chtigen Bohrkugel arbeiten wÃ¼rde. Das Stuklie-System befindet sich im Ã¤uÃersten SÃ¼dosten, jenseits unseres Systems.\nIhre Forschungsergebnisse mÃ¼ssten hier bald ankommen.";

	public static var GOSSIP_DEFAULT = [
			"Von der FURI wurden mehrere Weltraumdemonstrationen organisiert. Letztes Jahr hat ein Delegation aus Ã¼ber 350 FURI-ReprÃ¤sentanten es sogar geschafft, eine Audienz beim PrÃ¤sidenten der KonfÃ¶deration der Menschen zu bekommen.",
			"Ich werde meine karbonischen Freunde nie wiedersehen. Lasst mich in Ruhe. Ihr anderen Menschen seid nicht imstande, einzuschÃ¤tzen, was wirklich wichtig ist im Leben.",
			"Die Nebelschwaden sind derart grell, dass sie die Piloten oft bei der Navigation stÃ¶ren. Wir, die anderen Piloten, haben glÃ¼cklicherweise immer eine Sonnenbrille.",
			"Ich hasse Kompott.",
			"Es gibt ein Universum mit ziemlich mÃ¤chtigen, halluzinogenen Ansammlungssteinen. Diese Steine kÃ¶nnen deinen Orientierungssinn komplett durcheinanderbringen.",
			"Meine Ferien auf Samosa letztes Jahr waren der totale Reinfall. Wir haben in der ganzen Woche nicht einen Tag Sonne gehabt!",
			"Den Roboterhasen ist es bisher noch nicht gelungen in unser System einzudringen. Ich denke wir sollten uns alle etwas weniger Ã¼ber ESCorps Anwesenheit hier beschweren. Seitdem die Menschen hier sind, hat es keinen einzigen Krieg mehr gegeben!",
			"Meine GroÃmutter wurde mit 28 Jahren von einer Roboterhasen-Patrouille entfÃ¼hrt. Wir haben sie seitdem nie wieder gesehen... Es fÃ¤llt mir schwer es auszusprechen, aber ich muss anerkennen, dass ESCorps Anwesehenheit erheblich dazu beigetragen hat unser System zu sichern.",
			];

	public static var GOSSIP_MISSILE_0 = "Als ich in der Gegend um Sektor ::coord:: herumbummelte, ist mir ein zerfleddertes Raketenwrack aufgefallen.\n";
	public static var GOSSIP_MISSILE_1 = [
		"Das Weltall ist zu einer wahren MÃ¼lltonne verkommen.",
		"Die jungen Leute scheren sich wirklich um nichts mehr...",
		"Ich hoffe, dass die Weltraum-MÃ¼llmÃ¤nner das Wrack beseitigt haben.",
		"Ich habe mich ihm nicht genÃ¤hert, da ich Angst hatte, dass es explodiert.",
		"Es war in einem erbÃ¤rmlichen Zustand.",
	];
}
