#export fp_run_tests

/// @desc Runs the fixpath self-tests and reports a summary to the debug output.
/// @return {Boolean} Whether every assertion passed.
function fp_run_tests()
{
	global.__fp_test_report = { checks: 0, failures: 0 };

	__fp_test_is_valid();
	__fp_test_path();
	__fp_test_is_absolute();
	__fp_test_datafiles_path();
	__fp_test_join_path();
	__fp_test_save_area_path();
	__fp_test_buffer_save_path();
	__fp_test_sync_path();
	__fp_test_resolve_path();
	__fp_test_url_is_valid();
	__fp_test_url();

	var _report = global.__fp_test_report;
	show_debug_message($"fixpath tests: {_report.checks - _report.failures}/{_report.checks} passed.");

	return _report.failures == 0;
}

/// @ignore
/// @desc Asserts that two values are equal.
/// @param {Any} actual The value produced by the library.
/// @param {Any} expected The value the contract requires.
/// @param {String} message Describes the case under test.
function __fp_test_assert_equal(_actual, _expected, _message)
{
	global.__fp_test_report.checks++;

	if (_actual == _expected) return;

	global.__fp_test_report.failures++;
	show_debug_message($"FAIL {_message}: expected <{_expected}>, got <{_actual}>.");
}

/// @ignore
/// @desc Asserts that a value is undefined.
/// @param {Any} actual The value produced by the library.
/// @param {String} message Describes the case under test.
function __fp_test_assert_undefined(_actual, _message)
{
	global.__fp_test_report.checks++;

	if (is_undefined(_actual) ) return;

	global.__fp_test_report.failures++;
	show_debug_message($"FAIL {_message}: expected <undefined>, got <{_actual}>.");
}

/// @ignore
/// @desc Covers fp_is_valid().
function __fp_test_is_valid()
{
	__fp_test_assert_equal(fp_is_valid("sprites/a.png", "test"), true, "fp_is_valid: accepts a path");
	__fp_test_assert_equal(fp_is_valid(noone, "test"), false, "fp_is_valid: rejects a non-string");
	__fp_test_assert_equal(fp_is_valid("   ", "test"), false, "fp_is_valid: rejects whitespace only");
}

/// @ignore
/// @desc Covers fp_path().
function __fp_test_path()
{
	__fp_test_assert_undefined(fp_path(undefined), "fp_path: undefined input");
	__fp_test_assert_undefined(fp_path("   "), "fp_path: empty input");
	__fp_test_assert_equal(fp_path("  sprites\\a.png  "), "sprites/a.png", "fp_path: trims and normalizes separators");
	__fp_test_assert_equal(fp_path("C:\\Game\\a.png"), "C:/Game/a.png", "fp_path: keeps absolute paths");
}

/// @ignore
/// @desc Covers fp_is_absolute().
function __fp_test_is_absolute()
{
	__fp_test_assert_equal(fp_is_absolute("/nowhere/a.dat"), true, "fp_is_absolute: a leading separator is absolute");
	__fp_test_assert_equal(fp_is_absolute("sprites/a.png"), false, "fp_is_absolute: a relative path is not absolute");
	__fp_test_assert_equal(fp_is_absolute(noone), false, "fp_is_absolute: an invalid path is not absolute");

	if (os_type == os_windows)
	{
		__fp_test_assert_equal(fp_is_absolute("C:\\Game\\a.dat"), true, "fp_is_absolute: a drive letter is absolute");
	}
}

/// @ignore
/// @desc Covers fp_datafiles_path().
function __fp_test_datafiles_path()
{
	__fp_test_assert_undefined(fp_datafiles_path(noone), "fp_datafiles_path: non-string input");
	__fp_test_assert_undefined(fp_datafiles_path("  "), "fp_datafiles_path: empty input");

	var _area_root = (GM_is_sandboxed) ?
		string(working_directory) :
		filename_path(GM_project_filename) + "datafiles";

	__fp_test_assert_equal(
		fp_datafiles_path("sprites\\a.png"),
		__fp_join(_area_root, "sprites/a.png"),
		"fp_datafiles_path: resolves the datafiles root"
	);
}

/// @ignore
/// @desc Covers fp_join_path().
function __fp_test_join_path()
{
	__fp_test_assert_undefined(fp_join_path(noone, "a.dat"), "fp_join_path: invalid directory");
	__fp_test_assert_undefined(fp_join_path("/nowhere", "   "), "fp_join_path: invalid relative path");

	__fp_test_assert_equal(
		fp_join_path("C:\\Game\\data", "slot.dat"),
		"C:/Game/data/slot.dat",
		"fp_join_path: normalizes separators"
	);
	__fp_test_assert_equal(
		fp_join_path("C:/Game/data/", "slot.dat"),
		"C:/Game/data/slot.dat",
		"fp_join_path: does not duplicate the separator"
	);
}

