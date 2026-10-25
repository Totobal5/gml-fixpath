# fixpath

`fixpath` is a GameMaker library for validating and normalizing file paths in pure GML.

The library only returns path strings. It does not open, read, write, or interpret files. It does not disable the GameMaker sandbox or bypass operating-system permissions.

## Generic path normalization

Use `fp_path()` when you need a normalized path for any file API. It trims surrounding whitespace and converts backslashes to forward slashes.

The function does not resolve the path against the project directory, `working_directory`, the bundle, or the save area.

```gml
var _relative_path = fp_path("  config\\settings.json  ");
// "config/settings.json"

var _absolute_path = fp_path("C:\\Game\\config.json");
// "C:/Game/config.json"
```

`fp_path()` returns the original value when validation fails and reports the reason with `show_debug_message()`.

When the sandbox is enabled, GameMaker can only access the file bundle and save area. `fp_path()` emits a sandbox diagnostic for every valid path and still returns the normalized string.

## Datafiles paths

Use `fp_datafiles_path()` for a path relative to the root of the project's `datafiles/` directory. Do not include the `datafiles/` prefix in the input.

When sandboxed, the function resolves the path from `working_directory`, which provides access to the matching file in the game bundle. When the sandbox is disabled, it resolves from the directory containing `GM_project_filename`, allowing runtime hotload from the source project's `datafiles/` directory.

```gml
var _sprite_path = fp_datafiles_path("Sprites/Algo.png");
```

For this input, the returned path is conceptually:

```text
Sandbox enabled:  working_directory + "Sprites/Algo.png"
Sandbox disabled: filename_path(GM_project_filename) + "datafiles/Sprites/Algo.png"
```

Use paths without an initial slash, such as `Sprites/Algo.png`, so both modes form the same logical location without duplicate separators.

## Save area paths

`buffer_save_async()` does not write where the other file functions look. GameMaker resolves the same relative string differently depending on the API:

| API | A relative path resolves to |
| --- | --- |
| `buffer_save_async`, `buffer_load_async` | the save area, inside a `default/` folder |
| `file_exists`, `file_rename`, `file_find_first`, `file_text_*`, ... | the game bundle (sandbox on) or the executable's folder (sandbox off) |

So one relative string names two different files, and GameMaker rejects absolute paths while the sandbox is on. `fp_sync_path()` returns the string that makes the synchronous functions reach what `buffer_save_async()` wrote, for the current target:

```gml
var _relative = "profile.dat";
buffer_save_async(_buffer, _relative);      // writes save area/default/profile.dat
file_exists(fp_sync_path(_relative));       // true, same file
buffer_load_async(_buffer, _relative);      // load takes the path without default/
```

Its result depends on the target:

- sandbox on → `default/profile.dat`, a relative path the sandbox resolves inside the save area;
- sandbox off → the absolute path inside the save area.

The absolute forms are available on their own: `fp_buffer_save_path()` (save area + `default/`) and `fp_save_area_path()` (save area root, for files you create with the synchronous functions). Both normalize separators, and both return an absolute input unchanged.

`buffer_load_async()` is the exception: it takes the same relative path you passed to `buffer_save_async()`, without the `default/` part.

On desktop with the sandbox disabled, `buffer_save_async()` uses an absolute path as-is and does not add `default/`.

`fp_resolve_path()` does the opposite conversion (an absolute path inside the save area or the bundle becomes relative), so reach for it only when an API requires a sandbox-relative path.

## Resolved paths

Use `fp_resolve_path()` when the path may be absolute but still has to work on a sandboxed target. It validates and normalizes exactly like `fp_path()`.

With the sandbox disabled it returns the normalized path unchanged. With the sandbox enabled, an absolute path under the save area (`game_save_id`) or the game bundle (`working_directory`) is returned relative to that area, because sandboxed targets reject absolute paths. A path outside both areas is returned unchanged, since the sandbox cannot reach it either way.

