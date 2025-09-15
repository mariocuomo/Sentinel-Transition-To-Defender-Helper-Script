## Version history

- [SentinelTransitionHelper_v4.2.ps1](https://github.com/mariocuomo/Sentinel-Transition-To-Defender-Helper-Script/tree/main/script/SentinelTransitionHelper_v4.2.ps1) **CURRENT** <br> Note about Analytics Rules vs Custom Detection Rules

- [SentinelTransitionHelper_v4.1.ps1](https://github.com/mariocuomo/Sentinel-Transition-To-Defender-Helper-Script/tree/main/script/SentinelTransitionHelper_v4.1.ps1) <br> Code Refactoring

- [SentinelTransitionHelper_v4.0.ps1](https://github.com/mariocuomo/Sentinel-Transition-To-Defender-Helper-Script/tree/main/script/SentinelTransitionHelper_v4.0.ps1) <br> Implemented the ability to analyse the current configuration of Sentinel Analytics Rules to understand whether they can be migrated to Custom Detection Rules (based on the GA features of September 11, 2025)

- [SentinelTransitionHelper_v3.2.ps1](https://github.com/mariocuomo/Sentinel-Transition-To-Defender-Helper-Script/tree/main/script/SentinelTransitionHelper_v3.2.ps1) <br> Added the _Format_ parameter (docx or pdf)

- [SentinelTransitionHelper_v3.1.ps1](https://github.com/mariocuomo/Sentinel-Transition-To-Defender-Helper-Script/tree/main/script/SentinelTransitionHelper_v3.1.ps1) <br> Fixed printing issues. 

- [SentinelTransitionHelper_v3.0.ps1](https://github.com/mariocuomo/Sentinel-Transition-To-Defender-Helper-Script/tree/main/script/SentinelTransitionHelper_v3.0.ps1) <br> Implemented the possibility to analyze multiple Sentinel environments in a single script execution. Metadata (workspaceName, resourceGroupName, subscriptionId) for the various Sentinel environments should be inserted into the [_sentinelEnvironments.json_](https://github.com/mariocuomo/Sentinel-Transition-To-Defender-Helper-Script/blob/main/script/sentinelEnvironments.json) file.
  
- [SentinelTransitionHelper_v2.1.ps1](https://github.com/mariocuomo/Sentinel-Transition-To-Defender-Helper-Script/blob/main/script/SentinelTransitionHelper_v2.1.ps1) <br> Minor updates: fixed some printing operations, code refactoring per better management

- [SentinelTransitionHelper_v2.0.ps1](https://github.com/mariocuomo/Sentinel-Transition-To-Defender-Helper-Script/blob/main/script/SentinelTransitionHelper_v2.0.ps1) <br> Implemented the option to create PDF reports using _FileName_ parameter. Added statistics on passed and failed controls.

- [SentinelTransitionHelper_v1.0.ps1](https://github.com/mariocuomo/Sentinel-Transition-To-Defender-Helper-Script/blob/main/script/SentinelTransitionHelper_v2.1.ps1) <br> Initial version, blog post [here](https://www.linkedin.com/pulse/quick-automatic-checker-reducing-friction-during-sentinel-mario-cuomo-ab6ge/?trackingId=YW5akA14RT6hF4YknmrZFw%3D%3D). Same version as [gist](https://gist.github.com/mariocuomo/9594cffd32b87289ae70bff29da86618)

---
## Backlog of controls to be implemented
- Be sure that Word and Excel processes are closed correctly
- Handling errors
- Implementing more logic about custom detections conversion with dedicated functions to check tables mentioned the KQL queries
- Entra RBAC and Defender RBAC Analysis
