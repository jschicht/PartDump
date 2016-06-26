#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\..\..\Program Files (x86)\autoit-v3.3.14.2\Icons\au3.ico
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Dump disk partition info
#AutoIt3Wrapper_Res_Description=Dump disk partition info
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Joakim Schicht
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Include <WinAPIEx.au3>
;#include <Array.au3>
;
; https://github.com/jschicht
;
Global $TargetImageFile, $Entries, $IsShadowCopy=False, $IsPhysicalDrive=False, $IsImage=False, $hDisk, $OutPutPath=@ScriptDir, $WritePartInfo=0
Global $VolumesArray[1][3]

$VolumesArray[0][0] = "Type"
$VolumesArray[0][1] = "ByteOffset"
$VolumesArray[0][2] = "Sectors"

ConsoleWrite("PartDump v1.0.0.0" & @CRLF & @CRLF)

_GetInputParams()
;_ArrayDisplay($VolumesArray,"$VolumesArray")

If $WritePartInfo Then
	$hFile = FileOpen($OutPutPath & "\DiskInfo.txt",2)
	FileWriteLine($hFile,"Type,ByteOffset,Sectors")
EndIf

$HighestVal0 = UBound($VolumesArray)
$HighestVal0 = StringLen($HighestVal0)
$NoStr = "No"
If StringLen($NoStr) < $HighestVal0 Then $NoStr = _AlignString($NoStr,$HighestVal0+2,1)

$HighestVal1 = _ArrayMax2($VolumesArray,0)
If @error then
	ConsoleWrite("Error: Unexpected error when resolving higest value in array: " & @error & @CRLF)
	Exit
EndIf
$TypeStr = $VolumesArray[0][0];"Type"
If StringLen($TypeStr) < $HighestVal1 Then $TypeStr = _AlignString($TypeStr,$HighestVal1+2,1)

$HighestVal2 = _ArrayMax2($VolumesArray,1)
If @error then
	ConsoleWrite("Error: Unexpected error when resolving higest value in array: " & @error & @CRLF)
	Exit
EndIf
$ByteOffsetStr = $VolumesArray[0][1];"ByteOffset"
If StringLen($ByteOffsetStr) < $HighestVal2 Then $ByteOffsetStr = _AlignString($ByteOffsetStr,$HighestVal2+2,1)

$HighestVal3 = _ArrayMax2($VolumesArray,2)
If @error then
	ConsoleWrite("Error: Unexpected error when resolving higest value in array: " & @error & @CRLF)
	Exit
EndIf
$SectorsStr = $VolumesArray[0][2];"Sectors"
If StringLen($SectorsStr) < $HighestVal3 Then $SectorsStr = _AlignString($SectorsStr,$HighestVal3+2,1)

ConsoleWrite($NoStr & "|" & $TypeStr & "|" & $ByteOffsetStr & "|" & $SectorsStr & @CRLF)
For $i = 1 To UBound($VolumesArray)-1
	;ConsoleWrite($VolumesArray[$i][0]&","&$VolumesArray[$i][1]&","&$VolumesArray[$i][2] & @CRLF)
	$AlignedSizeVal0 = _AlignString($i,$HighestVal0,1)
	$AlignedSizeVal1 = _AlignString($VolumesArray[$i][0],$HighestVal1,1)
	$AlignedSizeVal2 = _AlignString($VolumesArray[$i][1],$HighestVal2,0)
	$AlignedSizeVal3 = _AlignString($VolumesArray[$i][2],$HighestVal3,0)
	$TextOut = $AlignedSizeVal0 & " | " & $AlignedSizeVal1 & " | " & $AlignedSizeVal2 & " | " & $AlignedSizeVal3
	ConsoleWrite($TextOut & @CRLF)
	If $WritePartInfo Then
		FileWriteLine($hFile,$VolumesArray[$i][0]&","&$VolumesArray[$i][1]&","&$VolumesArray[$i][2])
	EndIf
Next
If $WritePartInfo Then
	FileClose($hFile)
EndIf

