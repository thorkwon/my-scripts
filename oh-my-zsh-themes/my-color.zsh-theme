# -*- sh -*- vim:set ft=sh ai et sw=4 sts=4:
# It might be bash like, but I can't have my co-workers knowing I use zsh

function branch_color()
{
    if git rev-parse --git-dir >/dev/null 2>&1; then
        if git diff --quiet 2>/dev/null >&2; then
            BRANCH_COLOR="%{$fg[green]%}("
        else
            BRANCH_COLOR="%{$fg[red]%}("
        fi
        echo -ne $BRANCH_COLOR
    fi
}

function git-mode-toggle()
{
    if [ $GIT_MODE -eq 1 ]; then
        GIT_MODE=0
        echo "Disable git mode"
        PROMPT='%{$fg[green]%}%n@%m:%{$fg_bold[blue]%}%~ %{$reset_color%}%(!.#.$) '
    else
        GIT_MODE=1
        echo "Enable git mode"
        PROMPT='%{$fg[green]%}%n@%m:%{$fg_bold[blue]%}%~ $(branch_color)$(git_prompt_info)%{$reset_color%}%(!.#.$) '
    fi
}


ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=")%{$reset_color%}"

GIT_MODE=1
PROMPT='%{$fg[green]%}%n@%m:%{$fg_bold[blue]%}%~ $(branch_color)$(git_prompt_info)%{$reset_color%}%(!.#.$) '
