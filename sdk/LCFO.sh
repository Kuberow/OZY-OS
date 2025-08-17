echo "if it errors usage: LCFO output.ozex input.lua"
luac -o bin.luac $2
echo -n "OZEX" > $1
cat bin.luac >> $1
echo "Compiled!"
