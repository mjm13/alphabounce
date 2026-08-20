import haxe.Json;
import haxe.ds.StringMap;
import haxe.CallStack;
import Protocol;

class Api { // }
	#if prod
	static public var FL_DEBUG = false;
	#else
	static public var FL_DEBUG = true;
	#end

	static public var LATENCE = 0;
	static public var CACHE_GRID_MARGIN = 100;

	static var BASE = "_/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	static var key:String = null;
	static var knb:Int = 0;

	static public var onConfirm:Void->Void;

	// ------
	// ENVOIE
	// ------
	// Appelé au demarrage du jeu
	// Attend la reception de setInfos();
	static public function askInfos() {
		trace('API: askInfos');
		#if prod
		serverRequest(_AskInfos);
		#else
		var f2 = haxe.Timer.delay(function() {
			Api.setInfos();
		}, Std.random(LATENCE));
		#end
	}

	static public function increaseMineralCounter(x:Int) {
		trace('API: increaseMineralCounter ($x)');
		untyped js.App.addMineral(x);
	}

	// Appelé Lorsque le joueur se déplace dans une case situé dans sa zone d'action.
	// Attend la reception de confirmMove();
	static public function play(x:Int, y:Int) {
		trace('API: play ($x $y)');
		#if prod
		serverRequest(_Play(x, y), 1);
		#else
		// EMULATION PARTIE SERVEUR
		// VERIFIE SI UN LEVEL EDITE EXISTE
		var so:Dynamic = JSSharedObject.getLocal("baseNiveaux");
		var lvl = null;
		if (so.data.grid != null) {
			lvl = so.data.grid.get('${x + CACHE_GRID_MARGIN},${y + CACHE_GRID_MARGIN}');
		}
		haxe.Timer.delay(function() {
			Api.confirmMove(x, y, true, lvl);
		}, Std.random(LATENCE));
		#end

		untyped js.App.enterPlay();
	}

	/*
		// Appelé lorsque le joueur tente d'atterir sur une planète
		static public function playLander(x,y){
			#if prod
				// TODO
				//serverRequest(_PlayLander(x,y));
			#else
				// EMULATION PARTIE SERVEUR
				haxe.Timer.delay( function(){ Api.confirmLander(x,y,true); }, Std.random(LATENCE) )();
			#end
		}
	 */
	// Appelé lorsque le joueur finis sa partie.
	// Attend la reception de setInfos();
	// --> Adapater la partie 'émulation serveur'.
	static public function endGame(x:Int, y:Int, flVictory:Bool, min:Int, mis:Int, ?itemId:Int, ?shopItems:Array<Int>) {
		trace('API: endGame ($x $y $flVictory $min $mis $itemId $shopItems)');
		#if prod
		serverRequest(_EndGame(x, y, flVictory, min, mis, itemId, shopItems), true);
		#else
		// RAPPEL AUTO
		haxe.Timer.delay(function() {
			Api.setInfos();
		}, Std.random(LATENCE));
		// EMULATION DE LA PARTIE SERVEUR
		{
			// ADD RESSOURCES
			Cs.pi.minerai += min;
			Cs.pi.missile = mis;
			Cs.pi.addItem(itemId);

			// MOVE PLAYER
			if (flVictory) {
				Cs.pi.x = Game.me.level.wx;
				Cs.pi.y = Game.me.level.wy;
			}

			// CHECK MISSION
			Cs.pi.checkMission();

			// SHOPITEM DEPENSE
			if (shopItems != null) {
				for (id in shopItems)
					Cs.pi.shopItems[id] = 0;
			}
		}
		Cs.pi.saveCache();
		#end

		untyped js.App.endPlay();
	}

	//
	static public function playLander(x:Int, y:Int) {
		trace('API: play lander ($x $y)');
		#if prod
		serverRequest(_PlayLander(x, y), 1);
		#else
		#end

		trace('FIXME: fake lander');
		haxe.Timer.delay(function() {
			Api.confirmLander(true, 0, false);
		}, Std.random(LATENCE));
	}

