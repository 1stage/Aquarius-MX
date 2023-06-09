@SET DEF1=
@IF NOT "%1"=="" SET DEF1=-D%1
zmac.exe --zmac -e --nmnv --oo cim,lst -L -n -I include %DEF1% aqubasic.asm
