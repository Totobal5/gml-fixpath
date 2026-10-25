#export fp_is_valid, fp_path, fp_datafiles_path, fp_resolve_path, fp_url_is_valid, fp_url

/// @desc Validates file path format without restricting valid desktop absolute paths.
/// @param {String} path The path to validate.
/// @param {String} operation The operation being performed.
/// @return {Boolean} Whether the path is valid.
function fp_is_valid(_path, _operation)
{
	if (!__fp_is_string(_path, _operation, "path") ) return false;

	var _trimmed = string_trim(_path);
	if (string_length(_trimmed) <= 0)
	{
		show_debug_message($"{_operation}: path cannot be empty.");
		return false;
	}

	return true;
}

/// @desc Returns a validated and normalized path for any file API.
/// Relative paths remain relative and are not resolved against a project directory.
/// @param {String} path A path to validate and normalize.
/// @return {String|Undefined} The validated and normalized path or undefined if the path is invalid.
function fp_path(_path)
{
	var _norm = __fp_normalize(_path, "fp_path");
	if (is_undefined(_norm) ) return undefined;

	if (GM_is_sandboxed ) { show_debug_message("fp_path() absolute paths may be inaccessible while the file system sandbox is enabled."); }

	return _norm;
};

/// @desc Returns a validated and normalized path for source-project datafiles. 
/// It resolves the path against the source project directory if the file system sandbox is disabled.
/// @param {String} path A path to validate and normalize.
/// @return {String|Undefined} The normalized path or undefined if the path is invalid.
function fp_datafiles_path(_path)
{
	var _norm = __fp_normalize(_path, "fp_datafiles_path");
	if (is_undefined(_norm) ) return undefined;

	return (GM_is_sandboxed) ?
		working_directory + _norm :
		filename_path(GM_project_filename) + "datafiles/" + _norm;
};

/// @desc Resolves a path into a form the file functions accept on the current target.
/// Sandboxed targets reject absolute paths, so a path inside the save area or the game bundle
/// is returned relative to that area. Validation and normalization match fp_path().
/// @param {String} path A path to resolve.
/// @return {String|Undefined} The usable path or undefined if the path is invalid.
function fp_resolve_path(_path)
{
	static __roots = [ __fp_root(game_save_id), __fp_root(working_directory) ];

	var _norm = __fp_normalize(_path, "fp_resolve_path");
	if (is_undefined(_norm) || !GM_is_sandboxed) return _norm;

	var _lower = string_lower(_norm);
	for (var i = 0; i < array_length(__roots); i++)
	{
		var _root = __roots[i];
		if (_root.length <= 0) continue;

		if (string_length(_norm) > _root.length && string_starts_with(_lower, _root.path) )
		{
			return string_delete(_norm, 1, _root.length);
		}
	}

	// Outside the bundle and the save area the sandbox has nothing usable to offer.
	return _norm;
};

/// @desc Returns whether a URL is a valid HTTP or HTTPS URL.
/// @param {String} url The URL to validate.
/// @param {String} operation The operation being performed.
/// @return {Boolean} Whether the URL is valid.
function fp_url_is_valid(_url, _operation)
{
	if (!__fp_is_string(_url, _operation, "URL") ) return false;

	var _normalized = __fp_to_slash(_url);
	var _lower = string_lower(_normalized);
	var _is_http = string_starts_with(_lower, "http://");
	var _is_https = string_starts_with(_lower, "https://");
	if (!_is_http && !_is_https)
	{
		show_debug_message($"{_operation}: URL must begin with 'http://' or 'https://'.");
		return false;
	}

	var _scheme_length = _is_https ? 8 : 7;
	if (string_length(_normalized) <= _scheme_length || string_char_at(_normalized, _scheme_length + 1) == "/")
	{
		show_debug_message($"{_operation}: URL must contain a host.");
		return false;
	}

	if (string_pos(" ", _normalized) > 0 || string_pos("\t", _normalized) > 0
		|| string_pos("\n", _normalized) > 0 || string_pos("\r", _normalized) > 0)
	{
		show_debug_message($"{_operation}: URL cannot contain whitespace.");
		return false;
	}

	return true;
}

/// @desc Returns a validated and normalized HTTP or HTTPS URL.
/// @param {String} url A URL to validate and normalize.
/// @return {String|Undefined} The validated and normalized URL or undefined if the URL is invalid.
function fp_url(_url)
{
	if (!fp_url_is_valid(_url, "fp_url") ) return undefined;
	var _normalized = __fp_to_slash(_url);
	var _scheme_end = string_pos("://", _normalized);
	if (_scheme_end <= 0) return _normalized;

	var _scheme = string_lower(string_copy(_normalized, 1, _scheme_end - 1));
	return _scheme + string_delete(_normalized, 1, _scheme_end - 1);
};

/// @ignore
/// @desc Rejects a value that is not a string, reporting the operation and the value name.
/// @param {Any} value The value to check.
/// @param {String} operation The operation being performed.
/// @param {String} label The value name used in the diagnostic.
/// @return {Boolean} Whether the value is a string.
function __fp_is_string(_value, _operation, _label)
{
	if (is_string(_value) ) return true;

	show_debug_message($"{_operation}: {_label} must be a string.");
	return false;
};

/// @ignore
/// @desc Trims a string and converts backslashes to forward slashes.
/// @param {String} value The string to normalize. Callers reject non-strings first.
/// @return {String} The trimmed string with forward slashes.
function __fp_to_slash(_value)
{
	return string_replace_all(string_trim(_value), "\\", "/");
};

/// @ignore
/// @desc Validates and normalizes a path behind the public path helpers.
/// @param {String} path A path to validate and normalize.
/// @param {String} operation The operation being performed.
/// @return {String|Undefined} The normalized path or undefined if the path is invalid.
function __fp_normalize(_path, _operation)
{
	if (!fp_is_valid(_path, _operation) ) return undefined;

	return __fp_to_slash(_path);
};

/// @ignore
/// @desc Builds the comparison root for one sandbox area, normalized once per process.
/// @param {String} area The save area or bundle directory reported by GameMaker.
/// @return {Struct} `path` holds the lowercase root ending in "/" and `length` its character count.
function __fp_root(_area)
{
	var _root = __fp_to_slash(string(_area));
	if (string_length(_root) > 0 && string_char_at(_root, string_length(_root) ) != "/") _root += "/";
	_root = string_lower(_root);

	return { path: _root, length: string_length(_root) };
};