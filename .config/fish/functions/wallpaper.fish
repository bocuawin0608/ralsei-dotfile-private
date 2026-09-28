function wallpaper --description 'Change wallpaper and regenerate theme'
    # Usage: wallpaper <path>    — apply specific wallpaper
    #        wallpaper --random  — pick random from ~/Pictures/Wallpapers/
    if test (count $argv) -eq 0
        echo 'Usage: wallpaper <path> | wallpaper --random'
        return 1
    else if test "$argv[1]" = '--random'
        bash ~/.config/quickshell/$QS_CONFIG/scripts/colors/random_wallpaper.sh
    else
        bash ~/.config/quickshell/$QS_CONFIG/scripts/colors/switchwall.sh "$argv[1]"
    end
end
