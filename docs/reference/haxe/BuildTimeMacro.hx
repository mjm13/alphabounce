class BuildTimeMacro {
	public static macro function getBuildTime() {
		var buildTime = Math.floor(Date.now().getTime() / 1000);

		return macro $v{buildTime};
	}
}
