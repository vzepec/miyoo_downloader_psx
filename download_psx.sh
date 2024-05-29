#!/bin/sh

# Select source
while true; do
    echo -n "Select European sources (e) or USA sources (u): "
    read -r choice
    if [ "$choice" = "e" ] || [ "$choice" = "u" ]; then
        break
    else
        echo "Invalid choice. Please enter 'e' for European sources or 'u' for USA sources."
    fi
done

# Set BASE_URL based on choice
BASE_URL=$(if [ "$choice" = "e" ]; then echo "https://archive.org/download/chd_psx_eur/CHD-PSX-EUR/"; else echo "https://archive.org/download/chd_psx/CHD-PSX-USA/"; fi)

# Download file list
wget -q -O - "$BASE_URL" | grep -o 'href="[^\"]*\.chd"' | sed 's/ /%20/g' | sed 's/href="//' | sed 's/"//' > file_list.txt

show_page() {
    clear
    local page="$1"
    local start=$((page * 10))
    local end=$((start + 10))
    local i=0
    local line

    echo "Page $((page + 1)):"
    echo "------"
    echo ""
    while IFS= read -r line && [ $i -lt $end ]; do
        i=$((i + 1))
        if [ $i -gt $start ]; then
            # Replace invalid chars
            file_name=$(echo "$line" | sed -e 's/%20/ /g' -e 's/%28/(/g' -e 's/%29/)/g' -e 's/%2C/,/g' -e 's/%26/\&/g' -e 's/%27/'"'"'/g' -e 's/%21/!/g' -e 's/%25/%/g')
            # Trunc name if is so long
            if [ ${#file_name} -gt 45 ]; then
                file_name="${file_name:0:45}..."  # Cut at 45 chars and add "..."
            fi
            echo -e "\e[32m$i. $file_name\e[0m"
        fi
    done < file_list.txt
    echo ""
    echo "------------------"
    echo "n. Next page"
    echo "p. Previous page"
    echo "q. Quit"
}


download_file() {
    local index="$1"
    local i=0
    local line
    local file_name

    while IFS= read -r line && [ $i -le $index ]; do
        if [ $i -eq $index ]; then
            # Download selected file
            wget -P "../Roms/PS/" "$BASE_URL$line"

            # Replace invalid chars from the name
            file_name=$(echo "$line" | sed -e 's/%20/ /g' -e 's/%28/(/g' -e 's/%29/)/g' -e 's/%2C/,/g' -e 's/%26/\&/g' -e 's/%27/'"'"'/g' -e 's/%21/!/g' -e 's/%25/%/g')

            # Rename file with the new file name
            mv "../Roms/PS/$line" "../Roms/PS/$file_name"
            echo "Download complete: ../Roms/PS/$file_name"
            break
        fi
        i=$((i + 1))
    done < file_list.txt
}


page=0
while true; do
    show_page "$page"
    echo -n "Select a file to download (number), navigate (n/p), or quit (q): "
    read -r choice

    if echo "$choice" | grep -q '^[0-9]\+$'; then
        index=$((choice - 1))
        echo "Downloading..."
        download_file "$index"
    elif [ "$choice" = "n" ]; then
        page=$((page + 1))
        if ! tail -n +$((page * 10 + 1)) file_list.txt | head -n 1 >/dev/null 2>&1; then
            page=$((page - 1))
            echo "No more pages."
        fi
    elif [ "$choice" = "p" ]; then
        if [ "$page" -gt 0 ]; then
            page=$((page - 1))
        else
            echo "Already at the first page."
        fi
    elif [ "$choice" = "q" ]; then
        break
    else
        echo "Invalid choice."
    fi
done

# Cleanup
rm file_list.txt
