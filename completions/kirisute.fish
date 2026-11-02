complete -c kirisute -n __fish_use_subcommand -a doctor -d 'check the tools kirisute needs'
complete -c kirisute -n __fish_use_subcommand -a version -d 'print the version'
complete -c kirisute -n __fish_use_subcommand -a help -d 'print usage'

complete -c kirisute -l dry-run -d 'list what would be trimmed and change nothing'
complete -c kirisute -l info -d "print each ROM's header and change nothing"
complete -c kirisute -l verify -d 'trim only a ROM whose padding holds nothing but 00 or FF'
complete -c kirisute -l no-verify -d 'trim whatever the padding holds'
complete -c kirisute -l backup -d 'keep each original as <rom>.bak'
complete -c kirisute -l no-backup -d 'keep no copy of the original'
complete -c kirisute -l recursive -d 'look for .nds files in every subfolder too'
complete -c kirisute -l json -d 'print the result as one JSON object, for scripts'
