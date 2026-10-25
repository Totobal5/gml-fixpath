---
name: gml-code-conventions
description: 'Use when writing, reviewing, refactoring, formatting or naming GameMaker GML code in any project: script assets, objects, sprites, rooms, macros, enums, constructors, structs and fluent APIs. Encodes a consistent GML house style - tab indentation, Allman braces, mandatory semicolons, spaced nested parentheses, /// doc blocks with @desc/@param/@return/@ignore, identifier and asset naming (o_, sp_, r_), two-level struct regions, guard-clause validation, and module error/alert helpers.'
argument-hint: 'Describe the GML you need (script, constructor/struct, enum/macro, object event, or asset name)'
---

# GML house style

These rules are the default for new GML in any GameMaker project. The snippets borrow their shape from a tween library (Simple-Curves): copy the structure, not the names or the domain.

Two rules of precedence:

1. If the file you are editing already follows a different pattern, match the file. Consistency inside a module beats these defaults.
2. If two of these rules disagree, prefer the one that makes the call site easier to read.

## Non-negotiables

1. **Tabs for indentation**, one tab per nesting level. Never spaces.
2. **Allman braces**: `{` and `else` go on their own line.
3. **Every statement ends with `;`** - assignments, calls, `return`, `exit`, `break`, `continue`.
4. **Never write `))`**. Separate consecutive closing parentheses with a space: `foo(bar(x) )`.
5. **Every function, static, field, macro and enum gets a `///` doc block.** Internal members start with `/// @ignore`.
6. **Private members are prefixed `__`**; internal script functions are `__` + module prefix + snake_case.
7. **Public setters/actions are fluent and `return self`**, documented as `@return {Struct.X} this instance`.

## Layout and formatting

| Rule | Do | Avoid |
| --- | --- | --- |
| Indentation | one tab per level | 4 spaces |
| Braces | `{` on its own line | `if (x) {` |
| `else` | own line, aligned with `if` | `} else {` |
| Semicolons | on every statement | ASI-style omission |
| Space before `(` | `if (x)`, `for (var i = 0; ...)`, `repeat(n)`, `with (obj)` | `if(x)` |
| Space inside parens | none: `if (x)`, `foo(_a, _b)` | `if ( x )` |
| Nested parens | `) )` | `))` |
| Binary operators | ` + `, ` * `, ` == `, ` && ` | `a+b` |
| Commas | `foo(_a, _b)` | `foo(_a,_b)` |
| `switch` bodies | `break;` aligned with its `case` | `break;` indented into the body |
| One-line bodies | `if (!ok) return self;` | braces for a single short statement |
| Line length | aim <= 100, hard limit ~120 | long chains on one line |
| Blank lines | one between logical blocks | stacks of blank lines |

```gml
if (!time_source_exists(__clock) ) return self;

if (time_source_exists(__clock) )
{
	time_source_stop(__clock);
	return self;
}
else
{
	__scurve_error("Cannot stop a clock that does not exist.");
}

switch (__type)
{
	case SC_TYPE.TO:
		__SetToPhase(__is_reversed, false, 1);
	break;

	case SC_TYPE.PATROL:
		__SetPatrolPhase(SC_PATROL_MODE.GO, false, 1);
	break;
}
```

Braces may stay on one line only for a tiny if/else pair:

```gml
if (__destroy_on_finish) { Destroy(); } else { Stop(); }
```

### Breaking long calls and chains

Arguments go on their own lines, indented one tab, with `);` at the statement indentation. Fluent chains break **before** the dot.

```gml
AssertEqual(
	__scurve_strip_origin("cyou_tobalsea_scurves_1_1_0_Simple_Curves_Functions:43"),
	"Simple_Curves_Functions:43"
);

var _tween = new SCurve(SCURVE.EASE)
	.Target(self)
	.To(0.5, "x", 320, "image_alpha", 0)
	.Delay(0.1)
	.Play();
```

## Identifiers

