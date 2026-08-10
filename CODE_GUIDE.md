# Code Guide

Conventions and judgment calls for authoring and reviewing mod code, especially state-driven `_process` / `_input` logic.

## Syntax rules

* Avoid creating untyped vars and consts. Use type inference with `:=` if RHS is a simple function call or a single statement, otherwise declare type explicitly. GDScript parser has trouble inferring type from complex expressions.
* Format explicit var/const declaration like this `var var_name: Type` - note the spacing.
* Avoid creating untyped arrays and dictionaries wherever possible without re-allocating.
	* Note that GDScript doesn't allow casting untyped collections into typed equivalent. This expression `untyped_array as Array[int]` will produce null even if every value inside the array is int.
	* The only way to convert an untyped array to a typed array is by creating a typed copy and using assign() method - this is an unreasonable overhead most of the time.
* Use C-type boolean operators `||` and `&&` instead of `or` and `and`.
* Use colon for dictionary `{"key": "value"}` declaration.
* Enforce two empty lines between functions.
* Enforce Tab indentation.
* Use `!obj` style for `null` checks instead of `obj == null`.
* For types that inherit `Node` use `is_instance_valid(obj)` instead of a null check to make sure the instance wasn't disposed.
* Do not mix `if/elif` condition trees with early returns within the same function - pick one approach.
* Comments must add context the code cannot convey (constraints, reasons, gotchas). Do not narrate what the code already says.
* Do not hard-wrap a comment sentence across lines - the editor already soft-wraps. Start a new comment line only for a new sentence or thought.

## State machines

- **`_process` drives state; `_input` only selects it.** Input handlers mutate `_state` (and minimal state payload) and nothing else. Per-frame work, scene mutation (animator, audio, shaders), timers and dispatch live in `_process`. Keep all side effects in one place.
	- It is fine to call a complete, fire-and-forget action (a self-contained coroutine) directly from `_input`. What must not happen in `_input` is *partial-state* manipulation (un-pausing an animator, stopping a sound mid-sequence). Make those into states handled by `_process`.

- **Use `await` for linear sequences; don't rebuild it as a delta-timer FSM.** "Play animation, wait for it, apply changes" should just `await` (e.g. `await await_animation(...)`, `await play(...)`). Do not reimplement animation-completion waiting with a busy state, a kind-tag, a length pre-read and an on-complete dispatch. Reserve a per-frame `_process` FSM for genuinely *interactive* phases (hold, pause, release) that would otherwise be a polling loop (`while ...: await process_frame`).

- **A state must have distinct per-frame processing.** If a candidate state runs the same processing as another and differs only in a one-time terminal action, it is a flag in disguise. Collapse it. Conversely, a bit that *selects a transition* belongs in the enum, not a parallel bool.
	- Promote transition-selecting flags into states (e.g. a "released early" bit becomes a distinct state).
	- Don't create a state that only carries a terminal parameter of a shared phase; pass it as data instead.
	- An inert "an awaited sequence owns the machine" marker state is acceptable when its only job is to block re-entry while a coroutine finishes itself, and existing gameplay flags don't already cover that window.

- **Collapse redundant intermediate states into a threshold or awaiter.** A phase whose only job is "wait, then flip one thing" doesn't need its own state. Express it as a small awaiter fired at the right moment.

- **Mind same-frame fall-through with early-return ifs.** A `match` evaluates the subject once; an `if` chain re-reads `_state` after each block. When a block mutates `_state`, it must `return` so the next `if` doesn't re-match the new state and run two phases in one frame. Prefer flat, uniform `if _state == X: ... return` handlers (consistent with the rule against mixing elif trees with early returns).

## Functions

- **Inline single-use helpers.** Keep a helper only when shared by 2+ callers or when it genuinely clarifies. Fold one-call helpers back into the call site.
- **Collapse two functions that differ only by a constant into one bool/param function** (e.g. show/hide pair → `_set(shown: bool)`).
- **Name a function for what it does, not the path that triggered it.** A single cleanup routine can serve both normal completion and `_exit_tree` teardown.
- **A bool param that fully determines behavior is borderline.** Fine when the paths share most logic; if they diverge heavily, prefer two states/functions.

## Variables

- **Hoist a value used by multiple branches to the top of the function** (e.g. `var rig = get_parent()` once per `_process`, not per branch).
- **Extract a repeated sub-expression into a named local** (e.g. `var timer_expired: bool = _timer <= 0.0`) for readability and single evaluation.
- **One variable per concept, reused across mutually exclusive phases.** Sequential, never-concurrent phases can share a single timer rather than one per phase. When merging, ensure it is decremented exactly once per frame (watch for double-decrement).
- **Don't keep vestigial vars.** A member only assigned-then-immediately-read should be a local or inlined. A member nulled in cleanup but always reassigned before use is dead housekeeping.

## Guards and validity

- **`is_instance_valid()` only earns its place after an `await`,** where the node can be freed mid-wait. Synchronous reads of a member set earlier in the same call don't need it.
- **Free-running timers are safe only if reset on entry and read only when state-gated.** Hoisting a `_timer -= delta` out of its state guard is acceptable when the timer is reset on every phase entry and read only inside a state-gated condition. The cost is a latent footgun (a future reader in another state sees a decrementing value) plus minor wasted work. Weigh it.

## Behavior and process

- **Aborting vs resuming is a real semantic distinction.** Interrupting a sequence to start another should *abort* the first (stop its sound, replace its animation), not un-pause/resume it. Express the intent rather than relying on an incidental side effect (a later `stop()`/replace) to achieve the abort.
- **Preserve behavioral parity with the original unless a change is requested.** When reproducing timing, verify the math (e.g. that an `await delay` then `await_animation` collapses to the intended total) rather than assuming.
- **Plan, confirm, then implement.** Propose a structural change and surface its tradeoffs before editing.
