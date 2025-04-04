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

"- Get the install WIM/ESD info:"
$wim_esd = Get-WindowsImage -ImagePath $installation.FullName
$wim_esd | fc
$wim_esd = Get-WindowsImage -ImagePath $installation.FullName -Index 1
$wim_esd | fl

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

"- Mount WIM/ESD:"
$log = $mount + ".log"
$wim_esd = Mount-WindowsImage -ImagePath $installation.FullName -Index $wim_esd.ImageIndex -ReadOnly -Path $mount -LogPath $log -CheckIntegrity -Optimize
if ($?) { $wim_esd | Select-Object | fc }

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
  "- Create the output dir (in any):"
  $out = $mount + ".WinRE\"
  New-Item -ItemType Directory -Force $out | ft

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

"- Dismount WIM/ESD:"
$wim_esd = Dismount-WindowsImage -Discard -Path $mount -LogPath $log
$wim_esd | Select-Object * | fc

"- Remove mount dir:"
""
Remove-Item -Recurse -LiteralPath $mount -WhatIf
Remove-Item -Recurse -LiteralPath $mount
""

# TODO Dismount ISO file too.

# TODO Show WinRE.wim details.

"."