/// @ignore
/// @desc Covers fp_save_area_path().
function __fp_test_save_area_path()
{
	__fp_test_assert_undefined(fp_save_area_path(undefined), "fp_save_area_path: undefined input");
	__fp_test_assert_undefined(fp_save_area_path(noone), "fp_save_area_path: non-string input");
	__fp_test_assert_undefined(fp_save_area_path("   "), "fp_save_area_path: empty input");

	__fp_test_assert_equal(
		fp_save_area_path("/nowhere/a.dat"),
		"/nowhere/a.dat",
		"fp_save_area_path: a leading separator is absolute"
	);

	if (os_type == os_windows)
	{
		__fp_test_assert_equal(
			fp_save_area_path("C:\\Game\\a.dat"),
			"C:/Game/a.dat",
			"fp_save_area_path: a drive letter is absolute"
		);
	}

	var _save_area = string(game_save_id);
	if (string_length(_save_area) <= 0)
	{
		show_debug_message("fixpath tests: game_save_id is empty, skipping the anchoring cases.");
		return;
	}

	var _anchored = __fp_join(_save_area, "profile/data.dat");

	__fp_test_assert_equal(
		fp_save_area_path("profile\\data.dat"),
		_anchored,
		"fp_save_area_path: anchors a relative path in the save area"
	);
	// Feeding an anchored path back must be a no-op, otherwise callers cannot compose the helper.
	__fp_test_assert_equal(
		fp_save_area_path(_anchored),
		fp_path(_anchored),
		"fp_save_area_path: is idempotent"
	);

	if (GM_is_sandboxed)
	{
		__fp_test_assert_equal(
			fp_resolve_path(_anchored),
			"profile/data.dat",
			"fp_resolve_path: undoes the save area anchor"
		);
	}
}

/// @ignore
/// @desc Covers fp_buffer_save_path().
function __fp_test_buffer_save_path()
{
	__fp_test_assert_undefined(fp_buffer_save_path(undefined), "fp_buffer_save_path: undefined input");
	__fp_test_assert_undefined(fp_buffer_save_path(noone), "fp_buffer_save_path: non-string input");
	__fp_test_assert_undefined(fp_buffer_save_path("   "), "fp_buffer_save_path: empty input");

	__fp_test_assert_equal(
		fp_buffer_save_path("/nowhere/a.dat"),
		"/nowhere/a.dat",
		"fp_buffer_save_path: a leading separator is absolute"
	);

	if (os_type == os_windows)
	{
		__fp_test_assert_equal(
			fp_buffer_save_path("C:\\Game\\a.dat"),
			"C:/Game/a.dat",
			"fp_buffer_save_path: a drive letter is absolute"
		);
	}

	var _save_area = string(game_save_id);
	if (string_length(_save_area) <= 0)
	{
		show_debug_message("fixpath tests: game_save_id is empty, skipping the buffer cases.");
		return;
	}

	// buffer_save_async() places the file under "default/", so the sync functions need that segment.
	var _buffered = __fp_join(__fp_join(_save_area, "default"), "profile/data.dat");

	__fp_test_assert_equal(
		fp_buffer_save_path("profile\\data.dat"),
		_buffered,
		"fp_buffer_save_path: anchors a relative path under default/"
	);
	__fp_test_assert_equal(
		fp_buffer_save_path(_buffered),
		fp_path(_buffered),
		"fp_buffer_save_path: is idempotent"
	);

	if (GM_is_sandboxed)
	{
		// fp_resolve_path() strips only the save area root, so the buffer folder survives.
		__fp_test_assert_equal(
			fp_resolve_path(_buffered),
			"default/profile/data.dat",
			"fp_resolve_path: keeps the default/ folder of an async buffer"
		);
	}
}

