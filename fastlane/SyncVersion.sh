#!/bin/bash

echo "Start Sync Version $1 ($2) to Setting"
cd ..
/usr/libexec/PlistBuddy -c "Set PreferenceSpecifiers:0:DefaultValue $1 ($2)" "./Settings.bundle/Root.plist"