| Kind | Pattern | Examples |
| --- | --- | --- |
| Script asset / file | `PascalCase` feature + concern | `Simple_Curves`, `Simple_Curves_Settings` |
| Constructor | `PascalCase` noun | `SCurve`, `SCMaster`, `__Property` |
| Public method / static | `PascalCase` verb or query | `Play`, `To`, `Patrol`, `Destroy`, `Delay`, `IsPlaying`, `GetProgress`, `HasTag`, `SetLogErrors`, `PauseAll` |
| Private method / static | `__` + `PascalCase` | `__Tick`, `__Apply`, `__Register`, `__HasValidTarget` |
| Struct / instance field | `__` + `lower_snake_case` | `__duration`, `__phase_time`, `__target_is_struct` |
| Local variable | `_` + `lower_snake_case` | `_ratio`, `_prop`, `_scurve`, `_time_state` |
| Parameter | `_` + `lower_snake_case` | `_duration`, `_is_reversed`, `_prop_hash` |
| Loop counter | `i`, then `j`, then `s` | `for (var i = ...)`, `for (var j = ...)` |
| Top-level script function | `snake_case`, verb first | `is_scurve` |
| Internal script function | `__` + module prefix + snake | `__scurve_alert`, `__scurve_strip_origin` |
| Macro | `SCREAMING_SNAKE` with module prefix | `SC_LOG_ERRORS`, `SC_MIN_DELTA_FPS`, `SC_LAUNCH_ON_FINISH` |
| Enum type | `SCREAMING_SNAKE` noun | `SCURVE`, `SC_TYPE`, `SC_PATROL_MODE` |
| Enum member | `SCREAMING_SNAKE` | `LINEAR`, `TO`, `PATROL`, `GO`, `WAIT`, `BACK` |
| Private Global | `global.__` + lower_snake | `global.__sc_test_runner` |
| Public Global | `global.` + lower_snake | `global.sc_test_runner` |
| Debug handle | `global.__name__` | `global.__scurve_master__` |

Rules that follow from the table:

- **No `camelCase` anywhere.** Methods are `PascalCase`, everything else is `snake_case`.
- Booleans read as a statement: `__is_reversed`, `__destroyed`, `__needs_init`, `__valid`; predicates are `IsX` / `HasX`.
- Setters are `SetX`, getters are `GetX`, actions are bare verbs (`Play`, `Stop`, `Pause`, `Resume`, `Destroy`, `Refresh`, `Reverse`), callback registration is `OnX` (`OnFinish`, `OnUpdate`, `OnDelay`).
- Abbreviate only established domain words (`_prop`, `_msg`, `_scurve`, `_tween`). Never invent new abbreviations.
- Every internal name carries the module prefix, so helpers from different modules never collide (`__scurve_alert`, `__x_alert`). Pick one short prefix per module and keep it for life.
- Sentinel values are explicit: `noone` for instances, `undefined` for optional callbacks, `-1` for "not registered" (documented in the field doc block).

## Doc comments

Every declaration is documented with `///` tags. Order is fixed: `@ignore`, then `@type`, then `@desc`, then `@param`, then `@return`.

```gml
/// @ignore
/// @type {Real}
/// @desc Runtime elapsed time for the current phase.
__phase_time = 0;

/// @desc Starts the animation.
/// @return {Struct.SCurve} this instance
static Play = function()
{
	...
}

/// @desc Sets the local time scale for this animation.
/// @param {Real} scale Speed multiplier (1=normal, 0.5=half, 2=double).
/// @return {Struct.SCurve} this instance
static TimeScale = function(_scale)
{
	...
}

/// @ignore
/// @desc Removes the prefab prefix from a trace origin.
///       "cyou_tobalsea_scurves_1_1_0_Simple_Curves_Functions:43" becomes "Simple_Curves_Functions:43".
/// @param {String} origin The raw trace origin.
/// @return {String} The origin, stripped when it carries the package prefix.
function __scurve_strip_origin(_origin)
{
	...
}
```

Conventions:

- `@desc` is a capitalized sentence ending in a period. Continuation lines use `///` plus seven spaces so the text stays aligned under `@desc `.
- `@param {Type} name Description.` - parameter name first, type in braces, description as a sentence. Document the logical name: the leading `_` marks the variable as a parameter, it is not part of the name.
- Optional parameters are written `[name=default]`: `@param {Bool} [is_reversed=true] Whether the animation should play in reverse.`
- `@return {Type} Description.` - omit only for constructors.
- `@ignore` is the first tag on anything not part of the public surface: internal functions, private fields, private statics, config macros.
- Enum members are documented with a plain `///` sentence when they need explanation (`/// Forward, wait and backward cycle.`), and with `/// @desc ...` when the member needs emphasis.
- Doc types use GameMaker vocabulary with capital initials: `Real`, `Bool`, `String`, `Struct`, `Method`, `Any`, `Id.Instance`, `Array<String>`, `Struct<Real, Struct.SCurve>`, `Enum.SCURVE`, `Real|Undefined`, `Id.Instance | Struct`. Never `number`, `float`, `boolean` or `integer`.
- Public methods always document the fluent return, even when the body can return early.