```gml
var _settings_path = fp_resolve_path(game_save_id + "settings.json");
// "settings.json"
```

Like the other helpers, it returns `undefined` when validation fails and never touches the file system.

## URLs

Use `fp_url()` to validate and normalize an HTTP or HTTPS URL. It trims surrounding whitespace, converts backslashes to forward slashes, and converts the scheme to lowercase. The path, query, and fragment remain otherwise unchanged.

```gml
var _url = fp_url("  HTTPS://example.com\\api?mode=debug#status  ");
// "https://example.com/api?mode=debug#status"
```

URLs must begin with `http://` or `https://`, include a host, and contain no spaces, tabs, or line breaks. Invalid input is returned unchanged and reported with `show_debug_message()`.

## API

### `fp_path(path)`

Validates and normalizes a path without resolving its location.

### `fp_datafiles_path(path)`

Validates and resolves a path relative to `datafiles/`. In sandbox mode it points to the matching file in the bundle. With the sandbox disabled it points to the source-project file, enabling hotload.

### `fp_is_valid(path, operation)`

Returns whether a path is a valid local file path. The `operation` argument is used in diagnostic messages.

### `fp_is_absolute(path)`

Returns whether a path is absolute on the current target: a leading `/`, or a drive letter on Windows. Returns `false` for invalid input.

### `fp_join_path(directory, relative)`

Joins a directory and a relative path with exactly one separator, converting backslashes to forward slashes. Useful to rebuild a full path from `file_find_first()` results, which come back without their directory. Returns `undefined` if either input is invalid.

### `fp_sync_path(path)`

Returns what the synchronous file functions need to reach a file written by `buffer_save_async()`: a relative path under `default/` while the sandbox is on, the absolute save-area path when it is off. An absolute input is returned unchanged.

### `fp_save_area_path(path)`

Validates and normalizes a path, then anchors a relative path in the save area root (`game_save_id`). Absolute paths are returned unchanged. Returns `undefined` for invalid input.

### `fp_buffer_save_path(path)`

Validates and normalizes a path, then anchors a relative path in the save area's `default/` folder, where `buffer_save_async()` writes. Absolute paths are returned unchanged. Returns `undefined` for invalid input.

### `fp_resolve_path(path)`

Validates and normalizes a path, then returns it relative to the save area or the game bundle when the target is sandboxed. Returns `undefined` for invalid input.

### `fp_url(url)`

Validates and normalizes an HTTP or HTTPS URL by trimming it, converting `\\` to `/`, and changing its scheme to lowercase.

### `fp_url_is_valid(url, operation)`

Returns whether a URL has an HTTP(S) scheme, a host, and no whitespace. The `operation` argument is used in diagnostic messages.

## Scope and limitations

- The library does not check whether a file exists.
- The library does not create directories or files.
- The library does not read or parse text, JSON, binary data, or buffers.
- `fp_path()` normalizes a string; it does not establish whether that path is accessible on the current target.
- In sandbox mode, GameMaker only permits access to the file bundle and save area.
- `fp_datafiles_path()` uses the bundle in sandbox mode and the project source directory otherwise.
- `fp_resolve_path()` only rewrites the root of an absolute path inside the save area or the bundle; it does not make any other path reachable.
- `fp_save_area_path()` does not create the save area or check that the file exists; it only anchors a relative path.
- `fp_buffer_save_path()` mirrors the documented `default/` folder of `buffer_save_async()`; it does not check that the buffer was actually saved.
- `fp_sync_path()` follows the same documented layout; it does not check that the buffer was saved either.
- `fp_save_area_path()` and `fp_resolve_path()` are inverses only while the target is sandboxed.
- Access to an external source-project path still depends on the target's sandbox setting and OS permissions.
- URL helpers support only `http://` and `https://`; they validate and normalize strings but do not make network requests.

## License

[MIT License](LICENSE.txt)
