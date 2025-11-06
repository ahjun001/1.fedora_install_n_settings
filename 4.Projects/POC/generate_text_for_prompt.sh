find . -path "./.git" -prune -o -type f -print | xargs cat > ../text_for_prompt.txt
