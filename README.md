# daily-commit

Because nothing says “passionate software artisan” like an automated timestamp commit at 9:15 AM.

This repo exists for one purpose: to gently nudge GitHub’s contribution graph into thinking I’m coding every day — even when I’m actually:
- answering emails,
- touching grass (rare),
- or staring into the void wondering why `launchctl` hates me.

## What it does

Once a day, a LaunchAgent runs a script that:
1. appends a timestamp to `logs/daily.log`
2. commits the change
3. pushes it to GitHub

Result: a tidy little trail of commits and a contribution graph that looks *remarkably* consistent.

## Why

- Motivation? Sure.
- Habit-building? Totally.
- Vanity? Let’s not pretend it isn’t a little.
- Science? Definitely science.

## Requirements

- macOS (because `launchd` is the star of this show)
- Git
- SSH access to GitHub (preferably configured so automation doesn’t get stuck asking for secrets)

## Setup (high level)

- Put the script somewhere stable (I used: `/Users/davidstinnett/bin/dailycommit.sh`)
- Add a LaunchAgent plist in `~/Library/LaunchAgents/`
- Schedule it for your preferred daily time
- Make sure the script’s PATH includes Homebrew Git if needed (`/opt/homebrew/bin`)

## Files

- `logs/daily.log` — the sacred scroll of proof I “did something”
- `dailycommit.sh` — the wizard behind the curtain (stored outside the repo)

## Ethics statement

This repo is a joke… mostly.

If you’re judging dev skill by green squares alone, that’s on you.  
(But also: welcome to the internet.)


## Today’s Quote

<!-- TODAY_QUOTE_START -->
> “Silence is a source of great strength.” — Lao Tzu

<sub>Updated: 2026-01-17 • Source: Quotable</sub>
<!-- TODAY_QUOTE_END -->

## License

Do whatever you want. If this somehow becomes your personality, at least buy me a coffee.
# daily-commit
