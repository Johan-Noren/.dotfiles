HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
zstyle ':completion:*' use-ip true
setopt NO_CASE_GLOB
autoload -Uz compinit
compinit

# CALCULATOR
autoload -U zcalc
function __calc_plugin { zcalc -e "$*" }
aliases[calc]='noglob __calc_plugin'
aliases[=]='noglob __calc_plugin'

# ALIASES
alias vi='nvim '
alias sudo='sudo '
alias ls='ls --color=auto'

# PROMPT
export PS1='
%B%F{white}%d%f%b '

unset GLOBAL_RCS

export GDK_BACKEND=wayland
export MOZ_ENABLE_WAYLAND=1
export MOZ_USE_XINPUT2=1
export QT_QPA_PLATFORM=wayland-egl
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export EDITOR=/bin/nvim
export BROWSER=/bin/firefox
export GTK_THEME='Adwaita:dark'
