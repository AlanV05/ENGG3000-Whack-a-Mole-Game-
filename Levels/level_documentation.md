# Whack-a-Mole — Level Documentation

Levels are advanced manually by pressing **N** during play (used for demoing,
not tied to score or time). The 60s round timer runs continuously across all
levels — it doesn't reset when you advance.

---

## Level 1 — Warm Up

The baseline mode. One mole at a time, spawns in a random hole, stays up for
2 seconds before it escapes. No combo bonuses, no big mole, no double spawns.
This is just the core jump-to-whack loop.

---

## Level 2 — Combo Mode

Same single-mole spawn as Level 1, but hitting moles back-to-back now builds
a **combo streak** (shown in the HUD once it hits 2+).

- Reach a **5-combo** and the game gives a half-second "BIG MOLE INCOMING!"
  warning, then a **Big Mole** spawns instead of a normal one.
- The Big Mole is bigger (~1.7x size) but only stays up for **0.9 seconds**
  instead of 2 — it's a timing challenge, not a "wait around" challenge.
- Landing the hit gives a flat **+5 bonus** on top of normal scoring.
- Whether you hit it or miss it, the combo resets to 0 afterward — you have
  to build up another 5-streak for the next one.

---

## Level 3 — Overdrive

Everything from Level 2 still applies (combo streaks, Big Mole at 5), plus:

- Mole timeout drops to **1.1 seconds** — noticeably faster reactions needed.
- Each spawn has a **35% chance** of putting up two moles at once, in two
  different holes, instead of just one.
- The Big Mole event still takes priority when triggered — it always spawns
  alone so it stays a clear, readable moment even in the faster pace.

---

## Where to tune things

All the level settings live in `LEVEL_CONFIGS` and the constants just above
it near the top of the script (`BIG_MOLE_COMBO_THRESHOLD`,
`BIG_MOLE_BONUS_POINTS`, `BIG_MOLE_TIMEOUT_SECONDS`, `BIG_MOLE_SCALE`).
Changing timeout, dual-spawn chance, or the combo threshold needed doesn't
require touching any of the game loop logic.
