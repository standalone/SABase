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

HEADERS="build/Debug-iphonesimulator/usr/local/include/*.h"
for HEADER in ${HEADERS}; do
	FILENAME="${HEADER##*/}"
	cp $HEADER "${LIB_DESTINATION}/Headers/${FILENAME}" 
done

