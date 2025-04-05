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
mv .zshrc ./.config-backup/.zshrc && \
mv .gitconfig ./.config-backup/.gitconfig && \
mv .tmux.conf ./.config-backup/.tmux.conf && \
mv .config/sketchbar/  ./.config-backup/sketchybar/ && \
mv .config/nvim/  ./.config-backup/nvim/

```

3. Install Aerospace Window Tiling Manager

```bash
brew install aerospace # window tiling manager
```

4. Install Zsh plugin manager (Oh My Zsh), as the .zshrc uses that.

[https://ohmyz.sh/#install](https://ohmyz.sh/#install)

5. Stow specific dotfile directories (inside ~/.dotfiles)

```bash
cd ~/.dotfiles/
stow aerospace
stow zsh
stow git
stow tmux
stow sketchybar # with aerospace specific config
stow nvim # may need to delete .DS_Store files if error appears
```
