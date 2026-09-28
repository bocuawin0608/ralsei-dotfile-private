function dotfiles --description 'Dotfile management CLI'
    # Usage: dotfiles [doctor|validate|reload|restart|wallpaper|theme]
    if test (count $argv) -eq 0
        echo 'Usage: dotfiles [doctor|validate|reload|restart|wallpaper|theme]'
        return 1
    end
    switch "$argv[1]"
        case doctor
            bash ~/.config/hypr/hyprland/scripts/dotfiles_doctor.sh
        case validate
            bash ~/.config/hypr/hyprland/scripts/dotfiles_validate.sh
        case reload
            hyprctl reload
            and qs-restart
        case restart
            qs-restart
        case wallpaper
            wallpaper $argv[2..-1]
        case theme
            theme $argv[2..-1]
        case '*'
            echo 'Usage: dotfiles [doctor|validate|reload|restart|wallpaper|theme]'
            return 1
    end
end
