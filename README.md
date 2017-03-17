# PureBasic Includes
A variety of useful Include Files for PureBasic projects

Most of these come from my own projects, others were written for the PB forums, and some were never used at all. Feel free to borrow, modify, and share. No credit required.

*All files are "EnableExplicit safe" and "Multiple-include safe"*

## [7Zip.pbi](7Zip.pbi)
This provides an interface to the basic archive functions of 7-Zip - creation, examination, and extraction - with password support.
+ Windows only
+ ASCII/Unicode safe
+ Demo included
+ **[7-Zip commandline version](http://www.7-zip.org/download.html) (7za.exe) is required**

## [common.pbi](common.pbi)
Lots of handy constants, macros, and procedures for common tasks related to: data types, time and date, dialogs, gadgets, file I/O, file paths, drawing, images, strings, etc.
+ Windows/Linux/Mac
+ ASCII/Unicode safe
+ **[os.pbi](os.pbi) is also required**

## [DropdownButtonGadget.pbi](DropdownButtonGadget.pbi)
Custom canvas-based button which provides one clickable main action, plus a popup menu for secondary actions. Simulates a widget seen in some Microsoft programs.
+ Windows/Linux/Mac
+ ASCII/Unicode safe
+ Demo included

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

## [os.pbi](os.pbi)
Low-overhead code (constants and macros, no procedures) to simplify cross-platform programming

Convenient for handling different OS, filesystems, subsystems, ASCII vs. Unicode, x86 vs. x64
+ Windows/Linux/Mac
+ ASCII/Unicode safe

## [Winamp.pbi](Winamp.pbi)
Gives you basic access and control of Winamp's playback status

**Note**: This is for controlling Winamp from an external program, not for writing Winamp plugin DLLs
+ Windows only
+ ASCII/Unicode safe
