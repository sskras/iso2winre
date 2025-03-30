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
Write-Output $iso_file
""

$drive = Get-DiskImage -ImagePath $iso_file

if ($info)
{
  "- Image details:"
  $drive | fl
}

if ($cleanup)
{
  "- Cleaning up virtual drives mounted from the image:"
  ""
  " * initial volume:"
  $init_vol  = $drive | Get-Volume
  $init_vol | ft

  " * next device path: " + $drive.DevicePath
  " * next device dismount: "
  $drive = Dismount-DiskImage -DevicePath $drive.DevicePath | fl
  $drive

  continue

  " * normalized path of the mounted ISO:"
  ""
  $drive = $init_vol | Get-DiskImage
  $drive.ImagePath
  ""
  " * found label:"
  ""
  $iso_label = $init_vol.FileSystemLabel
  $iso_label
  ""
  " * all volumes by the label:"
  $all_vols  = Get-Volume -FileSystemLabel $iso_label
  $all_vols | ft

  foreach ($vol in $all_vols)
  {
    $image = $vol | Get-DiskImage
    $img_path = $image.ImagePath
    ""
    if ($image.ImagePath -ne $drive.ImagePath)
    {
      "Skipping image with different paths: '${img_path}'"
      continue
    }
    " * dismounting volume " + $vol.Path
    Dismount-DiskImage -ImagePath $image.ImagePath | fl
  }
}

"- Finale image state:"
Get-DiskImage -ImagePath $drive.ImagePath | fl

"."
