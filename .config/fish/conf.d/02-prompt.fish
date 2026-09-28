# 02-prompt.fish — Prompt initialization
# Priority: starship > tide > plain fish prompt

if status is-interactive
    if command -v starship >/dev/null 2>&1
        starship init fish | source
    # Tide is a fish plugin; check if it's loaded via its init function
    else if functions -q _tide_init
        # tide is already initialized via its plugin loader
        true
    end
    # Otherwise, fish falls back to its built-in prompt — no action needed
end
