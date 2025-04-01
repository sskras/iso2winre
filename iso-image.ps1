#! /usr/bin/env -S powershell -NoProfile -File

# SPDX-License-Identifier: BlueOak-1.0.0
# SPDX-FileCopyrightText: 2025 Saulius Krasuckas <saulius2_at_ar-fi_point_lt> | sskras

# ISO image helper tool for:
#
# + checking image details,
# - mounting an image,
# + cleaning up virtual drives mounted from an ISO image.

param
(
  [switch] $info,
  [switch] $cleanup,
  [switch] $mount,
  [switch] $list,
  [switch] $EOA         # End of Arguments (a virtual argument, not intended to be actually used)
)
# Via: https://www.red-gate.com/simple-talk/sysadmin/powershell/how-to-use-parameters-in-powershell-part-ii/#boolean-vs-switch

$iso_file = $args

"- Processing the image:"
""
Write-Output $iso_file
""

if ($info)
{
  $drive = Get-DiskImage -ImagePath $iso_file

  "- Image details:"
  $drive | fl
}

if ($cleanup)
{
  $drive = Get-DiskImage -ImagePath $iso_file

  "- Cleaning up virtual drives mounted from the image:"

  $init_vol  = $drive | Get-Volume
  if ($init_vol)
  {
    $all_vols = Get-Volume -FileSystemLabel $init_vol.FileSystemLabel
    $all_vols | ft
  }
  else { "" }

  " * found device:"
  $drive | fl

  if (!$drive.Attached)
  {
    Write-Output "  Nothing left to dismount."
  }

  while ($drive.DevicePath)
  {
    " * dismounting device path: " + $drive.DevicePath
    ""
    $vol = $drive | Get-Volume
    $letter = $vol.DriveLetter
    $vol_path = $vol.Path

    if ($letter)
    {
      $letter = " (${letter}:)"
    }
    "   ${vol_path}" + ${letter}

    # TODO: Loop the following dismount using the same $drive.DevicePath until it starts failing.
    # (Maybe via PowerShell exceptions/errors handling)
    #
    # This sometimes is needed because sometimes (esp. after multipe runs of RemoveDrive_x64)
    # OS gets multiple volumes mounted under the same \\.\CDROMx drive.

    $drive = Dismount-DiskImage -DevicePath $drive.DevicePath
    $drive | fl
  }
}

if ($mount)
{
  "- Initial optical drives"
  Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 5' | Select-Object DeviceID, Size, VolumeName, Description | ft

  "- Details of the image"
  Get-DiskImage -ImagePath ${iso_file} | fl

  $letters_before = (Get-Volume).DriveLetter

  "- Mount the ISO image"
  Mount-DiskImage -ImagePath ${iso_file} -PassThru

  "- Final optical drives"
  Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 5' | Select-Object DeviceID, Size, VolumeName, Description | ft

  $letters_after = (Get-Volume).DriveLetter

  "- Drive letters diff"
  Compare-Object ($letters_before | Select-Object) ($letters_after | Select-Object) | ft
}

if ($list)
{
  Get-Volume | ft
  Get-WmiObject -Class Win32_Volume | Select-Object Label, FileSystem, DriveLetter, DeviceID | ft
}

"."
