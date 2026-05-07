# Unsupervised

Interactive data analysis CLI powered by Claude Code. Explore datasets,
run queries, and generate reports from your terminal.

## Install

```bash
curl -fsSL https://unsupervised.com/cli/install.sh | sh
```

This downloads the correct binary for your platform and installs it to
`~/.local/bin/unsupervised`. Set `UNSUPERVISED_VERSION` or
`UNSUPERVISED_INSTALL_DIR` to customize.

### Project setup

```bash
unsupervised install [dir]
```

Sets up a project directory with the standard folder structure
(`business_context/`, `datasources/`, `queries/`, `reports/`, etc.),
downloads required binaries, and configures Claude Code permissions.

## Usage

### `unsupervised`

Opens the CLI directly. Launches Claude Code in analyst mode with bundled
configuration for data exploration, ad-hoc queries, and reporting.

```bash
unsupervised                       # start in current directory
unsupervised --role analyst        # explicit role (default)
unsupervised "summarize sales.csv" # pass a prompt directly
```

All unrecognized arguments are forwarded to Claude Code.

### `unsupervised web`

Opens the web UI for browser-based interaction. Provides a file viewer,
chat sidebar, and real-time workflow progress.

```bash
unsupervised web                   # start web UI → http://localhost:7070
```

### `unsupervised runner`

Headless runner for automated pipelines (planned).

## How it works

1. Claude Code runs with a bundled analyst configuration (system prompt,
   permissions, plugins)
2. DeepWork workflows coordinate multi-step analysis tasks
3. Reports are written to `reports/` in your project directory
4. The web UI watches for file changes and updates in real time