	//
	static public function endLander(flVictory:Bool, min:Int, mis:Int, caps:Int, travel:_Travel, itemId:Int, flMarkHouse:Bool) {
		trace('API: end lander ($flVictory, $min, $mis, $caps, $itemId, $travel, $flMarkHouse)');
		#if prod
		serverRequest(_EndLander(flVictory, min, mis, caps, itemId, travel, flMarkHouse), true);
		#else
		haxe.Timer.delay(function() {
			Api.setInfos();
		}, Std.random(LATENCE));
		{
			// ADD RESSOURCES
			Cs.pi.minerai += min;
			Cs.pi.missile = mis;
			Cs.pi.addItem(itemId);
			if (travel != null)
				Cs.pi.travel.push(travel);
			// CHECK MISSION
			Cs.pi.checkMission();
		}
		Cs.pi.saveCache();
		#end

		trace('FIXME: fake end lander');
		haxe.Timer.delay(function() {
			Api.setInfos();
		}, Std.random(LATENCE));
	}

	// Appelé lorsque le joueur achète un objet en boutique.
	// Attend la reception de confirm();
	// !!! Les infos sont modifié en parrallele chez le Client + en BDD
	static public function buyItem(id:Int) {
		trace('API: Buy item ($id)');
		Manager.initWaitScreen();
		// CALCUL DOUBLE CLIENT + SERVEUR
		Cs.pi.buyShopItem(id);

		#if prod
		serverRequest(_BuyItem(id), true);
		#else
		var f2 = haxe.Timer.delay(function() {
			Api.confirm();
		}, Std.random(LATENCE));
		Cs.pi.saveCache();
		#end
	}

	// Appelé lorsque le joueur propose un niveau
	// Attend la reception de confirm();
	static public function submit(x:Int, y:Int, str:String) {
		Manager.initWaitScreen();
		trace('API: Submit ($x $y $str)');
		#if prod
		serverRequest(_SubmitLevel(str));
		#else
		// RAPPEL AUTO
		var f = function() {
			Api.confirm();
		};
		haxe.Timer.delay(f, Std.random(LATENCE));

		// EMULATION PARTIE SERVEUR
		var ma = CACHE_GRID_MARGIN;
		var so = JSSharedObject.getLocal("pendingLevels");
		if (so.data.grid == null) {
			so.data.grid = new StringMap();
			for (x in 0...ma * 2) {
				for (y in 0...ma * 2) {
					so.data.grid.set('${x},${y}', []);
				}
			}
		}
		so.data.grid.get('${x + ma},${y + ma}').push(str);
		so.data.flush();
		#end
	}

	// Appelé lorsque l'admin ou l'editeur veut afficher la liste des niveaux proposés pour une case précise. ( max 32 )
	// Attend la reception de Api.displayPendingLevels(a:Array<String>);
	static public function askPendingLevels(x:Int, y:Int) {
		trace('API: Select pending level ($x $y)');
		Manager.initWaitScreen();
		#if prod
		serverRequest(_AskPendingLevels(x, y));
		#else
		// RAPPEL AUTO
		var so = JSSharedObject.getLocal("pendingLevels");
		var a = so.data.grid.get('${x + CACHE_GRID_MARGIN},${y + CACHE_GRID_MARGIN}');
		var f = function() {
			Api.displayPendingLevels(a);
		};
		haxe.Timer.delay(f, Std.random(LATENCE));
		#end
	}

	// Appelé lorsque l'admin ou l'editeur valide un niveau.
	// Attend la reception de confirm();
	static public function selectPendingLevel(x:Int, y:Int, id:Int) {
		Manager.initWaitScreen();
		trace('API: Select pending level ($x $y $id)');
		#if prod
		serverRequest(_SelectPendingLevel(x, y, id));
		#else
		// EMULATION PARTIE SERVEUR
		var ma = CACHE_GRID_MARGIN;
		var so = JSSharedObject.getLocal("baseNiveaux");
		var so2 = JSSharedObject.getLocal("pendingLevels");
		if (so.data.grid == null) {
			so.data.grid = new StringMap();
		}

		var px = x + CACHE_GRID_MARGIN;
		var py = y + CACHE_GRID_MARGIN;

		var str = so2.data.grid.get('${px},${py}')[id];
		so2.data.grid.set('${px},${py}', []);
		so.data.grid.set('${px},${py}', str);
		so.flush();

		// RAPPEL AUTO
		var f = function() {
			Api.confirm();
		};
		haxe.Timer.delay(f, Std.random(LATENCE));
		#end
	}

