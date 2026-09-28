# Minimal bootstrap — actual config lives in conf.d/
# DO NOT add aliases, functions, or env vars here — use conf.d/ instead.
if status is-interactive
    # Interactive-only initialization (e.g. keybindings) goes here
    # Everything else is loaded automatically from conf.d/*.fish
end
