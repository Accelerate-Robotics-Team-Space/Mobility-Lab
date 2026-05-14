#!/bin/sh
/usr/bin/sandbox-exec -p "(version 1)
(deny default)
(import \"system.sb\")
(allow file-read*)
(allow process*)
(allow mach-lookup (global-name \"com.apple.lsd.mapdb\"))
(allow mach-lookup (global-name \"com.apple.mobileassetd.v2\"))
(allow file-write*
    (subpath \"/private/tmp\")
    (subpath \"/private/var/tmp\")
    (subpath \"/private/var/folders/m_/mltdp1j51_x2stcq3lpv05fr0000gn/T\")
    (subpath \"/private/var/folders/m_/mltdp1j51_x2stcq3lpv05fr0000gn/C\")
)
(deny file-write*
    (subpath \"/Users/richahussain/Code/Mobility-Lab\")
)
(allow file-write*
    (subpath \"/Users/richahussain/Library/Developer/Xcode/DerivedData/SensorSuite-cxfziznyqgllhzepecxjnjzursft/Build/Intermediates.noindex/BuildToolPluginIntermediates/SensorSuite.output/SensorSuite_WatchKit_App/RswiftGenerateInternalResources\")
    (subpath \"/private/var/folders/m_/mltdp1j51_x2stcq3lpv05fr0000gn/T/TemporaryItems\")
)
" "/${BUILD_DIR}/${CONFIGURATION}/rswift" generate "/Users/richahussain/Library/Developer/Xcode/DerivedData/SensorSuite-cxfziznyqgllhzepecxjnjzursft/Build/Intermediates.noindex/BuildToolPluginIntermediates/SensorSuite.output/SensorSuite_WatchKit_App/RswiftGenerateInternalResources/SensorSuite WatchKit App/Resources/R.generated.swift" --target "SensorSuite WatchKit App" --input-type xcodeproj --bundle-source finder

