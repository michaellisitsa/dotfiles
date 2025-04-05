# Dotfiles Config

This uses the GNU stow method to creates symlinks and store the actual dotfiles a git subfolder
Inspired by [https://www.jakewiesler.com/blog/managing-dotfiles](https://www.jakewiesler.com/blog/managing-dotfiles)

1. Clone repo

```bash
cd ~; git clone [THIS REPO]
```

2. Backup existing dotfiles that will be overwritten

```bash
cd ~; mkdir -p .config-backup && \
mv .aerospace.toml ./.config-backup/.aerospace.toml && \
mv .zshrc ./.config-backup/.zshrc && \
mv .gitconfig ./.config-backup/.gitconfig
```

3. Install Aerospace Window Tiling Manager

```bash
brew install aerospace # window tiling manager
```

4. Install Zsh plugin manager (Oh My Zsh), as the .zshrc uses that.

[https://ohmyz.sh/#install](https://ohmyz.sh/#install)

5. Stow specific dotfile directories

```bash
stow git
stow zsh
stow aerospace
stow nvim # may need to delete .DS_Store files if error appears
```
