#!/bin/sh

EUR_SOURCE='https://archive.org/download/chd_psx_eur/CHD-PSX-EUR/'
USA_SOURCE='https://archive.org/download/chd_psx/CHD-PSX-USA/'

# Define a function to select source and download file list
select_source_and_download() {
    while true; do
        echo -n "Select European sources (e); USA sources (u) or both (b): "
        read -r choice
        if [ "$choice" = "e" ] || [ "$choice" = "u" ] || [ "$choice" = "b" ]; then
            break
        else
            echo "Invalid choice. Please enter 'e' for European sources, 'u' for USA sources or 'b' for both"
        fi
    done

    if [ "$choice" = "e" ]; then
        BASE_URL="$EUR_SOURCE"
        wget -q -O - "$BASE_URL" | grep -o 'href="[^\"]*\.chd"' | sed 's/ /%20/g' | sed 's/href="//' | sed 's/"//' > file_list.txt
    elif [ "$choice" = "u" ]; then
        BASE_URL="$USA_SOURCE"
        wget -q -O - "$BASE_URL" | grep -o 'href="[^\"]*\.chd"' | sed 's/ /%20/g' | sed 's/href="//' | sed 's/"//' > file_list.txt
    elif [ "$choice" = "b" ]; then
        BASE_URL="$EUR_SOURCE"
        BASE_URL2="$USA_SOURCE"
        wget -q -O - "$BASE_URL" | grep -o 'href="[^\"]*\.chd"' | sed 's/ /%20/g' | sed 's/href="//' | sed 's/"//' > file_list_2.txt
        wget -q -O - "$BASE_URL2" | grep -o 'href="[^\"]*\.chd"' | sed 's/ /%20/g' | sed 's/href="//' | sed 's/"//' > file_list_3.txt
        cat file_list_2.txt >> file_list.txt
        cat file_list_3.txt >> file_list.txt
    fi

    sort -u file_list.txt -o file_list.txt
}

select_source_and_download

show_page() {
    clear
    local page="$1"
    local start=$((page * 10))
    local end=$((start + 10))
    local i=0
    local line
    local total_files=$(wc -l < file_list.txt)
    echo "Page $((page + 1)):"
    echo "Total files: $total_files"
    echo "------------------"
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
    local BASE_URL

    while IFS= read -r line && [ $i -le $index ]; do
        if [ $i -eq $index ]; then
            # Search for the selected file in file_list.txt
            if grep -q "$line" file_list2.txt; then
                BASE_URL="$EUR_SOURCE"
            elif grep -q "$line" file_list_3.txt; then
                BASE_URL="$USA_SOURCE"
            else
                echo "File not found"
                break
            fi

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
    echo -n "Select a file to download (number), navigate (n/p), menu selector (m) or quit (q): "
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
    elif [ "$choice" = "m" ]; then
        select_source_and_download
        page=0
    elif [ "$choice" = "q" ]; then
        break
    else
        echo "Invalid choice."
    fi
done

# Cleanup
rm file_list.txt
rm -f file_list_2.txt
