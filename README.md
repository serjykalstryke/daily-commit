# daily-commit

## Today’s Quote
<!-- TODAY_QUOTE_START -->
> “Ideas do not reach perfection in a day, no matter how much study is put upon them.” — Alexander Graham Bell

<sub>Updated: 2026-04-03 • Source: [ZenQuotes API](https://zenquotes.io/)</sub>
<!-- TODAY_QUOTE_END -->
## Purpose

Because nothing says “passionate software artisan” like an automated timestamp commit at 9:15 AM.

This repo is a gentle reminder that consistency can be automated… but progress still has to be earned.

daily-commit exists for one purpose: to gently nudge GitHub’s contribution graph into thinking I’m coding every day — even when I’m actually:
- answering emails,
- touching grass (rare),
- or staring into the void wondering why my scheduler hates me.

## What it does

Once a day, a scheduler runs a script that:
1. appends a timestamp to `logs/daily.log`
2. (optionally) updates the README “Today’s Quote” block
3. commits the change
4. pushes it to GitHub

Result: a tidy little trail of commits and a contribution graph that looks *remarkably* consistent.

## Why

- Motivation? Sure.
- Habit-building? Totally.
- Vanity? Let’s not pretend it isn’t a little.
- Science? Definitely science.

## Requirements

- Any Unix-like OS (macOS or Linux)
- git
- python3
- SSH access to GitHub (configured so automation can push non-interactively)

> ⚠️ Scheduler jobs often run with a minimal environment. If `git push` works in your terminal but fails in automation, it’s almost always SSH agent/keychain/keyring setup.

## Setup

### 1) Put the script somewhere stable

Example:

- $HOME/bin/dailycommit.sh (common)
- or any path you want, as long as your scheduler can execute it

Make it executable:

    chmod +x $HOME/bin/dailycommit.sh

### 2) Manual test (run once)

The script needs to know which repo to operate on. `REPO` should point to the folder containing this repo’s `.git` directory.

Set `REPO` to the path of this repo:

    REPO="$HOME/path/to/daily-commit" $HOME/bin/dailycommit.sh

If it can commit and push once manually, scheduling it is straightforward.

### 3) Scheduling

#### macOS: launchd (LaunchAgent)

On macOS, the easiest “set it and forget it” scheduler is a **LaunchAgent**: a small `.plist` file that lives in `$HOME/Library/LaunchAgents/` and runs on your behalf while you’re logged in.

This is the general flow:
- create the plist
- load it with `launchctl`
- optionally “kickstart” it to test immediately
- confirm logs / status

**1) Create the LaunchAgents folder (if it doesn’t exist)**

    mkdir -p $HOME/Library/LaunchAgents

**2) Create the plist**

Pick a label (use reverse-DNS style). Example:

    nano $HOME/Library/LaunchAgents/com.example.dailycommit.plist

Paste this (edit the `REPO` path + script path if yours differs):

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.example.dailycommit</string>

        <!-- Run a login shell so env vars work, and inject REPO -->
        <key>ProgramArguments</key>
        <array>
          <string>/bin/bash</string>
          <string>-lc</string>
          <string>REPO="$HOME/path/to/daily-commit" "$HOME/bin/dailycommit.sh"</string>
        </array>

        <!-- Run every day at 09:15 local time -->
        <key>StartCalendarInterval</key>
        <dict>
          <key>Hour</key>
          <integer>9</integer>
          <key>Minute</key>
          <integer>15</integer>
        </dict>

        <!-- Also run once when the agent loads (optional) -->
        <key>RunAtLoad</key>
        <true/>

        <!-- Helpful logs -->
        <key>StandardOutPath</key>
        <string>/tmp/dailycommit.out</string>
        <key>StandardErrorPath</key>
        <string>/tmp/dailycommit.err</string>
      </dict>
    </plist>

Notes:
- `RunAtLoad` is optional. If you don’t want an extra run at load/login, set it to `<false/>` or remove it.
- `StartCalendarInterval` is local time.
- Using `/bin/bash -lc ...` makes the command behave more like a normal terminal session and allows `REPO="..."` inline.

**3) Validate the plist**
(If this prints nothing, it’s usually fine.)

    plutil -lint $HOME/Library/LaunchAgents/com.example.dailycommit.plist

**4) Load it so it runs automatically**
These commands register it for your user session:

    launchctl bootstrap gui/$(id -u) $HOME/Library/LaunchAgents/com.example.dailycommit.plist

If you ever need to unload it:

    launchctl bootout gui/$(id -u) $HOME/Library/LaunchAgents/com.example.dailycommit.plist

