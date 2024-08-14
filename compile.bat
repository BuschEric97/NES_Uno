..\..\cc65\bin\ca65 .\src\main.asm -o .\bin\game.o -t nes -g
..\..\cc65\bin\ld65 .\bin\game.o -C .\game.cfg -o .\bin\game.nes -m .\bin\game.map.txt --dbgfile .\bin\game.nes.dbg