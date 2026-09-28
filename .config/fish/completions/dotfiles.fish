# Completions for the `dotfiles` command

set -l subcommands doctor validate reload restart wallpaper theme

# Top-level subcommands (only when no subcommand has been given yet)
complete -c dotfiles -n "not __fish_seen_subcommand_from $subcommands" \
    -a doctor    -d 'Check status of all components'
complete -c dotfiles -n "not __fish_seen_subcommand_from $subcommands" \
    -a validate  -d 'Validate config syntax'
complete -c dotfiles -n "not __fish_seen_subcommand_from $subcommands" \
    -a reload    -d 'Reload hyprland and restart Quickshell'
complete -c dotfiles -n "not __fish_seen_subcommand_from $subcommands" \
    -a restart   -d 'Restart Quickshell'
complete -c dotfiles -n "not __fish_seen_subcommand_from $subcommands" \
    -a wallpaper -d 'Change wallpaper and regenerate theme'
complete -c dotfiles -n "not __fish_seen_subcommand_from $subcommands" \
    -a theme     -d 'Toggle light/dark mode'

# wallpaper subcommand options
complete -c dotfiles -n "__fish_seen_subcommand_from wallpaper" \
    -a '--random'  -d 'Pick random wallpaper from ~/Pictures/Wallpapers/'
complete -c dotfiles -n "__fish_seen_subcommand_from wallpaper" \
    -F  # file completion for explicit paths

# theme subcommand options
complete -c dotfiles -n "__fish_seen_subcommand_from theme" \
    -a 'dark'  -d 'Switch to dark mode'
complete -c dotfiles -n "__fish_seen_subcommand_from theme" \
    -a 'light' -d 'Switch to light mode'
