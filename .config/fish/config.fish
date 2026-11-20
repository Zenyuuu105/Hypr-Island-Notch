source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
#function fish_greeting
#    # smth smth
#end

# User scripts deployed by install.sh
fish_add_path $HOME/.local/bin

# Initialize Starship prompt
starship init fish | source
