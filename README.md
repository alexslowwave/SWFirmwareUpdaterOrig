# SWFirmwareUpdater

This project is a standalone iOS app that may be used to update SWIFT firmware from the iPad

SWIFT must be running version V8 or higher for this to work at all.

While the actual firmware updates happen over Bluetooth, please note that a USB connection is required so the app can send MIDI messages to put SWIFT into DFU Mode.

This was done to protect the current functionality of "normal mode" in the firmware, and to protect the update process from interference or errors due to processing sensor data or checking messages from SWControl app. Instead of adding DFU to the main loop, we added a MIDI command that reboots SWIFT into a separate loop that only does DFU updates.

It should be possible in the future to avoid the reboot. This would have the advantage of avoiding restarts and MIDI handshaking to determine SWIFT mode (normal or DFU). 