/// @ignore
/// @desc Covers fp_sync_path().
function __fp_test_sync_path()
{
	__fp_test_assert_undefined(fp_sync_path(undefined), "fp_sync_path: undefined input");
	__fp_test_assert_undefined(fp_sync_path(noone), "fp_sync_path: non-string input");
	__fp_test_assert_undefined(fp_sync_path("   "), "fp_sync_path: empty input");

	__fp_test_assert_equal(
		fp_sync_path("/nowhere/a.dat"),
		"/nowhere/a.dat",
		"fp_sync_path: an absolute path is left alone"
	);

	var _save_area = string(game_save_id);
	var _absolute = (string_length(_save_area) <= 0) ?
		"default/profile/data.dat" :
		__fp_join(_save_area, "default/profile/data.dat");

	__fp_test_assert_equal(
		fp_sync_path("profile\\data.dat"),
		(GM_is_sandboxed) ? "default/profile/data.dat" : _absolute,
		"fp_sync_path: follows the target's sandbox rule"
	);

	var _sync = fp_sync_path("profile\\data.dat");

	__fp_test_assert_equal(
		fp_sync_path("default/profile/data.dat"),
		_sync,
		"fp_sync_path: does not duplicate the default/ folder"
	);
	__fp_test_assert_equal(
		fp_sync_path(fp_buffer_save_path("profile\\data.dat") ),
		_sync,
		"fp_sync_path: accepts the absolute buffer path"
	);
	__fp_test_assert_equal(
		fp_sync_path(fp_resolve_path("profile\\data.dat") ),
		_sync,
		"fp_sync_path: composing fp_resolve_path changes nothing"
	);
	__fp_test_assert_equal(
		fp_sync_path(_sync),
		_sync,
		"fp_sync_path: is idempotent"
	);
}

/// @ignore
/// @desc Covers fp_resolve_path() on the current target.
function __fp_test_resolve_path()
{
	__fp_test_assert_undefined(fp_resolve_path(undefined), "fp_resolve_path: undefined input");
	__fp_test_assert_undefined(fp_resolve_path(noone), "fp_resolve_path: non-string input");
	__fp_test_assert_undefined(fp_resolve_path("   "), "fp_resolve_path: empty input");
	__fp_test_assert_equal(fp_resolve_path("  sprites\\a.png  "), "sprites/a.png", "fp_resolve_path: relative path");

	if (!GM_is_sandboxed)
	{
		__fp_test_assert_equal(
			fp_resolve_path("C:\\Game\\a.png"),
			"C:/Game/a.png",
			"fp_resolve_path: absolute path outside the sandbox"
		);
		return;
	}

	var _areas = [game_save_id, working_directory];
	var _names = ["game_save_id", "working_directory"];

	for (var i = 0; i < array_length(_areas); i++)
	{
		var _area = string(_areas[i]);
		var _name = _names[i];
		if (string_length(_area) <= 0)
		{
			show_debug_message($"fixpath tests: {_name} is empty, skipping its cases.");
			continue;
		}

		var _absolute = __fp_join(_area, "sprites/a.png");
		// Uppercase only the root so the case-insensitive match is proven without touching the remainder.
		var _upper_root = string_upper(_area) + string_delete(_absolute, 1, string_length(_area) );

		__fp_test_assert_equal(fp_resolve_path(_absolute), "sprites/a.png", $"fp_resolve_path: path inside {_name}");
		__fp_test_assert_equal(
			fp_resolve_path(_upper_root),
			"sprites/a.png",
			$"fp_resolve_path: {_name} matches case-insensitively"
		);
		__fp_test_assert_equal(fp_resolve_path(_area), fp_path(_area), $"fp_resolve_path: bare {_name} stays absolute");
	}

	__fp_test_assert_equal(
		fp_resolve_path("Z:/fixpath_outside/a.png"),
		"Z:/fixpath_outside/a.png",
		"fp_resolve_path: path outside both areas"
	);
}

/// @ignore
/// @desc Covers fp_url_is_valid().
function __fp_test_url_is_valid()
{
	__fp_test_assert_equal(fp_url_is_valid("https://example.com/a", "test"), true, "fp_url_is_valid: accepts https");
	__fp_test_assert_equal(fp_url_is_valid("http://example.com", "test"), true, "fp_url_is_valid: accepts http");
	__fp_test_assert_equal(fp_url_is_valid(noone, "test"), false, "fp_url_is_valid: rejects a non-string");
	__fp_test_assert_equal(
		fp_url_is_valid("ftp://example.com", "test"),
		false,
		"fp_url_is_valid: rejects a non-HTTP scheme"
	);
	__fp_test_assert_equal(fp_url_is_valid("https://", "test"), false, "fp_url_is_valid: rejects a missing host");
	__fp_test_assert_equal(
		fp_url_is_valid("https://example.com/a b", "test"),
		false,
		"fp_url_is_valid: rejects whitespace"
	);
}

/// @ignore
/// @desc Covers fp_url().
function __fp_test_url()
{
	__fp_test_assert_equal(
		fp_url("  HTTPS://example.com\\api?m=1#s  "),
		"https://example.com/api?m=1#s",
		"fp_url: trims, normalizes separators and lowercases the scheme"
	);
	__fp_test_assert_undefined(fp_url("ftp://example.com"), "fp_url: invalid URL");
}
