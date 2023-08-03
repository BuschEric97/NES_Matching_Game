..\..\cc65\bin\ca65 main.asm -o game.o -t nes -g
..\..\cc65\bin\ld65 game.o -C game.cfg -o game.nes -m game.map.txt --dbgfile game.nes.dbg