Func _AlignString($input,$length,$LeftAlign)
	While 1
		If StringLen($input)=$length Then ExitLoop
		If $LeftAlign Then
			$input = $input&" "
		Else
			$input = " "&$input
		EndIf
	WEnd
	Return $input
EndFunc

Func _ArrayMax2($Array,$Column)
	Local $MaxLength=0
	If Not IsArray($Array) Then Return SetError(1)
	For $i = 1 To UBound($Array)-1
		If StringLen($Array[$i][$Column]) > $MaxLength Then
			$MaxLength = StringLen($Array[$i][$Column])
		EndIf
	Next
	Return $MaxLength
EndFunc

Func _SwapEndian($iHex)
	Return StringMid(Binary(Dec($iHex,2)),3, StringLen($iHex))
EndFunc

Func _HexEncode($bInput)
    Local $tInput = DllStructCreate("byte[" & BinaryLen($bInput) & "]")
    DllStructSetData($tInput, 1, $bInput)
    Local $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", 0, _
            "dword*", 0)

    If @error Or Not $a_iCall[0] Then
        Return SetError(1, 0, "")
    EndIf

    Local $iSize = $a_iCall[5]
    Local $tOut = DllStructCreate("char[" & $iSize & "]")

    $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", DllStructGetPtr($tOut), _
            "dword*", $iSize)

    If @error Or Not $a_iCall[0] Then
        Return SetError(2, 0, "")
    EndIf

    Return SetError(0, 0, DllStructGetData($tOut, 1))

EndFunc  ;==>_HexEncode

