echo "if it errors usage: LCFO output.ozex input.lua <OZLE/OZEX>"
echo "OZLE format is Lite and OZEX format is Normal!"
luac -o bin.luac $2
echo -n $3 > $1
cat bin.luac >> $1
echo "Compiled!"
