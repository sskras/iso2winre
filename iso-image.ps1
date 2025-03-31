#! /usr/bin/env -S powershell -NoProfile -File

# SPDX-License-Identifier: BlueOak-1.0.0
# SPDX-FileCopyrightText: 2025 Saulius Krasuckas <saulius2_at_ar-fi_point_lt> | sskras

# ISO image helper tool for:
#
# - checking image details,
# - mounting an image,
# - cleaning up virtual drives mounted from an ISO image.

param
(
  [switch] $info,
  [switch] $cleanup,
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
  ""
  " * initial volume:"
  $init_vol  = $drive | Get-Volume
  $init_vol | ft

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

    $drive = Dismount-DiskImage -DevicePath $drive.DevicePath
    $drive | fl
  }
}

"."
