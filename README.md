# macOS_softwareUpdate
Interactive bash script for installing software updates and (optionally) Command Line Tools.

## Overview
This script can perform the following actions:
- Run software updates (only applies to applications in the Mac App Store)
- If desired, perform a reboot that bypasses the pre-boot FileVault auth screen
  - This requires authorized credentials
  - You can opt to not bypass FileVault. You'll just need to unlock FileVault like normal.
  - In either case, you will be notified if a reboot is required __PRIOR__ to proceeding with any upgrades/reboot.
- __[ Optional ]__ Install Command Line Tools (without Xcode)
  - __NOTE:__ It will (re)install the most current version, **_even if_** the most current version is already installed.

## How to Run
- Must be run as root
- Use __```-x```__ to install Command Line Tools
- For any prompts that provide a numbered selection, you must enter the __number__

### Examples:
_(assuming changing into repository and/or script is not in $PATH)_

To check for software updates:
```
sudo ./macOS_softwareUpdate.sh
```

To check for software updates AND install Command Line Tools:
```
sudo ./macOS_softwareUpdate.sh -x
```

---
### For any questions or comments, please contact me. Thanks!
