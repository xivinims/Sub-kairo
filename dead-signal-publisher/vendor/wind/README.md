# Audited Wind Effects selection

Source: Roblox Creator Store asset 11946229834, supplied by the user.
WindShake and WindLines by boatbomber and CloneTrooper1019; Octree credits retained in source (Quenty/howmanysmall).

The seven source containers were inspected without parenting them into the DataModel or executing them. Only the six local modules were copied; the WindController demo LocalScript and its GUI were excluded. No remote asset requires, network calls, obfuscated loaders or external execution were found in the copied modules.

Local adaptations: 20 Hz movement / 15 Hz target computation; nearest 32 objects on touch and 64 on desktop, within 96 studs; missing-camera guard; initialization cleanup correction; subtle wind line transparency. The custom ForestWindClient integrates GlobalWind, streaming mount/unmount and the audited modules. Native grass animation remains Roblox terrain decoration.
