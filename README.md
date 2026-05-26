# Gunttodo

Gunttodo is a lightweight macOS task tracker focused on keeping the current work visible without getting in the way.

## Download And Run On A Mac

```bash
git clone https://github.com/pulpvic/Gunttodo.git
cd Gunttodo
./script/build_and_run.sh
```

Gunttodo is a local SwiftUI/AppKit app. The script builds and launches a fresh `.app` bundle without creating an installer.

## Run

Use the Codex Run action, or run:

```bash
./script/build_and_run.sh
```

The script compiles the SwiftUI/AppKit sources locally, stages `dist/Gunttodo.app`, kills the previous process, and launches the fresh app. It does not create an installer.

## Product Shape

- A menu bar resident app for quick actions.
- A small Liquid Glass floating Gantt panel pinned above normal windows.
- A management window for projects, status, priority, dates, progress, tags, and notes.
- JSON persistence in `~/Library/Application Support/Gunttodo`.