## Structs, constructors and fluent APIs

Constructors group members in two levels: `#region PRIVATE` (fields, callbacks, methods) and `#region PUBLIC` (fields, methods, state queries, getters). Constructor body code that is not a member declaration - registering, wiring - sits between the two, once every field it touches exists.

```gml
function Example(_duration) constructor
{
	#region PRIVATE

		#region FIELDS

		/// @ignore
		/// @type {Bool}
		/// @desc Flag indicating whether this instance has been destroyed.
		__destroyed = false;

		/// @ignore
		static __count = 0;

		/// @ignore
		/// @type {Real}
		/// @desc Total duration in seconds.
		__duration = _duration;

		#endregion

		#region CALLBACKS

		/// @ignore
		/// @desc Callback triggered when the animation finishes.
		__callback_finish = undefined;

		#endregion

	// Register once the instance is fully configured.
	Registry.__Register(self);

		#region METHODS

		/// @ignore
		/// @desc Main loop, executed every frame.
		static __Tick = function()
		{
			if (__destroyed) exit;
			...
		}

		#endregion

	#endregion

	#region PUBLIC

		#region FIELDS

		#endregion

		#region METHODS

		static Play = function()
		{
			...
			return self;
		}

		#endregion

		#region STATE QUERIES

		static IsPlaying = function()
		{
			...
		}

		#endregion

		#region GETTERS

		static GetType = function()
		{
			return __type;
		}

		#endregion

	#endregion
}
```

Rules:

- **Guard clause first** in every public method, then validation, then mutation. Never mutate before all arguments are validated.
- Failures are reported through the module error helper and then `return self`; never throw, never `show_error` inline outside the helper.
- Separate diagnostics from contract violations: `__x_alert(...)` for expected/ignorable situations, `__x_error(...)` for misuse that is fatal by default.
- Messages are interpolated with `$"..."` whenever they embed a value.
- Clamp at the boundary instead of validating-and-failing when a clamp is meaningful: `__time_scale = max(0, _scale);`.
- Callbacks are stored as `undefined` and invoked behind `if (is_callable(__callback_x) ) __callback_x();`.
- Iterate backwards when the loop removes elements: `for (var i = array_length(__list) - 1; i >= 0; i--) __list[i].Destroy();`.
- `Destroy()` is idempotent: return early when already destroyed, release resources, then null every reference (`noone`, `undefined`, `[]`).
- Use `is_undefined`, `is_real`, `is_string`, `is_struct`, `is_callable`, `is_instanceof` for type checks - not truthiness.
- Prefer an enum plus `switch` over string modes or boolean flags.
- Statics that hold data are `__lower_snake`; statics that hold functions are `__PascalCase` or `PascalCase`.

## Script file layout

1. `#export` lines for the public surface, one line per kind, comma separated.
2. Doc block and declaration for each function, public first.
3. In a settings/config asset: `#macro` definitions grouped by concern, each with an `/// @ignore` doc block and values aligned with tabs, then the enums.
4. Static initialization at the end of the script (`script_execute(SCMaster);` when the script defines a singleton).
5. Optional `if (debug_mode)` block that exposes handles for debugging last.

```gml
#export SCMaster, SCurve

/// @ignore [MAJOR.MINOR.PATCH]
#macro SC_VERSION	"1.1.0"

/// @ignore Crash the game on errors (true/false). If false, errors will be logged but the game will continue.
#macro SC_FATAL_ERRORS			true

/// @desc Animation type of an SCurve.
enum SC_TYPE
{
	/// No animation configured yet.
	NONE,
	/// Single transition to the end value.
	TO,
	/// @desc Forward, wait and backward cycle.
	PATROL
}
```

## Comments and regions

