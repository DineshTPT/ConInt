
. "build.config"

MARKETTING_VERSION="1.0"
TARGET_SDK="iphoneos6.1"
API_TOKEN="68730198beebeebed04363cbf48300cd_OTMzNjI4MjAxMy0wMy0xNSAwOToxNzo0OS4zMjM0OTU"
TEAM_TOKEN="4b7d84ffb8df9dd918918feae21c98e5_MjIwNDYyMjAxMy0wNS0wOSAxMTo1MDo0NC45NzAzMjY"

for config in $CONFIGURATIONS; do
PROVISONNING_PROFILE=$(eval echo \$`echo ProvisionFile$config`)
DEVELOPPER_NAME=$(eval echo \$`echo Codesign$config`)

PROJECT_BUILDDIR="build/${config}-iphoneos"
echo $PROJECT_BUILDDIR

XCODE_PROJECT_FILE_NAME=$(ls -d *.xcodeproj)
PROJECT_NAME=$(eval echo $XCODE_PROJECT_FILE_NAME |cut -d'.' -f1)

echo $PROJECT_NAME
echo $PROVISONNING_PROFILE
echo $DEVELOPPER_NAME

# Auto increment build number
agvtool new-marketing-version $MARKETTING_VERSION
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
/usr/bin/xcrun -sdk iphoneos PackageApplication -v "${app_path}" -o "$(pwd)/${PROJECT_NAME}.ipa" --sign "${DEVELOPPER_NAME}" --embed "$(pwd)/${PROVISONNING_PROFILE}"

#echo -n "Zipping .dSYM for ${PRODUCT_NAME}..." >> $LOG
echo "Zipping .dSYM for ${PROJECT_NAME}"

dSYM_PATH=$(ls -d build/$config-iphoneos/*.dSYM)
zip -r "${dSYM_PATH}.zip" "${dSYM_PATH}"

#echo "done." >> $LOG
echo "Created .dSYM for ${PRODUCT_NAME}"

#echo -n "Uploading to TestFlight... " >> $LOG
echo "Uploading to TestFlight"

curl "http://testflightapp.com/api/builds.json" \
-F file=@"${PROJECT_NAME}.ipa" \
-F dsym=@"${dSYM_PATH}.zip" \
-F api_token="${API_TOKEN}" \
-F team_token="${TEAM_TOKEN}" \
-F notes="Build uploaded automatically using build script."

if [ $? != 0 ]
then
echo "upload failed"
exit 1
fi

echo "Build uploaded to TestFlight successfully!"

done
