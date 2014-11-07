LIB_DESTINATION="./SA_Base Library"

#rm -rf "${HOME}/Library/Developer/Xcode/DerivedData"

DERIVED="${HOME}/Library/Developer/Xcode/DerivedData/SABase-*"
for DERIVED_FOLDER in ${DERIVED}; do
	echo "Removing ${DERIVED_FOLDER}"
	rm -rf "${DERIVED_FOLDER}"
done


echo "Lipo'ing ${LIB_DESTINATION}"

mkdir -p "${LIB_DESTINATION}"
mkdir -p "${LIB_DESTINATION}/Headers"

lipo -create "build/Release-iphoneos/libSABase.a" "build/Debug-iphonesimulator/libSABase.a" -output "${LIB_DESTINATION}/libSABase.a"
#lipo -create "build/Release-iphoneos/libSABase.a" "build/Debug-iphonesimulator/libSABase.a" -output "${LIB_DESTINATION}/libSABaseD.a"

HEADERS="build/Debug-iphonesimulator/usr/local/include/*.h"
for HEADER in ${HEADERS}; do
	FILENAME="${HEADER##*/}"
	cp $HEADER "${LIB_DESTINATION}/Headers/${FILENAME}" 
done


LIB_DESTINATION="./SA_Base.framework"

echo "Lipo'ing ${LIB_DESTINATION}"

mkdir -p "${LIB_DESTINATION}"
mkdir -p "${LIB_DESTINATION}/Headers"

lipo -create "build/Release-iphoneos/libSABase.a" "build/Debug-iphonesimulator/libSABase.a" -output "${LIB_DESTINATION}/SA_Base"

HEADERS="build/Release-iphoneos/usr/local/include/*.h"
for HEADER in ${HEADERS}; do
	FILENAME="${HEADER##*/}"
	cp $HEADER "${LIB_DESTINATION}/Headers/${FILENAME}" 
done

GIT_BRANCH=`git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1/"`
GIT_REV=`git rev-parse --short HEAD`

PLIST_PATH="${LIB_DESTINATION}/info.plist"
echo "${PLIST_PATH}"
/usr/libexec/PlistBuddy "${PLIST_PATH}" -c
/usr/libexec/PlistBuddy "${PLIST_PATH}" -c "Add :branch string ${GIT_BRANCH}"
/usr/libexec/PlistBuddy "${PLIST_PATH}" -c "Add :rev string ${GIT_REV}"