- `//` comments are complete, capitalized sentences ending in a period, and they explain **why** - never restate the code.

  ```gml
  // Swap-remove keeps unregistration O(1) instead of shifting the whole list.
  ```

- Place the comment directly above the code it justifies. Use a blank line before it when it heads a multi-step block.
- `#region` groups long declarations; `#endregion` always closes it, and a blank line separates the marker from the content. Region names are uppercase and may carry a qualifier: `#region FIELDS`, `#region PUBLIC API`, `#region ANIMATION (async)`. Structs use the two-level layout from the previous section: an outer `PRIVATE`/`PUBLIC` marker, with nested markers and the declarations they hold sharing one indentation level, one tab deeper than the outer marker. Long functions may add a local region (`#region DELAY HANDLING`). Every `#region` needs its matching `#endregion` - count them before moving on.
- Do not add a region to a short function; a blank line is enough.

## Assets

| Kind | Pattern | Example |
| --- | --- | --- |
| Project | display name with spaces, `.yyp` | `Simple Curves.yyp` |
| Script | `PascalCase_With_Underscores`, one `.gml` matching the asset name | `scripts/Simple_Curves_Settings/Simple_Curves_Settings.gml` |
| Object | `o_` + `snake_case` | `o_test_suite`, `objects/o_test_suite/Create_0.gml` |
| Sprite | `sp_` + `snake_case` | `sp_iamfade` |
| Room | `r_` + `snake_case` | `r_test` |
| Animation curve | `PascalCase_With_Underscores` | `Simple_Curves_Animation` |
| Note / doc asset | `PascalCase_With_Underscores` | `Simple_Curves_License`, `Simple_Curves_Readme` |
| Package id | `vendor.platform.name-version` | `cyou.tobalsea.scurves-1.1.0` |
| Exported package | `Owner.Asset-Version.yymps` | `Totobal.Simple-Curves.1.0.0.yymps` |

- Folder name, `.yy` file name and `.gml` file name are identical for scripts.
- Object event files keep the generated names (`Create_0.gml`, `Step_0.gml`, `KeyPress_32.gml`).
- Event scripts open with a `/// @desc` header, then guard clauses that `exit;` early, then the body.

```gml
/// @desc Pumps the asynchronous test cases.

if (variable_instance_exists(id, "__sc_dummy") && __sc_dummy) exit;
if (!variable_global_exists("__sc_test_runner") || is_undefined(global.__sc_test_runner) ) exit;

if (global.__sc_test_runner.IsRunning() ) global.__sc_test_runner.Update();
```

## Review checklist

- [ ] Tabs only; Allman braces; `else` on its own line.
- [ ] Every statement terminated with `;`.
- [ ] No `))` anywhere.
- [ ] Every declaration has a `///` doc block; internal members start with `@ignore`.
- [ ] `@param` / `@return` document the logical name (without the `_` prefix) and use GameMaker doc types.
- [ ] Methods are `PascalCase`, privates are `__`-prefixed, locals start with `_`, loop counters are `i` / `j`.
- [ ] Public setters and actions `return self`.
- [ ] Guards and validation run before any mutation; errors go through the module helper.
- [ ] `switch` cases have `break;` aligned with the `case`.
- [ ] Structs use `#region PRIVATE` / `#region PUBLIC` with nested `FIELDS`, `CALLBACKS`, `METHODS`, `STATE QUERIES` and `GETTERS`, and every region has its `#endregion`.
- [ ] Script layout follows `#export` -> declarations -> init -> debug block, with `#region` grouping in long files.
- [ ] Asset names follow the prefix table and match their folders.

## Anti-patterns

| Don't | Do |
| --- | --- |
| `if (x) {` | `if (x)` then `{` on its own line |
| `AssertTrue(is_scurve(t) ))` | `AssertTrue(is_scurve(t) ) )` |
| `var tween = ...` / `localTimer` | `var _tween = ...` / `_local_timer` |
| `static tick = function()` | `static __Tick = function()` (private) or `static Play = ...` (public) |
| `/// @param {number} x` | `/// @param {Real} x` |
| validate half the arguments, then mutate | validate everything, then mutate |
| throw / `show_error` inside a feature method | module error helper, then `return self` |
| `// increment the counter` | no comment, or explain the reason |
| `#region helpers` mixed case for new code | `#region HELPERS` |
| bare `3` in a flag field | documented constant, macro or enum |
