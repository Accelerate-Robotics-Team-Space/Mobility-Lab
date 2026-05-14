#!/bin/sh
# Name of the resource we're selectively copying
GOOGLESERVICE_INFO_PLIST=GoogleService-Info.plist

# Get references to dev and prod versions of the GoogleService-Info.plist
# NOTE: These should only live on the file system and should NOT be part of the target (since we'll be adding them to the target manually)
GOOGLESERVICE_INFO_QA=${PROJECT_DIR}/SensorSuite/Firebase/Qa/${GOOGLESERVICE_INFO_PLIST}
GOOGLESERVICE_INFO_TEST=${PROJECT_DIR}/SensorSuite/Firebase/Test/${GOOGLESERVICE_INFO_PLIST}
GOOGLESERVICE_INFO_PROD=${PROJECT_DIR}/SensorSuite/Firebase/Prod/${GOOGLESERVICE_INFO_PLIST}

# Make sure the Qa version of GoogleService-Info.plist exists
echo "Looking for ${GOOGLESERVICE_INFO_PLIST} in ${GOOGLESERVICE_INFO_QA}"
if [ ! -f $GOOGLESERVICE_INFO_QA ]
then
    echo "No Development GoogleService-Info.plist found. Please ensure it's in the proper directory."
    exit 1
fi

# Make sure the Test version of GoogleService-Info.plist exists
echo "Looking for ${GOOGLESERVICE_INFO_PLIST} in ${GOOGLESERVICE_INFO_TEST}"
if [ ! -f $GOOGLESERVICE_INFO_TEST ]
then
    echo "No Test GoogleService-Info.plist found. Please ensure it's in the proper directory."
    exit 1
fi

# Make sure the prod version of GoogleService-Info.plist exists
echo "Looking for ${GOOGLESERVICE_INFO_PLIST} in ${GOOGLESERVICE_INFO_PROD}"
if [ ! -f $GOOGLESERVICE_INFO_PROD ]
then
    echo "No Production GoogleService-Info.plist found. Please ensure it's in the proper directory."
    exit 1
fi

# Get a reference to the destination location for the GoogleService-Info.plist
PLIST_DESTINATION=${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app
echo "Will copy ${GOOGLESERVICE_INFO_PLIST} to final destination: ${PLIST_DESTINATION}"

# Copy over the prod GoogleService-Info.plist for Release builds
if [ "${CONFIGURATION}" == "Prod" ]
then
    echo "Using ${GOOGLESERVICE_INFO_PROD}"
    cp "${GOOGLESERVICE_INFO_PROD}" "${PLIST_DESTINATION}"
elif [ "${CONFIGURATION}" == "Test" ]
then
    echo "Using ${GOOGLESERVICE_INFO_TEST}"
    cp "${GOOGLESERVICE_INFO_TEST}" "${PLIST_DESTINATION}"
else
    echo "Using ${GOOGLESERVICE_INFO_QA}"
    cp "${GOOGLESERVICE_INFO_QA}" "${PLIST_DESTINATION}"
fi

