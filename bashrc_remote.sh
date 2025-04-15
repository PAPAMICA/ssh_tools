#!/bin/bash
. /etc/profile
. ~/.bashrc
BUTTONS=False
# Color variables:
export black='\033[0;30m'
export red="\e[0;31m"
export green="\e[0;32m"
export yellow="\e[0;33m"
export blue="\e[0;34m"
export purple="\e[0;35m"
export grey="\e[0;37m"
export reset="\e[m"
export bold="\e[1m"
# Background
export On_Black='\033[40m'       # Black
export On_Red='\033[41m'         # Red
export On_Green='\033[42m'       # Green
export On_Yellow='\033[43m'      # Yellow
export On_Blue='\033[44m'        # Blue
export On_Purple='\033[45m'      # Purple
export On_Cyan='\033[46m'        # Cyan
export On_White='\033[47m'       # White
# MOTD
# Information gathering
motd() {
    hostname=$(hostname)
    if command -v lsb_release &> /dev/null; then
        distribution=$(lsb_release -d -s)
    elif [ -f /etc/redhat-release ]; then
        distribution=$(cat /etc/redhat-release)
    elif [ -f /etc/os-release ]; then
        distribution=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
    else
        distribution="Distribution inconnue"
    fi
    userconnected=$(who | grep pts | wc -l)
    usernames=$(who | grep pts | awk '{print $1}' | xargs)
    fi
    proc=$(nproc --all)
    proc_120=$(($proc*120/100))
    memfree=$(cat /proc/meminfo | grep MemFree | awk '{print $2}')
    memtotal=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
    memused=$(($memtotal-$memfree))
    memusedpercent=$(($memused*100/$memtotal))
    if [ $memusedpercent -lt 90 ]; then
        ramcolor=$green
    elif [ $memusedpercent -lt 96 ]; then
        ramcolor=$yellow
    else
        ramcolor=$red
    fi
    # Get swap information
    swaptotal=$(cat /proc/meminfo | grep SwapTotal | awk '{print $2}')
    swapfree=$(cat /proc/meminfo | grep SwapFree | awk '{print $2}')
    if [ $swaptotal -gt 0 ]; then
        swapused=$(($swaptotal-$swapfree))
        swapusedpercent=$(($swapused*100/$swaptotal))
        if [ $swapusedpercent -lt 50 ]; then
            swapcolor=$green
        elif [ $swapusedpercent -lt 80 ]; then
            swapcolor=$yellow
        else
            swapcolor=$red
        fi
    fi
    uptime=$(uptime -p 2> /dev/null)
    uptime_s=$(awk -F '.' '{print $1}' /proc/uptime)
    if [ $uptime_s -lt 86400 ]; then
        uptcolor=$yellow
    else
        uptcolor=$green
    fi
    addrip=$(hostname -I | cut -d " " -f1)
    public_ip=$(curl -s -f --connect-timeout 1 ifconfig.me)
    read one five fifteen rest < /proc/loadavg
    if (( $(echo "$one $proc" | awk '{print ($1 < $2)}') )); then
        onecolor=$green
    elif (( $(echo "$one $proc_120" | awk '{print ($1 < $2)}') )); then
        onecolor=$yellow
    else
        onecolor=$red
    fi
    if (( $(echo "$five $proc" | awk '{print ($1 < $2)}') )); then
        fivecolor=$green
    elif (( $(echo "$five $proc_120" | awk '{print ($1 < $2)}') )); then
        fivecolor=$yellow
    else
        fivecolor=$red
    fi
    if (( $(echo "$fifteen $proc" | awk '{print ($1 < $2)}') )); then
        fifteencolor=$green
    elif (( $(echo "$fifteen $proc_120" | awk '{print ($1 < $2)}') )); then
        fifteencolor=$yellow
    else
        fifteencolor=$red
    fi
    # Function to generate progress bar
    generate_progress_bar() {
        local percent=$1
        local width=20
        local filled=$(($width * $percent / 100))
        local empty=$(($width - $filled))
        printf "["
        printf "%${filled}s" | tr ' ' '='
        printf "%${empty}s" | tr ' ' ' '
        printf "] "
    }
    # Get storage information
    while read -r line; do
        if [[ $line =~ ^/dev/ ]]; then
            mount=$(echo $line | awk '{print $6}')
            size=$(echo $line | awk '{print $2}')
            used=$(echo $line | awk '{print $3}')
            avail=$(echo $line | awk '{print $4}')
            usepercent=$(echo $line | awk '{print $5}' | sed 's/%//')

            if [ $usepercent -lt 80 ]; then
                diskcolor=$green
            elif [ $usepercent -lt 90 ]; then
                diskcolor=$yellow
            else
                diskcolor=$red
            fi

            # Calculate maximum length for alignment
            mount_padded=$(printf "%-12s" "$mount")
            size_padded=$(printf "%4s" "$size")
            avail_padded=$(printf "%4s" "$avail")
            usepercent_padded=$(printf "%3s" "$usepercent")
            storage_info="$storage_info\n  $mount_padded: ${diskcolor}$(generate_progress_bar $usepercent) ${usepercent_padded}%${reset} (${avail_padded} / ${size_padded})"
        fi
    done < <(df -h | grep -v "tmpfs\|devtmpfs\|snap")
    # Check Docker presence
    if command -v docker &> /dev/null; then
        total_containers=$(sudo docker ps -a --format '{{.Status}}' | wc -l)
        healthy_containers=$(sudo docker ps -a --format '{{.Status}}' | grep -c "healthy")
        running_containers=$(sudo docker ps -a --format '{{.Status}}' | grep -c "Up" | grep -v "healthy")
        unhealthy_containers=$(sudo docker ps -a --format '{{.Status}}' | grep -c "unhealthy")
        stopped_containers=$(sudo docker ps -a --format '{{.Status}}' | grep -c "Exited")

        docker_info="  Docker : ${blue}Present${reset} → ${blue}${running_containers} running${reset} (${green}${healthy_containers} healthy${reset}, ${red}${unhealthy_containers} unhealthy${reset}) - ${yellow}${stopped_containers} stopped${reset}"
    fi
    # Display MOTD
    motd_content=$(cat /etc/motd /etc/motd.d/* 2>/dev/null)
    if [ -n "$motd_content" ]; then
        echo -e "\n$motd_content\n  -------------------\n"
    fi
    echo -e "\n  Hostname : ${blue}${bold}$(hostname)$purple${moreinfo}${reset}"
    echo -e "  Distribution : ${bold}$distribution${reset}"
    echo -e "  Connected users : ${bold}$userconnected$purple ${usernames}${reset}"
    printf "\n  Processors : $proc"
    printf "\n"
    printf "  Load CPU : $onecolor$one (1min)$reset / $fivecolor$five (5min)$reset / $fifteencolor$fifteen (15min)$reset"
    printf "\n"
    printf "  IP Address : $public_ip ($addrip)"
    printf "\n"
    printf "  RAM : $(($memfree/1024/1024))GB free / $(($memtotal/1024/1024))GB ($ramcolor$memusedpercent%% used$reset)"
    printf "\n"
    if [ $swaptotal -gt 0 ]; then
        printf "  SWAP : $(($swapfree/1024/1024))GB free / $(($swaptotal/1024/1024))GB ($swapcolor$swapusedpercent%% used$reset)"
    else
        printf "  SWAP : ${yellow}disabled${reset}"
    fi
    printf "\n"
    printf "  Uptime : $uptcolor$uptime$reset"
    printf "\n"
    # Display storage information
    echo -e "$storage_info"
    printf "\n"
    if [ -n "$docker_info" ]; then
        printf "$docker_info"
    else
        printf "  Docker : ${yellow}Absent${reset}"
    fi
    printf "\n"
    printf "\n"
}
export -f motd
motd
# Family help
dfihelp() {
    echo -e "\nAvailable commands:
    ${bold}motd${reset}               : Display welcome message
    ${bold}p / hp${reset}             : Show / hide current path
    ${bold}oomanalyser${reset}        : Execute script to analyze ooms
    "
}
export -f dfihelp
# Increase process priority with nice and ionice
if [ "$EUID" -eq 0 ]; then
    renice -n -20 -p $$ >/dev/null
    ionice -c 2 -n 0 -p $$ >/dev/null
fi
# Custom prompt
# Function to update PS1 color based on user
update_ps1_color() {
    if [ "$(whoami)" = "root" ]; then
        PS1_USER_COLOR="$red"
    else
        PS1_USER_COLOR="$green"
    fi
    export PS1_USER_COLOR
}

# Initial call
update_ps1_color

# Add trap to update color when user changes
trap update_ps1_color DEBUG
export PS1="\[${PS1_USER_COLOR}\]\u\[${grey}\]@\[${blue}\]\h \[${grey}\]>\[${reset}\] "
p() {
    export PS1="\[${PS1_USER_COLOR}\]\u\[${grey}\]@\[${blue}\]\h\[${yellow}\]:\w \[${grey}\]>\[${reset}\] "
}
export -f p
hp() {
    export PS1="\[${PS1_USER_COLOR}\]\u\[${grey}\]@\[${blue}\]\h \[${grey}\]>\[${reset}\] "
}
export -f hp
# Get list of SSH root connections and key owner used to connect
rootauthlog() {
    local KEYS=$(grep -o 'ssh-rsa.*' ~/.ssh/authorized_keys | while read type key name; do (cd /tmp; printf "%s %s %s" "$type" "$key" "$name" > "$name"; ssh-keygen -l -f "$name"; rm "$name"); done)
    l auth a | grep "Accepted publickey for root" | while read line; do echo -n "$line -> "; echo "$KEYS" | grep "$(echo $line | awk '{print $NF}')" | awk '{print $3}'; done
}
# Vim with custom vimrc
vic() {
    local tmpfile=$(mktemp)
    cat >$tmpfile <<EOF
__VIMRC__
EOF
    $(which vim) -u $tmpfile "$@"
    rm $tmpfile
}
export -f vic
# Sudo su with bashrc reload
suroot() {
    user=$(whoami)
    sudo su -c "source /home/$user/bashrc_remote.sh; exec bash" root
}
export -f suroot
oomanalyser() {
    local tmpfile=$(mktemp)
    local url="https://raw.githubusercontent.com/LukeShirnia/out-of-memory/3f8bdbc38f8139e228be0085960e190554148af3/oom-investigate.py"
    local hash="1bdae43494d9ab115b565ff76bd0542b260017ad3ee1fd03d8c4cb929649d1ff"
    curl "$url" --output "$tmpfile"
    if [[ "$(sha256sum $tmpfile | awk '{print $1}')" == "$hash" ]]; then
        chmod +x "$tmpfile"
        "$tmpfile" "$@"
    else
        echo "Hash is not correct, exiting"
    fi
    rm "$tmpfile"
}
export -f oomanalyser
# ls color
alias ls='ls --color=auto -F'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
