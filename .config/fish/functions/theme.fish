function theme --description 'Toggle or set desktop theme (dark/light)'
    # Usage: theme dark | theme light
    if test (count $argv) -eq 0
        echo 'Usage: theme [dark|light]'
        return 1
    end
    switch "$argv[1]"
        case dark light
            qs -c $QS_CONFIG ipc call quickshell:toggleLightDark
        case '*'
            echo 'Usage: theme [dark|light]'
            return 1
    end
end
