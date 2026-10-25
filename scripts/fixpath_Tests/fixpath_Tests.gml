#export fp_run_tests

/// @desc Runs the fixpath self-tests and reports a summary to the debug output.
/// @return {Boolean} Whether every assertion passed.
function fp_run_tests()
{
	global.__fp_test_report = { checks: 0, failures: 0 };

	__fp_test_is_valid();
	__fp_test_path();
	__fp_test_datafiles_path();
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
/// @desc Joins an area root and a relative path with exactly one separator.
/// @param {String} area The save area or bundle directory.
/// @param {String} relative The relative path to append.
/// @return {String} The joined path.
function __fp_test_join(_area, _relative)
{
	if (string_length(_area) <= 0) return _relative;

	var _last = string_char_at(_area, string_length(_area) );
	if (_last == "/" || _last == "\\") return _area + _relative;

	return _area + "/" + _relative;
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
		__fp_test_join(_area_root, "sprites/a.png"),
		"fp_datafiles_path: resolves the datafiles root"
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

		var _absolute = __fp_test_join(_area, "sprites/a.png");
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
