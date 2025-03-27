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

$iso = Get-DiskImage -ImagePath $iso_file

if ($info)
{
"- Image details:"
  $iso | fl
}

if ($cleanup)
{
"- Cleaning up virtual drives mounted from the image:"
  $init_vol  = $iso | Get-Volume
  $init_vol | ft
}

"."