	// Appelé lorsque l'admin ne veut aucun de nes niveaux proposé ( max 32 )
	// Attend la reception de confirm();
	static public function deletePendingLevels(x:Int, y:Int) {
		Manager.initWaitScreen();
		trace('API: Delete pending level ($x $y)');
		#if prod
		serverRequest(_DeletePendingLevels(x, y));
		#else
		// EMULATION PARTIE SERVEUR
		var ma = CACHE_GRID_MARGIN;
		var so = JSSharedObject.getLocal("pendingLevels");
		//
		so.data.grid.set('${x + CACHE_GRID_MARGIN},${y + CACHE_GRID_MARGIN}', []);
		// RAPPEL AUTO
		var f = function() {
			Api.confirm();
		};
		haxe.Timer.delay(f, Std.random(LATENCE));
		#end
	}

	// Appelé lorsque l'admin ou l'editeur veut détruire le niveau édité et revenir au niveau généré.
	// Attend la reception de confirm();
	static public function resetLevel(x:Int, y:Int) {
		Manager.initWaitScreen();
		trace('API: Reset level ($x $y)');
		#if prod
		serverRequest(_ResetLevel(x, y));
		#else
		// EMULATION PARTIE SERVEUR
		var ma = CACHE_GRID_MARGIN;
		var so = JSSharedObject.getLocal("baseNiveaux");
		var px = x + CACHE_GRID_MARGIN;
		var py = y + CACHE_GRID_MARGIN;
		so.data.grid.set('${px},${py}', null);
		so.flush();
		// RAPPEL AUTO
		var f = function() {
			Api.confirm();
		};
		haxe.Timer.delay(f, Std.random(LATENCE));
		#end
	}

	// Appelé lorsque le joueur se téléporte
	// Attend la reception de setInfos();
	// Le joueur est téléporté sur à la position du trou noir opposé défini dans ZoneInfo.holes
	// --> Adapater la partie 'émulation serveur'.
	static public function warp() {
		trace('API: Wrap');
		#if prod
		serverRequest(_Wrap);
		#else
		// RAPPEL AUTO
		var f2 = haxe.Timer.delay(function() {
			setInfos();
		}, Std.random(LATENCE));
		// EMULATION CODE SERVEUR
		for (a in ZoneInfo.holes) {
			var id = 0;
			for (p in a) {
				if (p[0] == Cs.pi.x && p[1] == Cs.pi.y) {
					var np = a[(id + 1) % 2];
					Cs.pi.x = np[0];
					Cs.pi.y = np[1];
					Cs.pi.saveCache();
					break;
				}
				id++;
			}
		}
		#end
	}

	static function serverRequest(sr:_ServerRequest, ?refreshInventory:Bool, ?attempts:Int) {
		if (attempts == null)
			attempts = 10;
		if (attempts <= 0) {
			Api.error("Communication ERROR");
			return;
		}
		var request = new haxe.Http("/play/intercom");
		var timer = new haxe.Timer(60000);
		timer.run = function() {
			timer.stop();
			serverRequest(sr, refreshInventory, --attempts);
		}
		request.onData = function(str:String) {
			timer.stop();
			try {
				var x = Xml.parse(str);
				var s = decode(x.firstElement().firstChild().nodeValue);
				var r:_ServerResponse = haxe.Unserializer.run(s);
				switch (r) {
					case _Confirm():
						Api.confirm();
						if (Cs.pi.checkMission()) Web.initCurrentPage();
					case _ConfirmMove(x, y, m, l):
						trace('Confirm move: $m $l');
						Api.confirmMove(x, y, m, l);
					case _ConfirmLander(hasMineral, capsType, visited):
						Api.confirmLander(hasMineral, capsType, visited);
					case _Error(e):
						Api.error(e);
					case _SetInfos(s, k, n):
						Api.setInfos(s);
						key = k;
						knb = n;
					case _PendingLevels(a):
						Api.displayPendingLevels(a);
				}
			} catch (e:Dynamic) {
				trace(str);
				trace(Std.string(e));
				trace(CallStack.exceptionStack().join("\n"));
				Api.error(Std.string(e));
			}
		}
		request.onError = function(str:String) {
			trace("request error : " + str);
			Api.error(str);
		}
		request.setParameter("knb", Std.string(knb));
		request.setParameter("cmd", encode(haxe.Serializer.run(sr)));
		request.request(true);
	}

