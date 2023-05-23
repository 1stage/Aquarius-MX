files
=====

AQ_MX_RRU.PLD source code for use with WinCUPL http://www.atmel.com/tools/wincupl.aspx

AQ_MX_RRU.docx WinCUPL listing file (includes expanded logic terms, fuse map, chip pinouts)

AQ_MX_RRU.jed JEDEC file used to program GAL


Explanation of PLD Source Code
==============================

Syntax:-  

  ! = negate/invert signal
  # = logical OR
  & = logical AND

Pin assignment example:-

PIN 17 = !RAME ; 

  Designates pin 17 as variable 'RAME'. '!' = inverted (active low) at pin.  


Equations:-

RAME = !MREQ&(!RD#!WR)&(((A15&!A14&!LATCH)#(!A15&A14))#(A15&A14&LATCH&!RD));

The 32k static RAM is selected when MREQ is low and RD or WR is low, normally in the address range $4000-$BFFF. When the ROM remapping latch is set the lower 16k still has full read/write access at $4000-$7FFF, but the upper 16k is write-protected and accessed at $C000-$FFFF.  


LATCH = LATR&((!IORQ&!WR&!A7&!A6)#LATCH);

If LATR is low then the ROM remapping latch is forced into reset. This occurs on power up when the reset generator pulls LATR low. When LATR is released the latch can be set by writing to I/O address $00-$3F. Once set it remains so until the next power up, because the output is fed back into the input which holds it high (LATCH = ... OR LATCH). 

  
ROME = !MREQ&(!RD#!WR)&A15&A14&!LATCH; 

In this revision, the ROM device has been changed from a Winbond W27C512 256k (16kb x 4) EPROM to a Dallas DS1244Y Real-Time Clock (RTC) with 32k (16kb x 2) of NVRAM. The device functions in the same way as the ROM, but the Write Enable line has been added to the logic to allow access to the Phantom Clock functions. The ROM is enabled when reading memory addresses $C000-$FFFF, but only when the latch is reset. When the latch is set the ROM is disabled.


RA14 = A14&!(A15&LATCH);

RAM address line A14 normally passes straight through, but when the latch is set A14 is forced low when A15 is high. This causes the upper 16k to be addressed at $C000-$FFFF.
