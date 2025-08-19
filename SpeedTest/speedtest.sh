#!/bin/bash

# Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

# Test URLs
URLS=(
    "https://nbg1-speed.hetzner.com/1GB.bin"
    "https://lon.speedtest.clouvider.net/1g.bin"
)

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    PKG_INSTALL="apt-get install -y"
    PKG_UPDATE="apt-get update -y"
elif command -v dnf >/dev/null 2>&1; then
    PKG_INSTALL="dnf install -y"
    PKG_UPDATE="dnf makecache -y"
elif command -v yum >/dev/null 2>&1; then
    PKG_INSTALL="yum install -y"
    PKG_UPDATE="yum makecache -y"
else
    echo "${RED}Error:${RESET} Package manager not supported!"
    exit 1
fi

# Install tool if missing
install_if_missing() {
    CMD=$1
    PKG=$2
    if ! command -v $CMD >/dev/null 2>&1; then
        echo "${YELLOW}Installing ${PKG}...${RESET}"
        sudo $PKG_UPDATE
        sudo $PKG_INSTALL $PKG
    fi
}

install_if_missing wget wget
install_if_missing wget2 wget2
install_if_missing axel axel
install_if_missing aria2c aria2

# Ask user for tools
echo -e "${BLUE}Select tools (comma separated):${RESET}"
echo "1) wget"
echo "2) wget2"
echo "3) axel"
echo "4) aria2c"
read -p "Enter choice(s) [e.g. 1,3,4]: " TOOL_CHOICES

# Ask user for modes
echo -e "\n${BLUE}Select test modes (comma separated):${RESET}"
echo "1) Single connection"
echo "2) Multi connection"
read -p "Enter choice(s) [e.g. 1,2]: " MODE_CHOICES

IFS=',' read -ra TOOLS <<< "$TOOL_CHOICES"
IFS=',' read -ra MODES <<< "$MODE_CHOICES"

RESULTS=()

parse_speed() {
    TOOL=$1
    LOG=$2
    SPEED="N/A"
    case $TOOL in
        wget|wget2|axel)
            SPEED=$(grep -oE "[0-9.]+[ ]?(MB/s|KB/s|GB/s)" "$LOG" | tail -1)
            ;;
        aria2c)
            SPEED=$(grep -oE "[0-9.]+[KMGT]?B/s" "$LOG" | tail -1)
            ;;
    esac
    echo "$SPEED"
}

echo -e "\n${GREEN}Starting tests...${RESET}"

for URL in "${URLS[@]}"; do
    echo -e "\n${YELLOW}Testing URL: $URL${RESET}"

    for TOOL_CHOICE in "${TOOLS[@]}"; do
        case $TOOL_CHOICE in
            1) TOOL="wget" ;;
            2) TOOL="wget2" ;;
            3) TOOL="axel" ;;
            4) TOOL="aria2c" ;;
            *) echo "${RED}Invalid tool choice: $TOOL_CHOICE${RESET}"; continue ;;
        esac

        for MODE_CHOICE in "${MODES[@]}"; do
            TMP_LOG=$(mktemp)

            echo -e "\n${BLUE}Running $TOOL ($( [ "$MODE_CHOICE" -eq 1 ] && echo "Single" || echo "Multi" ))...${RESET}"
            echo "${YELLOW}Progress will show live (speed + remaining time).${RESET}"

            case $TOOL in
                wget)
                    if [ "$MODE_CHOICE" -eq 1 ]; then
                        wget --progress=bar:force -O /dev/null "$URL" 2>&1 | tee "$TMP_LOG"
                    else
                        echo "${RED}[wget does not support multi-connection]${RESET}" | tee "$TMP_LOG"
                    fi
                    ;;
                wget2)
                    if [ "$MODE_CHOICE" -eq 1 ]; then
                        wget2 --max-threads=1 --progress=bar -O /dev/null "$URL" 2>&1 | tee "$TMP_LOG"
                    else
                        wget2 --max-threads=8 --progress=bar -O /dev/null "$URL" 2>&1 | tee "$TMP_LOG"
                    fi
                    ;;
                axel)
                    if [ "$MODE_CHOICE" -eq 1 ]; then
                        axel -n 1 -o /dev/null "$URL" 2>&1 | tee "$TMP_LOG"
                    else
                        axel -n 8 -o /dev/null "$URL" 2>&1 | tee "$TMP_LOG"
                    fi
                    ;;
                aria2c)
                    if [ "$MODE_CHOICE" -eq 1 ]; then
                        aria2c -x 1 -s 1 -o /dev/null "$URL" 2>&1 | tee "$TMP_LOG"
                    else
                        aria2c -x 16 -s 16 -o /dev/null "$URL" 2>&1 | tee "$TMP_LOG"
                    fi
                    ;;
            esac

            SPEED=$(parse_speed "$TOOL" "$TMP_LOG")
            rm -f "$TMP_LOG"

            RESULTS+=("$URL | $TOOL | $( [ "$MODE_CHOICE" -eq 1 ] && echo "Single" || echo "Multi" ) | $SPEED")
        done
    done
done

echo -e "\n${BLUE}============================"
echo "Test Summary"
echo -e "============================${RESET}"

printf "%-55s %-8s %-8s %-15s\n" "URL" "TOOL" "MODE" "SPEED"
printf "%-55s %-8s %-8s %-15s\n" "-------------------------------------------------------" "--------" "--------" "---------------"

declare -A AVG_SUM AVG_COUNT

for R in "${RESULTS[@]}"; do
    URL=$(echo "$R" | cut -d'|' -f1 | xargs)
    TOOL=$(echo "$R" | cut -d'|' -f2 | xargs)
    MODE=$(echo "$R" | cut -d'|' -f3 | xargs)
    SPEED=$(echo "$R" | cut -d'|' -f4 | xargs)

    printf "%-55s %-8s %-8s %-15s\n" "$URL" "$TOOL" "$MODE" "$SPEED"

    if [[ "$SPEED" =~ ^[0-9] ]]; then
        UNIT=$(echo "$SPEED" | awk '{print $2}')
        VALUE=$(echo "$SPEED" | awk '{print $1}')
        case $UNIT in
            KB/s) VALUE=$(echo "$VALUE / 1024" | bc -l) ;;
            MB/s) VALUE=$VALUE ;;
            GB/s) VALUE=$(echo "$VALUE * 1024" | bc -l) ;;
        esac
        KEY="$TOOL-$MODE"
        AVG_SUM[$KEY]=$(echo "${AVG_SUM[$KEY]:-0} + $VALUE" | bc -l)
        AVG_COUNT[$KEY]=$(( ${AVG_COUNT[$KEY]:-0} + 1 ))
    fi
done

echo -e "\n${GREEN}Average Speeds per Tool/Mode:${RESET}"
printf "%-8s %-8s %-15s\n" "TOOL" "MODE" "AVG SPEED (MB/s)"
printf "%-8s %-8s %-15s\n" "--------" "--------" "---------------"

for KEY in "${!AVG_SUM[@]}"; do
    TOOL=$(echo "$KEY" | cut -d'-' -f1)
    MODE=$(echo "$KEY" | cut -d'-' -f2)
    AVG=$(echo "${AVG_SUM[$KEY]} / ${AVG_COUNT[$KEY]}" | bc -l | xargs printf "%.2f")
    printf "%-8s %-8s %-15s\n" "$TOOL" "$MODE" "$AVG"
done

echo -e "\n${GREEN}All tests finished!${RESET}"
