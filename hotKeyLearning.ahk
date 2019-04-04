; AutoHotkey Version: 1.x
; Language:       English
; Platform:       Win9x/NT
; Author:         Avi
; function: On a given schedule, will pop up question prompts and/or pictures and then shows answers from files that the user populates.

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


;get user input for which pack to study
packageList=| ;this effectively gives a defalt value to the first folder
Loop, Files, %A_WorkingDir%\*, D, R
{
	packageList=%A_LoopFileName%|%packageList%
}

Gui, Add, text, , Select a package to study:
Gui, Add, DropDownList, vpack, %packageList%
Gui, Add, text, , Enter numer of minutes in between prompts:
Gui, Add, Edit, number vpromptDelay, 10
Gui, Add, UpDown, Range1-60, 5
Gui, Add, Button, Default gPackageSelect, &Go!
Gui, Show
breaker=0
Loop{
	if (breaker)
		break
	sleep, 10
}

; Create the item and "learned" array, initially empty:
itemList := Object()
learned := Object()
i:=0
Loop, Read, %A_WorkingDir%\%pack%\%pack%.txt ; This loop retrieves each line from the file, one at a time.
{  
  i+=1
  itemList[i]:=A_LoopReadLine ; Append this line to the array.
  learned[i]:=0
}

promptDelay:=promptDelay*3600
Loop { ;main loop
	skipWait:=false
	Gosub, nextItem
	loop %promptDelay% {
		if (skipWait=false) { ;must be inside loop so we can break
			sleep, 1
		}
	}  
}
Return

PackageSelect:
{
Gui, Submit
breaker=1
}
Return

nextItem:
{
	Gui, Destroy ;remove last popup if it still exists
	Loop { ;find a random line, but not one marked as learned
		random, rand, 1, i
		if (learned[rand] != 1){
			line := itemList[rand]
			break
		}
	}
	Gosub, ParseItem
	Gosub, PromptPop
}
Return

ParseItem:
{
	
	;first get the name of the picture folder, if there is one, then remove it from the remaining line
	pos1:=InStr(line,"<")
	pos2:=InStr(line,">")
	len:=pos2-pos1
	folderName:=SubStr(line, pos1+1, len-1) 
	line1:=SubStr(line, 1, pos1-1)
	line2:=SubStr(line, pos2+1)
	line=%line1%%line2%
	
	;now set the prompt, definition variables
	prompt := ""
	definition := ""
	p:=1
	Loop, parse, line, -
	{
		if (p=1){
			prompt=%A_LoopField%
			p:=p+1
		}
		else if (p=2){
			definition =%A_LoopField%
			p:=p+1
		}
		else definition=%definition%-%A_LoopField% ;account got additional dashes (delimiting character) in the definition.
	}
	
	;finally, load up the pictures from the folder, if any
	Pics := []
	numPics=0
	Loop, Files, %A_WorkingDir%\%pack%\%folderName%\*.jpg, R
	{
		 numPics:=numPics+1
		 Pics.Push(LoadPicture(A_LoopFileFullPath))
	} 
}
return

PromptPop:
{
	Gui, New, +Resize +MinSize400x, Learn Nature
	Gui, Add, Button, Default gDefPop, &Show Answer
	Gui, Add, text, , %prompt%
	Gui, Add, Pic, w400 h-1 vPic +Border, % "HBITMAP:*" Pics[1]
	ypos:=25
	currentPic=1 ;the picture that is currently enlarged
	j:=1 ;so we start with second picture, since first is already loaded
	Loop {
		j:=j+1
		if (j>numPics) 
			break
		Gui, Add, Pic, v%j% gSwapPic x450 y%ypos% w100 h100, % "HBITMAP:*" Pics[j]
		ypos:=ypos+120
	}
	Gui, Show
}
return
	
SwapPic:
{
	currentPic:=A_GuiControl ;the picture that is currently enlarged
	Gui, Destroy
	Gui, New, +Resize +MinSize500x, Learn Nature
	Gui, Add, Button, Default gDefPop, &Show Answer
	Gui, Add, text, , %prompt%
	Gui, Add, Pic, w400 h-1 vPic +Border, % "HBITMAP:*" Pics[currentPic]
	ypos:=25
	j:=0
	Loop {
		j:=j+1
		if (j>numPics) 
			break
		if (j!=currentPic)
		{
			Gui, Add, Pic, v%j% gSwapPic x450 y%ypos% w100 h100, % "HBITMAP:*" Pics[j]
			ypos:=ypos+120
		}
	}
	Gui, Show
}
return
	
DefPop:
{
		MsgBox,4,, %definition% `n `n `n `nMark as "learned"?
		IfMsgBox Yes
			{
			learned[rand]:=1 ; mark as learned so it doesn't repeat
			Gui, Destroy
			skipWait=true
			}
		else
			{
			Gui, Destroy
			
			}
}
return


!n:: ;alt+n skips the wait time until next word displays
  skipWait:=true
Return



