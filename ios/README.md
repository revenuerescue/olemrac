# Olemrac for iPhone

A native SwiftUI shell around the Olemrac web app. The web build in `Olemrac/web/` is
bundled into the app and served from a private `olemrac://app/` origin, so it works fully
offline and its data (IndexedDB) persists between launches. CSV export uses the iOS share
sheet; receipt photos use the system photo picker.

## Run it

1. Accept the Xcode licence once (needed for any build on this Mac):
   `sudo xcodebuild -license accept`
2. Open `ios/Olemrac.xcodeproj` in Xcode.
3. Select your Team under *Signing & Capabilities* (any free Apple ID works for the simulator
   and for running on your own phone).
4. Pick a simulator or your iPhone and press Run.

## Keep the web app and the iPhone app in sync

The iPhone app ships whatever is in `Olemrac/web/`. After changing the web app:

    cp ../index.html Olemrac/web/index.html && cp -R ../icons Olemrac/web/icons

## Regenerate the project (optional)

`project.yml` is an [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec that produces the
same project: `brew install xcodegen && xcodegen`.

## App Store

Needs an Apple Developer Program membership ($99/yr). Bump `CFBundleVersion` in
`Olemrac/Info.plist`, Archive in Xcode, upload to App Store Connect. The bundle id is
`com.olemrac.app`; change it if that id is taken.
