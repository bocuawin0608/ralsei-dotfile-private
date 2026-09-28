# 01-aliases.fish — Shell aliases

# ── Navigation ─────────────────────────────────────────────────────────────────
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'

# ── Listing ────────────────────────────────────────────────────────────────────
alias ls 'ls --color=auto'
alias ll 'ls -lah --color=auto'
alias la 'ls -A --color=auto'
alias lt 'ls -lah --color=auto --sort=time'

# ── Safety wrappers ────────────────────────────────────────────────────────────
alias cp 'cp -i'
alias mv 'mv -i'

# ── Hyprland / Hyprctl ────────────────────────────────────────────────────────
alias hl-reload 'hyprctl reload'
alias hl-repl   'hyprctl repl'
alias hl-kill   'hyprctl kill'

# ── Quickshell ─────────────────────────────────────────────────────────────────
alias qs-restart 'killall qs quickshell 2>/dev/null; qs -c $QS_CONFIG &'

# ── Dotfiles helpers ───────────────────────────────────────────────────────────
alias dotfiles-doctor   'bash ~/.config/hypr/hyprland/scripts/dotfiles_doctor.sh'
alias dotfiles-validate 'bash ~/.config/hypr/hyprland/scripts/dotfiles_validate.sh'

# ── Misc quality-of-life ──────────────────────────────────────────────────────
alias grep  'grep --color=auto'
alias diff  'diff --color=auto'
alias df    'df -h'
alias du    'du -sh'
alias free  'free -h'
alias mkdir 'mkdir -p'