**5) Test it immediately (optional)**
Kick it once right now:

    : > /tmp/dailycommit.err
    : > /tmp/dailycommit.out
    launchctl kickstart -k gui/$(id -u)/com.example.dailycommit

Check logs:

    tail -n 80 /tmp/dailycommit.out /tmp/dailycommit.err

**6) Confirm it’s registered**
Print the agent status:

    launchctl print gui/$(id -u)/com.example.dailycommit | head -n 60

**Common gotchas**
- If `git push` fails with “Permission denied (publickey)”, your SSH key isn’t available to automation yet. Ensure your SSH agent/keychain setup loads the key at login.
- If you see `README.md not found`, your `REPO=...` path points to the wrong folder.
- If it “runs but does nothing”, that’s normal if there are no file changes (git won’t create a new commit if nothing changed).

**Changing the schedule**
To run at a different time, change the `Hour` and `Minute` values in `StartCalendarInterval`, then bootout/bootstrap again (or kickstart).

#### Linux: systemd user timer

Create:

$HOME/.config/systemd/user/dailycommit.service

    [Unit]
    Description=Daily commit + quote update

    [Service]
    Type=oneshot
    Environment=REPO=%h/path/to/daily-commit
    ExecStart=/usr/bin/env bash -lc '%h/bin/dailycommit.sh'

Note: `%h` is a systemd shortcut for your home directory (similar to `$HOME` in a shell).

$HOME/.config/systemd/user/dailycommit.timer

    [Unit]
    Description=Run dailycommit daily

    [Timer]
    OnCalendar=*-*-* 09:15:00
    Persistent=true

    [Install]
    WantedBy=timers.target

Enable:

    systemctl --user daemon-reload
    systemctl --user enable --now dailycommit.timer
    systemctl --user list-timers | grep dailycommit

Logs:

    journalctl --user -u dailycommit.service -n 100 --no-pager

#### Any Unix: cron

Edit your crontab:

    crontab -e

Add:

    15 9 * * * REPO="$HOME/path/to/daily-commit" /usr/bin/env bash -lc "$HOME/bin/dailycommit.sh" >> /tmp/dailycommit.out 2>> /tmp/dailycommit.err


## Verifying it’s actually running

No matter which scheduler you use, the goal is the same:
- the job runs at the scheduled time
- it produces either a commit + push, *or* a “no changes” no-op
- errors (if any) are visible somewhere obvious

### Quick “did it run?” checks

#### macOS (launchd)
If you used the `StandardOutPath` / `StandardErrorPath` paths from the example plist:

    tail -n 80 /tmp/dailycommit.out /tmp/dailycommit.err

You can also confirm the agent is registered:

    launchctl print gui/$(id -u)/com.example.dailycommit | head -n 80

And you can force a test run immediately:

    : > /tmp/dailycommit.err
    : > /tmp/dailycommit.out
    launchctl kickstart -k gui/$(id -u)/com.example.dailycommit
    tail -n 80 /tmp/dailycommit.out /tmp/dailycommit.err

#### Linux (systemd user timer)
Confirm the timer is scheduled:

    systemctl --user list-timers | grep dailycommit

Force-run the service once:

    systemctl --user start dailycommit.service

View logs:

    journalctl --user -u dailycommit.service -n 120 --no-pager

#### Any Unix (cron)
Cron won’t show you much unless you log output somewhere. If you used the example crontab line that redirects output:

    tail -n 120 /tmp/dailycommit.out /tmp/dailycommit.err

### What “success” looks like
- If there was a change: you should see a new commit and a `git push` message in logs, and your GitHub repo will update.
- If there was no change: you might see “ran at …” but no commit (that’s normal — git won’t commit/push if nothing changed).

### Most common failure modes
- `Permission denied (publickey)` → SSH key isn’t available to the scheduler environment (agent/keychain/keyring).
   - macOS: use Keychain / `ssh-add --apple-use-keychain $HOME/.ssh/id_ed25519`
   - Linux: ensure ssh-agent/keyring is active for user session
- `README markers not found` → the `<!-- TODAY_QUOTE_START -->` / `<!-- TODAY_QUOTE_END -->` block is missing or duplicated.
- `README.md not found` → `REPO=...` points to the wrong directory.

## Files

- logs/daily.log — the sacred scroll of proof I “did something”
- README.md — contains the “Today’s Quote” block (updated daily)
- dailycommit.sh — the wizard behind the curtain (you can keep it in the repo, or keep it somewhere stable like $HOME/bin/)

## Ethics statement

This repo is a joke… mostly.

If you’re judging dev skill by green squares alone, that’s on you.
(But also: welcome to the internet.)

## License

Do whatever you want. If this somehow becomes your personality, at least buy me a coffee.
