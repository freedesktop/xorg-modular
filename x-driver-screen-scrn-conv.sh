#!/bin/sh

find . -name \*.[ch] -exec sed -i -e's/xf86Screens\[\([a-z].*\)->myNum\]/xf86ScreenToScrn(\1)/g' {} \;
find . -name \*.[ch] -exec sed -i -e's/screenInfo.screens\[\([a-z].*\)->scrnIndex\]/xf86ScrnToScreen(\1)/g' {} \;
