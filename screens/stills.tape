Source common.tape
Output scratch.gif
Set Height 1200
Hide
Type ". ./setup.sh"
Enter
Sleep 1s
Show
Sleep 800ms
Type "kirisute --info roms/racer.nds"
Enter
Sleep 3s
Screenshot info.png
Sleep 1s
Hide
Type "clear"
Enter
Show
Sleep 800ms
Type "kirisute --dry-run roms"
Enter
Sleep 4s
Screenshot dry-run.png
Sleep 1s
Hide
Type "clear"
Enter
Show
Sleep 800ms
Type "kirisute rename roms/adventure.nds"
Enter
Sleep 3s
Enter
Sleep 3s
Screenshot rename.png
Hide
Type "clear"
Enter
Show
Sleep 800ms
Type "kirisute compress psp/game.iso"
Enter
Sleep 3s
Enter
Sleep 15s
Screenshot compress.png
Hide
Type "clear"
Enter
Show
Sleep 800ms
Type "kirisute notes.txt"
Enter
Sleep 2s
Screenshot error.png
Sleep 1s
Hide
Type "clear"
Enter
Show
Sleep 800ms
Type "kirisute doctor"
Enter
Sleep 10s
Screenshot doctor.png
Sleep 1s
Hide
Type "clear"
Enter
Show
Sleep 800ms
Type "for t in kodougu catppuccin-mocha dracula nord gruvbox tokyo-night; do kirisute --theme $t version; done"
Enter
Sleep 8s
Screenshot themes.png
Sleep 1s
Sleep 1s
