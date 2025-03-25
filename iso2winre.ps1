#! /usr/bin/env -S powershell -file

# SPDX-License-Identifier: BlueOak-1.0.0
# SPDX-FileCopyrightText: 2025 Saulius Krasuckas <saulius2_at_ar-fi_point_lt> | sskras

# - Mount a Windows Vista+ ISO image,
# - then mount the inner `INSTALL.{ESD,WIM}`
# - and access the `WinRE.wim` image stored there.

Function _ ()
{
    echo "- $args"
}

Function P ()
{
    Invoke-Expression -Command "$args"
}

$iso_full=$args

_ "Initial optical drives"
P "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 5' | Select-Object DeviceID, Size, VolumeName, Description"

_ "Details of the image"
P "Get-DiskImage -ImagePath '${iso_full}' | fl"

_ "Mount the ISO image"
P "Mount-DiskImage -ImagePath '${iso_full}' -PassThru"

_ "Final optical drives"
P "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 5' | Select-Object DeviceID, Size, VolumeName, Description | ft"

echo .