Func _GetInputParams()
	Local $TmpOutPath, $TmpImageFile, $TmpLocalDisk, $TmpWritePartInfo
	For $i = 1 To $cmdline[0]
		;ConsoleWrite("Param " & $i & ": " & $cmdline[$i] & @CRLF)
		If StringLeft($cmdline[$i],12) = "/OutputPath:" Then $TmpOutPath = StringMid($cmdline[$i],13)
		If StringLeft($cmdline[$i],15) = "/ImageFilePath:" Then $TmpImageFile = StringMid($cmdline[$i],16)
		If StringLeft($cmdline[$i],15) = "/LocalDiskPath:" Then $TmpLocalDisk = StringMid($cmdline[$i],16)
		If StringLeft($cmdline[$i],11) = "/WriteInfo:" Then $TmpWritePartInfo = StringMid($cmdline[$i],12)
	Next
	If $cmdline[0] = 0 Then
		_PrintHelp()
		Exit
	EndIf

	If StringLen($TmpOutPath) > 0 Then
		If FileExists($TmpOutPath) Then
			$OutPutPath = $TmpOutPath
		Else
			$OutPutPath = @ScriptDir
		EndIf
	Else
		$OutPutPath = @ScriptDir
	EndIf

	If StringLen($TmpWritePartInfo) > 0 Then
		Select
			Case $TmpWritePartInfo <> 0 And $TmpWritePartInfo <> 1
				ConsoleWrite("Error: WriteInfo had unexpected value. Skipping it." & @CRLF)
				$WritePartInfo = 0
			Case $TmpWritePartInfo = 0
				$WritePartInfo = 0
			Case $TmpWritePartInfo = 1
				$WritePartInfo = 1
		EndSelect
	EndIf

	If StringLen($TmpImageFile) > 0 And StringLen($TmpLocalDisk) > 0 Then
		ConsoleWrite("Error: Can only use one of ImageFilePath or LocalDiskPath param" & @CRLF)
		Exit
	EndIf

	If StringLen($TmpImageFile) > 0 Then
		If FileExists($TmpImageFile) Then
			$IsImage=1
			$Check = _Start($TmpImageFile)
		Else
			ConsoleWrite("Error: Image file not found: " & $TmpImageFile & @CRLF)
			Exit
		EndIf
	EndIf

	If StringLen($TmpLocalDisk) > 0 Then
		If StringInStr($TmpLocalDisk,":") Or StringInStr($TmpLocalDisk,"PhysicalDrive")=0  Then
			ConsoleWrite("Error: Invalid physical drive object: " & $TmpLocalDisk & @CRLF)
			Exit
		EndIf
		If Not (StringLeft($TmpLocalDisk,4) = "\\.\") Then
			$TmpLocalDisk = "\\.\" & $TmpLocalDisk
		EndIf
		Local $hImage = _WinAPI_CreateFile($TmpLocalDisk,2,2,7)
		If Not $hImage Then
			ConsoleWrite("Error: Accessing " & $TmpLocalDisk & " failed: " & @CRLF)
			ConsoleWrite(_WinAPI_GetLastErrorMessage() & @CRLF)
			Exit
		EndIf
		_WinAPI_CloseHandle($hImage)
		$IsPhysicalDrive=1
		$Check = _Start($TmpLocalDisk)
	EndIf

	If $IsPhysicalDrive=0 And $IsImage=0 Then
		_PrintHelp()
		Exit
	EndIf
EndFunc

Func _PrintHelp()
	ConsoleWrite("Syntax:" & @CRLF)
	ConsoleWrite("PartDump.exe /ImageFilePath:FullPath\ImageFilename /OutputPath:FullPath /LocalDiskPath:FullDevicePath /WriteInfo:[0|1]" & @CRLF)
	ConsoleWrite("Examples:" & @CRLF)
	ConsoleWrite("PartDump.exe /ImageFilePath:e:\temp\diskimage.dd" & @CRLF)
	ConsoleWrite("PartDump.exe /ImageFilePath:e:\temp\diskimage.dd /OutputPath:e:\temp /WriteInfo:1" & @CRLF)
	ConsoleWrite("PartDump.exe /LocalDiskPath:\\.\PhysicalDrive0" & @CRLF)
	ConsoleWrite("PartDump.exe /LocalDiskPath:\\.\PhysicalDrive1 /WriteInfo:1" & @CRLF)
EndFunc

Func _Start($Target)
	Select
		Case $IsImage
			If Not FileExists($Target) Then
				ConsoleWrite("Error: Image file not found: " & $Target & @CRLF)
				Return
			EndIf
			$TargetImageFile = "\\.\"&$Target
			$Entries = ''
			_CheckMBR()
		Case $IsPhysicalDrive
			$TargetImageFile = $Target
			$Entries = ''
			_CheckMBR()
	EndSelect
EndFunc

Func _CheckMBR()
	Local $nbytes, $PartitionNumber, $PartitionEntry,$FilesystemDescriptor
	Local $StartingSector,$NumberOfSectors
	Local $hImage = _WinAPI_CreateFile($TargetImageFile,2,2,7)
	$tBuffer = DllStructCreate("byte[512]")
	Local $read = _WinAPI_ReadFile($hImage, DllStructGetPtr($tBuffer), 512, $nBytes)
	If $read = 0 Then Return ""
	Local $sector = DllStructGetData($tBuffer, 1)
;	ConsoleWrite(_HexEncode($sector) & @CRLF)
	For $PartitionNumber = 0 To 3
		$PartitionEntry = StringMid($sector,($PartitionNumber*32)+3+892,32)
		If $PartitionEntry = "00000000000000000000000000000000" Then ExitLoop ; No more entries
		$FilesystemDescriptor = StringMid($PartitionEntry,9,2)
		$StartingSector = Dec(_SwapEndian(StringMid($PartitionEntry,17,8)),2)
		$NumberOfSectors = Dec(_SwapEndian(StringMid($PartitionEntry,25,8)),2)
		If ($FilesystemDescriptor = "EE" and $StartingSector = 1 and $NumberOfSectors = 4294967295) Then ; A typical dummy partition to prevent overwriting of GPT data, also known as "protective MBR"
			_CheckGPT($hImage)
		ElseIf $FilesystemDescriptor = "05" Or $FilesystemDescriptor = "0F" Then ;Extended partition
			_CheckExtendedPartition($StartingSector, $hImage)
		Else
			If Not _TestNTFS($hImage, $StartingSector) Then
				ReDim $VolumesArray[UBound($VolumesArray)+1][3]
				$VolumesArray[UBound($VolumesArray)-1][0] = "Non-NTFS"
				$VolumesArray[UBound($VolumesArray)-1][1] = $StartingSector*512
				$VolumesArray[UBound($VolumesArray)-1][2] = $NumberOfSectors
				ContinueLoop
			Else
				$Entries &= _GenComboDescription($StartingSector,$NumberOfSectors)
			EndIf
		EndIf
    Next
	If $Entries = "" Then ;Also check if pure partition image (without mbr)
		$NtfsVolumeSize = _TestNTFS($hImage, 0)
		If $NtfsVolumeSize Then $Entries = _GenComboDescription(0,$NtfsVolumeSize)
	EndIf
	_WinAPI_CloseHandle($hImage)
EndFunc   ;==>_CheckMBR

Func _CheckGPT($hImage) ; Assume GPT to be present at sector 1, which is not fool proof
   ;Actually it is. While LBA1 may not be at sector 1 on the disk, it will always be there in an image.
   ConsoleWrite("_CheckGPT()" & @CRLF)
	Local $nbytes,$read,$sector,$GPTSignature,$StartLBA,$Processed=0,$FirstLBA,$LastLBA
	$tBuffer = DllStructCreate("byte[512]")
	$read = _WinAPI_ReadFile($hImage, DllStructGetPtr($tBuffer), 512, $nBytes)		;read second sector
	If $read = 0 Then Return ""
	$sector = DllStructGetData($tBuffer, 1)
	$GPTSignature = StringMid($sector,3,16)
	If $GPTSignature <> "4546492050415254" Then
		ConsoleWrite("Error: Could not find GPT signature: " & _HexEncode(StringMid($sector,3)) & @CRLF)
		Return
	EndIf
	$StartLBA = Dec(_SwapEndian(StringMid($sector,147,16)),2)
	$PartitionsInArray = Dec(_SwapEndian(StringMid($sector,163,8)),2)
	$PartitionEntrySize = Dec(_SwapEndian(StringMid($sector,171,8)),2)
	_WinAPI_SetFilePointerEx($hImage, $StartLBA*512, $FILE_BEGIN)
	$SizeNeeded = $PartitionsInArray*$PartitionEntrySize ;Set buffer size -> maximum number of partition entries that can fit in the array
	$tBuffer = DllStructCreate("byte[" & $SizeNeeded & "]")
	$read = _WinAPI_ReadFile($hImage, DllStructGetPtr($tBuffer), $SizeNeeded, $nBytes)
	If $read = 0 Then Return ""
	$sector = DllStructGetData($tBuffer, 1)
	Do
		$FirstLBA = Dec(_SwapEndian(StringMid($sector,67+($Processed*2),16)),2)
		$LastLBA = Dec(_SwapEndian(StringMid($sector,83+($Processed*2),16)),2)
		If $FirstLBA = 0 And $LastLBA = 0 Then ExitLoop ; No more entries
		$Processed += $PartitionEntrySize
		#cs
		If Not _TestNTFS($hImage, $FirstLBA) Then
			ContinueLoop ;Continue the loop if filesystem not NTFS
		EndIf
		$Entries &= _GenComboDescription($FirstLBA,$LastLBA-$FirstLBA)
		#ce
		If Not _TestNTFS($hImage, $FirstLBA) Then
			ReDim $VolumesArray[UBound($VolumesArray)+1][3]
			$VolumesArray[UBound($VolumesArray)-1][0] = "Non-NTFS"
			$VolumesArray[UBound($VolumesArray)-1][1] = $FirstLBA*512
			$VolumesArray[UBound($VolumesArray)-1][2] = $LastLBA-$FirstLBA
			ContinueLoop
		Else
			$Entries &= _GenComboDescription($FirstLBA,$LastLBA-$FirstLBA)
		EndIf
	Until $Processed >= $SizeNeeded
EndFunc   ;==>_CheckGPT

Func _CheckExtendedPartition($StartSector, $hImage)	;Extended partitions can only contain Logical Drives, but can be more than 4
	Local $nbytes,$read,$sector,$NextEntry=0,$StartingSector,$NumberOfSectors,$PartitionTable,$FilesystemDescriptor
	$tBuffer = DllStructCreate("byte[512]")
	While 1
		_WinAPI_SetFilePointerEx($hImage, ($StartSector + $NextEntry) * 512, $FILE_BEGIN)
		$read = _WinAPI_ReadFile($hImage, DllStructGetPtr($tBuffer), 512, $nBytes)
		If $read = 0 Then Return ""
		$sector = DllStructGetData($tBuffer, 1)
		;ConsoleWrite(_HexEncode($sector) & @CRLF)
		$PartitionTable = StringMid($sector,3+892,64)
		$FilesystemDescriptor = StringMid($PartitionTable,9,2)
		$StartingSector = $StartSector+$NextEntry+Dec(_SwapEndian(StringMid($PartitionTable,17,8)),2)
		$NumberOfSectors = Dec(_SwapEndian(StringMid($PartitionTable,25,8)),2)
		If $FilesystemDescriptor = "06" Or $FilesystemDescriptor = "07" Then
			If Not _TestNTFS($hImage, $StartingSector) Then
				ReDim $VolumesArray[UBound($VolumesArray)+1][3]
				$VolumesArray[UBound($VolumesArray)-1][0] = "Non-NTFS"
				$VolumesArray[UBound($VolumesArray)-1][1] = $StartingSector*512
				$VolumesArray[UBound($VolumesArray)-1][2] = $NumberOfSectors
			Else
				$Entries &= _GenComboDescription($StartingSector,$NumberOfSectors)
			EndIf
		ElseIf $FilesystemDescriptor <> "05" And $FilesystemDescriptor <> "0F" Then
			ReDim $VolumesArray[UBound($VolumesArray)+1][3]
			$VolumesArray[UBound($VolumesArray)-1][0] = "Non-NTFS"
			$VolumesArray[UBound($VolumesArray)-1][1] = $StartingSector*512
			$VolumesArray[UBound($VolumesArray)-1][2] = $NumberOfSectors
		EndIf
		If StringMid($PartitionTable,33) = "00000000000000000000000000000000" Then ExitLoop ; No more entries
		$NextEntry = Dec(_SwapEndian(StringMid($PartitionTable,49,8)),2)
	WEnd
EndFunc   ;==>_CheckExtendedPartition

Func _TestNTFS($hImage, $PartitionStartSector)
	Local $nbytes, $TotalSectors
	If $PartitionStartSector <> 0 Then
		_WinAPI_SetFilePointerEx($hImage, $PartitionStartSector*512, $FILE_BEGIN)
	Else
		_WinAPI_CloseHandle($hImage)
		$hImage = _WinAPI_CreateFile($TargetImageFile,2,2,7)
	EndIf
	$tBuffer = DllStructCreate("byte[512]")
	$read = _WinAPI_ReadFile($hImage, DllStructGetPtr($tBuffer), 512, $nBytes)
	If $read = 0 Then Return ""
	$sector = DllStructGetData($tBuffer, 1)
	$TestSig = StringMid($sector,9,8)
	$TotalSectors = Dec(_SwapEndian(StringMid($sector,83,8)),2)
	If $TestSig = "4E544653" Then
		ReDim $VolumesArray[UBound($VolumesArray)+1][3]
		$VolumesArray[UBound($VolumesArray)-1][0] = "NTFS"
		$VolumesArray[UBound($VolumesArray)-1][1] = $PartitionStartSector*512
		$VolumesArray[UBound($VolumesArray)-1][2] = $TotalSectors
		Return $TotalSectors		; Volume is NTFS
	EndIf
    Return 0
EndFunc   ;==>_TestNTFS

Func _GenComboDescription($StartSector,$SectorNumber)
	Return "Offset = " & $StartSector*512 & ": Volume size = " & Round(($SectorNumber*512)/1024/1024/1024,2) & " GB|"
EndFunc   ;==>_GenComboDescription


