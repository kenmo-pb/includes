# PureBasic Includes
A variety of useful Include Files for PureBasic projects

*All files are "EnableExplicit safe" and "Multiple-include safe"*

## [ImproveGadgets.pbi](ImproveGadgets.pbi)
Various small improvements to native PB gadgets
+ Windows only (compiles but has no effect on other OS)
+ ASCII/Unicode safe
+ Demo included
+ **StringGadget**, **ComboBoxGadget**: adds Ctrl+Backspace word deletion
+ **ContainerGadget**: reduces resize flickering by disabling some redraw events
+ **WebGadget**: Disables annoying "Script Error" popups

## [JSON.pbi](JSON.pbi)
Basic JSON support (read/write/parse/modify) before PureBasic added its own JSON library in 5.30
+ Windows/Linux/Mac
+ ASCII/Unicode safe
+ Demo included
+ **PB 5.30+**: Compilation is disabled (conflicts with PB's JSON commands)
+ **PB 5.20+**: Compiles as a Module (`UseModule JSON`)
+ **Before 5.20**: Compiles as included procedures

## [Winamp.pbi](Winamp.pbi)
Gives you basic access and control of Winamp's playback status

**Note**: This is for controlling Winamp from an external program, not for writing Winamp plugin DLLs
+ Windows only
+ ASCII/Unicode safe
