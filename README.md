# Poetry In Code

![Cover Photo](cover.png)

A Claude Code plugin that gives you a poem whenever you send Claude a prompt. Inspired by [Poetry in Motion](https://poetrysociety.org/poetry-in-motion), an initiative that places poetry in the transit systems of U.S. cities. 

## Poetry

- Real poems by Dickinson, Whitman, Hopkins, Keats, Wordsworth, Blake, Frost, Teasdale, Rossetti, Shelley, Yeats, Stevens, Masefield, Henley, Bashō, Issa, Chiyo-ni, and Laozi. All public domain.

## Requirements

- **macOS.** The plugin uses `osascript` to spawn Terminal/iTerm windows, which is macOS-only. It will fail silently on Linux and Windows.
- Claude Code (plugins are in public beta)
- `jq` on your PATH (standard on macOS with Homebrew; `brew install jq` if missing)
- Terminal.app or iTerm2 as your terminal

## Install from a marketplace

Inside Claude Code:

```
/plugin marketplace add isabelringing1/poetry-in-code
/plugin install poetry-in-code@poetry-in-code-marketplace
```

## Run locally (for development)

From the directory that contains this plugin folder:

```bash
claude --plugin-dir ./poetry-in-code
```

## License

MIT for the plugin code. Poems are public domain. Feel free to submit more via PR!

