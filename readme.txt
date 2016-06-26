Introduction
This is a console application that dump basic volume information from a disk object. The object can be an image file or a win32 physical drive device such as \\.\PhysicalDriveN. The information it retrieves is which volumes exist, their offset and size, and if they are NTFS or not.

Syntax
PartDump.exe /ImageFilePath:FullPath\ImageFilename /OutputPath:FullPath /LocalDiskPath:FullDevicePath /WriteInfo:[0|1]

Explanation of parameters
/ImageFilePath:
The full path and filename of an image file to evaluate. Use this one or /LocalDiskPath.
/LocalDiskPath:
The physical drive object to evaluate. Use this one or /ImageFilePath.
/OutputPath:
The output path to write the txt file. Optional. If omitted, then extract path defaults to program directory.
/WriteInfo:
An optional boolean flag for writing a file with some disk information into DiskInfo.txt in the defined output directory.

The /WriteInfo: parameter can be useful when scripting.


Sample usage

Example for dumping to console only, the volume information from diskimage.dd..
PartDump.exe /ImageFilePath:e:\temp\diskimage.dd

Example for dumping to console and to e:\temp\DiskInfo.txt, the volume information from diskimage.dd.
PartDump.exe /ImageFilePath:e:\temp\diskimage.dd /OutputPath:e:\temp /WriteInfo:1

Example for dumping to console only, the volume information from \\.\PhysicalDrive0.
PartDump.exe /LocalDiskPath:\\.\PhysicalDrive0

Example for dumping to console and to e:\temp\DiskInfo.txt, the volume information from \\.\PhysicalDrive1.
PartDump.exe /LocalDiskPath:\\.\PhysicalDrive1 /WriteInfo:1