	// Appelé lorsque le joueur arrive sur terre.
	// Le choix 0 indique que le joueur reprend le jeu a zero en mode difficile
	// Le choix 1 indique que le joueur reste sur sa partie mais revient au point [0][0];
	// L'itemId est a ajouter a la liste d'objet. Si l'item ajouté est MissionInfo.EARTH_PASS il faut ajouter au joueur 1pt en moteur et 1pt en radar.
	// Attend la reception de setInfos();
	static public function endStory(choice:Int, itemId:Int) {
		serverRequest(_EndStory(choice, itemId));
	}

	// ---------
	// RECEPTION
	// ---------
	// Confirmation générale de reception des données
	// utilisé pour l'action buyItem, submit
	static public function confirm() {
		if (onConfirm != null)
			onConfirm();
		Manager.removeWaitScreen();
		Web.updateMinerals();
	}

	// Confirme le mouvement demandé par le client
	// flMinerai indique si le minerai de ce niveau est disponible
	// lvl peut redéfinir le level a afficher.
	static public function confirmMove(x, y, flMinerai:Bool, ?lvl:String) {
		navi.Map.me.confirmMove(x, y, flMinerai, lvl);
	}

	/*
		static public function confirmLander(x,y,flMinerai:Bool){
			navi.Map.me.confirmLander(x,y,flMinerai);
		}
	 */
	// Confirme la partie de lander.
	// flMinerai indique si le minerai de ce niveau est disponible
	// capsType indique le type de capsule utilisé 0-liquide 1-solide.
	static public function confirmLander(flMinerai:Bool, capsType:Int, flHouseVisited:Bool) {
		navi.Map.me.confirmLander(flMinerai, capsType, flHouseVisited);
	}

	/*
		static public function confirmLander(x,y,flMinerai:Bool){
			navi.Map.me.confirmLander(x,y,flMinerai);
		}
	 */
	// Envoie la liste des niveaux en attente.
	static public function displayPendingLevels(a) {
		Manager.removeWaitScreen();
		navi.Map.me.onReceiveLevels(a);
	}

	// Affiche une erreur
	static public function error(str) {
		// trace("ERROR: "+str);
		if (Game.me != null) {
			Game.me.kill();
		}
		navi.Map.me.error(str);

		// Game.me.error(str);
	}

	// Mets les infos du joueur a jour dans le client puis lance la map.

	static public function setInfos(?str) {
		navi.Map.me.setInfos(str);
		Web.updateMinerals();
	}

	static function encode(str:String) {
		// if (key == null)
		return str;
		// str = haxe.BaseCode.encode(str, BASE);
		// return new Codec(key).encode(str);
	}

	static function decode(str:String) {
		// if (key == null)
		return str;
		/*str = new Codec(key).decode(str);
			return haxe.BaseCode.decode(str, BASE); */
	}

	static function init():Bool {
		key = null;
		/*var k = Reflect.field(flash.Lib._root, "k");
			if (k != null && k != "null")
				key = k;
			var n = Reflect.field(flash.Lib._root, "n");
			if (n != null && n != "null")
				knb = Std.parseInt(n); */
		return true;
	}

	static var _init_ = init();
	// {
}
