import js.Browser;
import js.lib.Promise;
import js.html.LIElement;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import js.Browser.document;
import js.Browser.location;
import js.html.ImageElement;
import mt.bumdum.Lib;
import Protocol;

using Lambda;

class Web {
	static public function initCurrentPage() {
		if (location.pathname.contains("user")) {
			initUserPage();
		} else {
			initMissionsPage();
		}

		checkTasks();
		bindMenu();
	}

	@:jsasync static private function loadSection(section:String, li:LIElement) {
		// Mark other links as inactive
		var menu = document.querySelector("#menu");
		var active = menu.querySelector("li.active");
		if (active != null)
			active.classList.remove("active");

		li.classList.add("active");

		var content = document.getElementById("section");
		content.className = "";
		content.innerHTML = "";

		if (section == "missions") {
			initMissionsPage();
		} else if (section == "leaderboard") {
			initRanking();
		}
	}

	static private function initRanking() {
		var content = document.getElementById("section");
		content.classList.add("ranking");
		content.innerHTML = "<h2>Chargement du classement...</h2><h3></h3>";
		loadRanking().then((r:Dynamic) -> {
			if (r.error != null) {
				content.querySelector("h2").innerText = "Erreur lors du chargement du classement";
			} else {
				var ranking:Array<PlayerRanking> = r;
				content.querySelector("h2").innerText = "Classement des mineurs";
				content.querySelector("h3").innerText = "Mis à jour toutes les 3 minutes";
				var ol = document.createOListElement();
				ol.classList.add("ranking");
				for (i in 0...ranking.length) {
					var li = document.createLIElement();
					var player = ranking[i];
					li.innerHTML = '<strong>${i + 1}</strong><span class="nick">${player.nick.htmlEscape()}</span><span class="explo">${player.exploration}</span>';
					ol.append(li);
				}
				content.append(ol);
			}
		});
	}

	static private function loadRanking():js.lib.Promise<Dynamic> {
		return new Promise((res, rej) -> {
			Browser.window.fetch("/api/leaderboard").then((r) -> {
				r.json().then(res);
			});
		});
	}

	static private function bindMenu() {
		var menu = document.querySelector("#menu");
		menu.querySelector("li.leaderboard").addEventListener('click', loadSection.bind("leaderboard", cast menu.querySelector("li.leaderboard")));
		menu.querySelector("li.missions-link").addEventListener('click', loadSection.bind("missions", cast menu.querySelector("li.missions-link")));
	}

	static private function initMissionsPage() {
		var content = document.getElementById("section");
		content.innerHTML = '
		<div id="currentMissionsTab">
			<div id="currentMissions">{{missions}}</div>
			<a onClick="Alphabounce.showTab(\'missionsHistoryTab\')" class="button">Historique</a>
		</div>
		<div id="missionsHistoryTab" style="display: none">
			<div id="finishedMissions">{{finishedMissions}}</div>
			<a onClick="Alphabounce.showTab(\'currentMissionsTab\')" class="button">Missions en cours</a>
		</div>';

		createMissionList();
	}

	static private function initUserPage() {
		var playerInfo = Cs.pi;

		var userRank = document.getElementById("userRank");
		userRank.setAttribute('tooltipContent', getUserRankTooltip(playerInfo.rank, playerInfo.faction));

		var imgRank = cast(document.getElementById("userRankImg"), ImageElement);
		var imgPrefix = playerInfo.faction == 1 ? "img/icons/rank_" : "img/icons/furi_rank_";
		imgRank.src = imgPrefix + playerInfo.getPlayerRank() + ".gif";

		var coordinates = document.getElementById("userCoords");
		coordinates.innerHTML = "[" + playerInfo.x + "][" + playerInfo.y + "]";

		var plays = document.getElementById("userPlays");
		plays.innerHTML = Std.string(playerInfo.plays);
	}

	static public function checkTasks() {
		// checks mission popups
		if (Cs.pi.tasks.length > 0)
			createMissionEndNotification(Cs.pi.tasks.pop());
	}

	static private function createMissionEndNotification(data:_LogData) {
		document.getElementById("inner").innerHTML = createMissionHtml(data);
		document.getElementById("pop").style.display = "block";
	}

