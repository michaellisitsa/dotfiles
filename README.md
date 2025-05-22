# Dotfiles Config

This uses the GNU stow method to creates symlinks and store the actual dotfiles a git subfolder
Inspired by [https://www.jakewiesler.com/blog/managing-dotfiles](https://www.jakewiesler.com/blog/managing-dotfiles)

1. Clone repo

```bash
cd ~; git clone [THIS REPO] .dotfiles
```

2. Backup existing dotfiles that will be overwritten (inside HOME directory)

```bash
cd ~; mkdir -p .config-backup && \
mv .aerospace.toml ./.config-backup/.aerospace.toml && \
mv .gitconfig ./.config-backup/.gitconfig && \
mv .tmux.conf ./.config-backup/.tmux.conf && \
mv .config/sketchbar/  ./.config-backup/sketchybar/ && \
mv .config/nvim/  ./.config-backup/nvim/

```

3. Install some dependencies

```bash
# For linux replace brew with relevant package manager
brew install --cask nikitabobko/tap/aerospace
brew install stow tmux ripgrep fzf fd
```

4. Install Zsh plugin manager (Oh My Zsh), as the .zshrc uses that.

[https://ohmyz.sh/#install](https://ohmyz.sh/#install)
```bash
# oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
mv .zshrc ./.config-backup/.zshrc # as above will create one
```

5. Stow specific dotfile directories (inside ~/.dotfiles)

```bash
cd ~/.dotfiles/

# Any unix
stow zsh
stow git
stow tmux
stow nvim # may need to delete .DS_Store files if error appears

# OSX only
stow aerospace

# Linux only
stow i3
```

6. Iterm settings sync (mac only)

Per guide in:
https://shyr.io/blog/sync-iterm2-configs

- Click General => Settings
  - Load Preferences from a custom subfolder
  - Save Changes to when quitting

## Adding a new config

1. Create a folder at the top-level with the name of what you're configuring e.g. nvim, i3, etc.
2. Create all sub-directories that would be included under root
3. Run `stow [name]` from the `~/.dotfiles` directory
