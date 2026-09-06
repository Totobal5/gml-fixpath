/// @desc Validates file path format without restricting valid desktop absolute paths.
/// @param {String} path The path to validate.
/// @param {String} operation The operation being performed.
/// @return {Boolean} Whether the path is valid.
function fp_is_valid(_path, _operation)
{
	if (!is_string(_path) )
	{
		show_debug_message($"{_operation}: path must be a string.");
		return false;
	}

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
/// @return {String} The validated and normalized path.
function fp_path(_path)
{
	if (!fp_is_valid(_path, "fp_path") ) return _path;

	var _norm = _path;
	switch (os_type)
	{
		default:
			_norm = string_trim(_path);
			_norm = string_replace_all(_norm, "\\", "/");
		break
	}
	if (GM_is_sandboxed ) { show_debug_message("fp_path: absolute paths may be inaccessible while the file system sandbox is enabled."); }

	return _norm;
};

/// @desc Returns a validated and normalized path for source-project datafiles. 
/// It resolves the path against the source project directory if the file system sandbox is disabled.
/// @param {String} path A path to validate and normalize.
/// @return {String} The normalized path.
function fp_datafiles_path(_path)
{
	if (!fp_is_valid(_path, "fp_datafiles_path") ) return _path;
	
	var _norm = _path;
	switch (os_type)
	{
		default:
			_norm = string_trim(_path);
			_norm = string_replace_all(_norm, "\\", "/");
		break
	}

	return (GM_is_sandboxed) ? 
		working_directory + _norm : 
		filename_path(GM_project_filename) + "datafiles/" + _norm;
};

/// @desc Returns whether a URL is a valid HTTP or HTTPS URL.
/// @param {String} url The URL to validate.
/// @param {String} operation The operation being performed.
/// @return {Boolean} Whether the URL is valid.
function fp_url_is_valid(_url, _operation)
{
	if (!is_string(_url)) 
	{
		show_debug_message($"{_operation}: URL must be a string.");
		return false;
	}

	var _trimmed = string_trim(_url);
	var _lower = string_lower(_trimmed);
	var _is_http = string_starts_with(_lower, "http://");
	var _is_https = string_starts_with(_lower, "https://");
	if (!_is_http && !_is_https)
	{
		show_debug_message($"{_operation}: URL must begin with 'http://' or 'https://'.");
		return false;
	}

	var _scheme_length = _is_https ? 8 : 7;
	if (string_length(_trimmed) <= _scheme_length || string_char_at(_trimmed, _scheme_length + 1) == "/")
	{
		show_debug_message($"{_operation}: URL must contain a host.");
		return false;
	}

	if (string_pos(" ", _trimmed) > 0 || string_pos("\t", _trimmed) > 0
		|| string_pos("\n", _trimmed) > 0 || string_pos("\r", _trimmed) > 0)
	{
		show_debug_message($"{_operation}: URL cannot contain whitespace.");
		return false;
	}

	return true;
}

/// @desc Returns a validated and normalized HTTP or HTTPS URL.
/// @param {String} url A URL to validate and normalize.
/// @return {String} The validated and normalized URL.
function fp_url(_url)
{
	if (!fp_url_is_valid(_url, "fp_url") ) return _url;
	var _normalized = string_replace_all(string_trim(_url), "\\", "/");
	var _scheme_end = string_pos("://", _normalized);
	if (_scheme_end <= 0) return _normalized;

	var _scheme = string_lower(string_copy(_normalized, 1, _scheme_end - 1));
	return _scheme + string_delete(_normalized, 1, _scheme_end - 1);
};