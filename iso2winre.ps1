#! /usr/bin/env -S powershell -file

# SPDX-License-Identifier: BlueOak-1.0.0
# SPDX-FileCopyrightText: 2025 Saulius Krasuckas <saulius2_at_ar-fi_point_lt> | sskras

# - Mount a Windows Vista+ ISO image,
# - then mount the inner `INSTALL.{ESD,WIM}`
# - and access the `WinRE.wim` image stored there.

$iso_full=$args

"- Initial optical drives"
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 5' | Select-Object DeviceID, Size, VolumeName, Description

"- Details of the image"
Get-DiskImage -ImagePath ${iso_full} | fl

"- Mount the ISO image"
Mount-DiskImage -ImagePath ${iso_full} -PassThru

"- Final optical drives"
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 5' | Select-Object DeviceID, Size, VolumeName, Description | ft

echo .
