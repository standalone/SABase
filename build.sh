rm -r SA_Base.xcframework

echo "Building for iOS..."
xcodebuild archive \
    -sdk iphoneos IPHONEOS_DEPLOYMENT_TARGET=9.0 \
    -arch armv7 -arch arm64 \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -scheme "SA_Base" \
    -archivePath "./build/iphoneos/SA_Base.xcarchive" SKIP_INSTALL=NO

echo "Building for iOS Simulator..."
xcodebuild archive \
    -sdk iphonesimulator IPHONEOS_DEPLOYMENT_TARGET=9.0 \
    -arch x86_64 -arch arm64 BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -scheme "SA_Base" \
    -archivePath "./build/iphonesimulator/SA_Base.xcarchive" SKIP_INSTALL=NO

echo "Building for Catalyst..."
xcodebuild archive \
    MACOSX_DEPLOYMENT_TARGET=10.15 \
    -destination "platform=macOS,variant=Mac Catalyst" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -scheme "SA_Base" \
    -archivePath "./build/maccatalyst/SA_Base.xcarchive" SKIP_INSTALL=NO

#echo "Building for macOS..."
#xcodebuild archive \
#    -sdk macosx MACOSX_DEPLOYMENT_TARGET=11.0 \
#    -arch x86_64 -arch arm64 BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
#    -scheme "SA_Base" \
#    -archivePath "./build/macosx/SA_Base.xcarchive" SKIP_INSTALL=NO

echo "Building XCFramework..."
xcodebuild -create-xcframework -output ./SA_Base.xcframework \
    -framework "./build/iphoneos/SA_Base.xcarchive/Products/Library/Frameworks/SA_Base.framework" \
    -framework "./build/iphonesimulator/SA_Base.xcarchive/Products/Library/Frameworks/SA_Base.framework"
    -framework "./build/maccatalyst/SA_Base.xcarchive/Products/Library/Frameworks/SA_Base.framework" 
#    -framework "./build/macosx/SA_Base.xcarchive/Products/Library/Frameworks/SA_Base.framework"
