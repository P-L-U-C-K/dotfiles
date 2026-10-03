function update --wraps='doas apk update && doas apk upgrade' --description 'alias update=doas apk update && doas apk upgrade'
    doas apk update && doas apk upgrade $argv
end
