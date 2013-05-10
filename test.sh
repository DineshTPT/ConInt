
. "build.config"

for config in $CONFIGURATIONS; do
provfile=$(eval echo \$`echo ProvisionFile$config`)
codesign=$(eval echo \$`echo Codesign$config`)

echo $provfile
echo $codesign
echo $config

cert="$provfile"
fileprefix="$config";

PROJECT_NAME="ConInt"
TARGET_SDK="iphoneos6.1"
PROJECT_BUILDDIR="build/Debug-iphoneos"
BUILD_HISTORY_DIR="/Users/Dinesh/Desktop"
DEVELOPPER_NAME=$codesign
PROVISONNING_PROFILE=$provfile

agvtool new-marketing-version 1.1.2
agvtool bump -all

# compile project
echo Building Project
xcodebuild -target "${PROJECT_NAME}" -sdk "${TARGET_SDK}" -configuration $config

#Check if build succeeded
if [ $? != 0 ]
then
exit 1
fi

app_path=$(ls -d build/$config-iphoneos/*.app)
/usr/bin/xcrun -sdk iphoneos PackageApplication -v "${app_path}" -o "$(pwd)/${PROJECT_NAME}.ipa" --sign "${DEVELOPPER_NAME}" --embed "${PROVISONNING_PROFILE}"


API_TOKEN="68730198beebeebed04363cbf48300cd_OTMzNjI4MjAxMy0wMy0xNSAwOToxNzo0OS4zMjM0OTU"
TEAM_TOKEN="4b7d84ffb8df9dd918918feae21c98e5_MjIwNDYyMjAxMy0wNS0wOSAxMTo1MDo0NC45NzAzMjY"

DSYM="${HOME}/Library/Developer/Xcode/Archives/${DATE}/${ARCHIVE}/dSYMs/${PRODUCT_NAME}.app.dSYM"
APP="${HOME}/Library/Developer/Xcode/Archives/${DATE}/${ARCHIVE}/Products/Applications/${PRODUCT_NAME}.app"


#echo -n "Zipping .dSYM for ${PRODUCT_NAME}..." >> $LOG
echo "Zipping .dSYM for ${PROJECT_NAME}"

dsym_path=$(ls -d build/$config-iphoneos/*.dSYM)
zip -r "${dsym_path}.zip" "${dsym_path}"

#echo "done." >> $LOG
echo "Created .dSYM for ${PRODUCT_NAME}"

#echo -n "Uploading to TestFlight... " >> $LOG
echo "Uploading to TestFlight"

curl "http://testflightapp.com/api/builds.json" \
-F file=@"${PROJECT_NAME}.ipa" \
-F dsym=@"${dsym_path}.zip" \
-F api_token="${API_TOKEN}" \
-F team_token="${TEAM_TOKEN}" \
-F notes="Build uploaded automatically using build script."

#check if the upload was successful, else retry upload next time. clean up on successful upload.

#echo "done." >> $LOG
echo "Uploaded to TestFlight"

done
