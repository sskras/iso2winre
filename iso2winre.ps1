#! /usr/bin/env -S powershell -file

# SPDX-License-Identifier: BlueOak-1.0.0
# SPDX-FileCopyrightText: 2025 Saulius Krasuckas <saulius2_at_ar-fi_point_lt> | sskras

# - Mount a Windows Vista+ ISO image,
# - then mount the inner `INSTALL.{ESD,WIM}`
# - and access the `WinRE.wim` image stored there.

param
(
  [string] $iso_full,    # Assign the ISO path name by default.
                         # no need to write `-iso_full ...`, plain `...` on the cmd-line works too.
  [string] $to,          # The output dir to store subdir with WinRE files (by default it's current dir).
  [switch] $interact,    # Interact with the both temporary mounted images (ISO + WIM/ESD) before unmounting.
  [switch] $EOA          # End of Arguments.
)

if (!$iso_full)
{
  "No ISO file given."
  exit 1
}

if (!$to) { $to = "." }

"- Mount the ISO image"
$drive = Mount-DiskImage -ImagePath ${iso_full} -PassThru
$drive | fl

"- Get the volume"
$vol = $drive | Get-Volume
$vol | ft

"- Get drive root:"
""
$path = $vol.DriveLetter + ":\"
$path
""

"- Get the install WIM/ESD image"
$installation = Get-ChildItem -Path $path -Recurse -Include install.*
$installation | Select-Object FullName, Length, LastWriteTime | ft
""

"- The chosen image:"
""
# TODO: Check for 64-bit image in case of multiple matches instead of choosing the 1st one:
$installation = $installation[0]
$installation | Select-Object FullName, Length, LastWriteTime | ft

"- Get the install WIM/ESD info:"
$wim_esd = Get-WindowsImage -ImagePath $installation.FullName
$wim_esd | fl

"- Prefered Windows editions:"
""
$editions = @(
  'Windows 10 Pro'
  'Windows 10 Enterprise'
  'Windows 10 Enterprise Evaluation'
)
$editions
""

ForEach ($edition in $editions) {
  $index = ($wim_esd | Where-Object { $_.ImageName -eq $edition }).ImageIndex

  if ($index) { break }
}
# TODO with hardcoded strings something more sensinble.
#      Maybe compare them with the value extracted from the online image.

if (!$index)
{
  "- No matching Windows edition (flavor) found."
  exit 2
}

"- Details of the selected image"
$wim_esd = Get-WindowsImage -ImagePath $installation.FullName -Index $index
$wim_esd | fl

if ($interact)
{
  "- Is the chosen image OK (index $index) ?"
  ""
  "  Press <Enter> to continue if so."
  Read-Host
}

"- Compile mount name from image details:"
""
$mount = "{0}\{1}-{2}-[{3}]-{4}" -f `
    $to, `
    $wim_esd.Version, `
    $wim_esd.EditionId, `
    $vol.FileSystemLabel, `
    $wim_esd.Languages[0]
$mount
""

"- Create mount dir:"
New-Item -ItemType Directory -Force $mount | ft

""
$log = $mount + ".log"
$filename = $installation.FullName

if ($filename -match '.esd$') {
  "- Convert from ESD to WIM format:"
  ""
  $temp_dir = "$mount.temp\"
  New-Item -ItemType Directory -Force $temp_dir | ft
  $esd = $filename
  $wim = $esd `
      -replace ('.+\\', $temp_dir) `
      -replace ('\.esd$', '.wim')
  ""
  "  * `$esd = $esd"
  "  * `$wim = $wim"
  ""
  $wim_esd = Export-WindowsImage -SourceImagePath $esd -SourceIndex $index -DestinationImagePath $wim -LogPath $log -CheckIntegrity -CompressionType 'none'
  $wim_esd | select * | fl
  # Since we create a new .wim file, it will contain the single volume image only. Hence:
  $index = 1

  if ($interact)
  {
    "- Was the ESD to WIM image conversion OK ?"
    ""
    "  Press <Enter> to continue if so."
    Read-Host
  }
}

if ($filename -match '.wim$') {
  $wim = $filename
}

"- Mount WIM:"
$wim_esd = Mount-WindowsImage -ImagePath $wim -Index $index -Path $mount -LogPath $log -CheckIntegrity -ReadOnly -Optimize
if (!$?) { "  * Failure:" }
$wim_esd | Select-Object * | fc

"- List WIM mounts:"
Get-WindowsImage -Mounted | fl

"- Search for WinRE files in:"
""
$path = $mount + '\Windows\System32\Recovery'
"  $path"
$winre = Get-ChildItem -LiteralPath $path -Recurse
$winre | ft
""

if ($winre)
{
  "- Output dir:"
  $out = $mount + ".RE\"
  New-Item -ItemType Directory -Force $out | ft
  Get-ChildItem -LiteralPath $mount | ft

  "- Copy WinRE files here:"
  $winre | Copy-Item -Destination $out
  Get-ChildItem -LiteralPath $out | ft
}
else
{
  "  * No files found."
  ""
}

if ($interact)
{
  "- Press <Enter> to continue and dismount the image ..."
  Read-Host
}

if ($temp_dir)
{
  "- Remove temporary WIM dir:"
  ""
  Remove-Item -Force $temp_dir -Recurse -WhatIf
  Remove-Item -Force $temp_dir -Recurse -Verbose
}

"- Dismount WIM:"

$wim_esd = Dismount-WindowsImage -Discard -Path $mount -LogPath $log
$wim_esd | Select-Object * | fc

"- Remove mount dir:"
""
Remove-Item -Recurse -LiteralPath $mount -WhatIf
Remove-Item -Recurse -LiteralPath $mount -ErrorAction SilentlyContinue -Verbose
""

"- Dismount ISO file:"
$drive = Dismount-DiskImage -DevicePath $drive.DevicePath
$drive

"- WinRE.wim details:"
""
$winre = "$out\winre.wim"
Get-Item -LiteralPath $winre | ft
Get-WindowsImage -ImagePath $winre | fl
Get-WindowsImage -ImagePath $winre -Index 1 | fl

"."
