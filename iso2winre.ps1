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

"- Create mount dir:"
""
$mount = $to + "\" + $vol.FileSystemLabel
$log = $mount + ".log"
New-Item -ItemType Directory $mount
""

# Sync screen before the lengthy operation:
[Console]::Out.Flush()

"- Mount WIM/ESD:"
$wim_esd = Mount-WindowsImage -ImagePath $installation.FullName -Index $wim_esd.ImageIndex -ReadOnly -Path $mount -LogPath $log -CheckIntegrity -Optimize
$wim_esd | Select-Object * | fc

"- Search for WinRE files:"
""
$path = $mount + '\Windows\System32\Recovery'
$winre = Get-ChildItem -Path $path -Recurse
$winre | Select-Object FullName, Length, LastWriteTime | ft
""

"- Create the empty output dir:"
$out = $mount + ".WinRE\"
New-Item -ItemType Directory $out
""

"- Copy WinRE files here:"
$winre | Copy-Item -Destination $out
Get-ChildItem -Path $out -Recurse
""

# Sync screen before the lengthy operation:
[Console]::Out.Flush()

"- Dismount WIM/ESD:"
$wim_esd = Dismount-WindowsImage -Discard -Path $mount -LogPath $log
$wim_esd | Select-Object * | fc

"- Remove mount dir:"
""
Remove-Item -Recurse $mount -WhatIf
Remove-Item -Recurse $mount
""

"."