	static private function createMissionList() {
		var currentMissionsList:Array<_LogData> = [];
		var missionLogsList:Array<_LogData> = [];
		var pi = Cs.pi;

		// compile currentMissionsList with data
		for (i in 0...MissionInfo.LIST.length)
			if (pi.missions[i].status == 0 && MissionInfo.LIST[i].desc != null) {
				var m:_LogData = {
					_id: i,
					_status: 0,
					_timestamp: pi.missions[i].timestamp,
				}
				currentMissionsList.push(m);
			}
		for (p in pi.travel) {
			var m:_LogData = {
				_id: 1002,
				_status: 0,
				_timestamp: p._timestamp,
				_data: ["tname" => p._name, "x" => Std.string(p._ex), "y" => Std.string(p._ey),],
			};
			currentMissionsList.push(m);
		}
		// compile missionLogs with data
		for (i in 0...pi.missionLog.length) {
			var m:_LogData = {
				_id: pi.missionLog[i]._id,
				_status: pi.missionLog[i]._status,
				_timestamp: pi.missionLog[i]._timestamp,
				_data: pi.missionLog[i]._data,
			}
			missionLogsList.push(m);
		}

		if (currentMissionsList.length > 1)
			currentMissionsList.sort((a, b) -> Std.int(b._timestamp - a._timestamp));
		if (missionLogsList.length > 1)
			missionLogsList.sort((a, b) -> b._timestamp == a._timestamp ? a._status - b._status : Std.int(b._timestamp - a._timestamp));

		// add level mission at the top
		var currentMissionsString = "";
		if (pi.levelMission != null) {
			var m:_LogData = {
				_id: pi.faction == 1 ? 1000 : 1001,
				_status: 0,
				_timestamp: pi.levelMission.timestamp,
				_data: [
					"reward" => Std.string(pi.faction == 1 ? (pi.levelMission.size * pi.levelMission.size * 10) : 75),
					"xmin" => Std.string(pi.levelMission.x),
					"ymin" => Std.string(pi.levelMission.y),
				],
			};
			if (pi.faction == 1) {
				m._data.set("xmax", Std.string(pi.levelMission.x + pi.levelMission.size - 1));
				m._data.set("ymax", Std.string(pi.levelMission.y + pi.levelMission.size - 1));
			}
			currentMissionsString += createMissionHtml(m);
		}
		for (m in currentMissionsList)
			currentMissionsString += createMissionHtml(m);

		var missionsLogString = "";
		for (m in missionLogsList)
			missionsLogString += createMissionHtml(m);

		document.getElementById("currentMissions").innerHTML = currentMissionsString;
		document.getElementById("finishedMissions").innerHTML = missionsLogString;
	}

	static private function createMissionHtml(data:_LogData) {
		var name = Texts.texts.get('mission_name_${data._id}');
		var date = DateTools.format(Date.fromTime(data._timestamp), Texts.texts.get("date_fmt"));
		var desc = Texts.texts.get(data._status == 1 ? 'mission_end_${data._id}' : 'mission_desc_${data._id}');
		desc = Str.searchAndReplace(desc, "::name::", Cs.pi.nick);
		if (data._data != null) {
			for (key in data._data.keys()) {
				desc = Str.searchAndReplace(desc, '::$key::', data._data.get(key));
			}
		}
		return
			'<div class="${data._status == 1 ? "KMissionEnd" : "KMissionStart"}"><div class="mission"><div class="date">$date</div><h3>$name</h3><div class="content"><div class="pic"><img src="/img/vigs/vig${data._id}.png" alt="Img"></div> $desc</div></div></div>';
	}

	static public function updateMinerals() {
		document.getElementById("mineral").innerHTML = Std.string(Cs.pi.minerai);
	}

	static private function getUserRankTooltip(completedMission:Int, faction:Int) {
		var isESCorp = faction == 1;
		var factionName = isESCorp ? 'ESCorp' : 'FURI';
		var tooltipString = '<strong>Mission ' + factionName + '</strong> ';
		tooltipString += completedMission;
		tooltipString += isESCorp ? '<em>Ce grade au sein de l\'ESCorp est déterminé en fonction du nombre de mission de nettoyage effectuées</em>' : '<em>Ce grade FURI est déterminé en fonction du nombre de prisonniers libérés</em>';
		return tooltipString;
	}
}
