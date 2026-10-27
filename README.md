# Photo Swipe

A small iPhone app for cleaning up your camera roll. It shows your photos one at a time, newest first. Swipe **left** to mark a photo for deletion, or swipe **right** to keep it. When you're ready, tap **Delete** at the top right. iOS asks you to confirm once, and then removes every photo you swiped left.

Deleted photos go to the Photos app's **Recently Deleted** album and stay there for 30 days, so a mistake can be undone.

Built with Swift and SwiftUI. It has no third-party dependencies.

## The code

There are three Swift files in `PhotoSwipe/`:

| File | What it does |
| --- | --- |
| `PhotoSwipeApp.swift` | Where the app starts. It opens `ContentView`. |
| `PhotoLibrary.swift` | Everything that talks to Photos: asking for access, loading photos newest first, keep / delete / undo, and the actual delete. |
| `ContentView.swift` | Everything on screen: the access prompt, the photo card, the swipe gesture, and the buttons. |

Some other files:

- `PhotoSwipe/Assets.xcassets`: the app icon.
- `PhotoSwipe.xcodeproj`: the Xcode project. Open this to work on the app. Any file you add to the `PhotoSwipe/` folder becomes part of the app automatically.
- `.github/workflows/build.yml`: GitHub builds the app on every push, so you can see whether a change compiles.

Some things you might want to change first:

- **Swipe distance**: `swipeThreshold` in `ContentView.swift`.
- **Including videos**: in `loadPhotos()` in `PhotoLibrary.swift`, `fetchAssets(with: .image, ...)` loads photos only. Delete the `with: .image,` argument to load videos too.
- **Remembering progress**: the app starts from the newest photo every time it opens. Saving `currentIndex` (for example with `@AppStorage`) would let it pick up where you left off.

## What you need

- A Mac with **Xcode** from the Mac App Store. This project needs Xcode 26 or newer.
- An iPhone running **iOS 18** or newer.
- An **Apple ID**. That's all you need to run the app on your own phone with a cable.
- A paid **Apple Developer Program** membership ($99/year) for TestFlight. You can enroll at <https://developer.apple.com/programs/enroll/>. Approval usually takes anywhere from a few hours to two days.

## Run it on your phone with a cable (quickest way to try it)

1. Clone the repo and open the project:
   ```sh
   git clone https://github.com/mathesond2/photo-swipe.git
   open photo-swipe/PhotoSwipe.xcodeproj
   ```
2. In Xcode, click **PhotoSwipe** at the top of the left sidebar, then click the **PhotoSwipe** target, then the **Signing & Capabilities** tab.
3. Leave **Automatically manage signing** checked. Under **Team**, pick your name. If it isn't listed, choose **Add an Account…** and sign in with your Apple ID.
4. If Xcode says the bundle identifier is unavailable, change **Bundle Identifier** to something unique, such as `com.yourname.PhotoSwipe`.
5. Plug in your iPhone and unlock it. Tap **Trust** if your phone asks.
6. On the iPhone, turn on **Settings › Privacy & Security › Developer Mode**. The phone will restart.
7. In Xcode's toolbar, pick your iPhone from the device menu at the top center, then press **▶** (or ⌘R).
8. The first time, iOS may refuse to open the app. Go to **Settings › General › VPN & Device Management**, tap your Apple ID, and tap **Trust**.

If you only have a free Apple ID, apps installed this way stop opening after 7 days. Press ▶ again to reinstall.

## Test it with TestFlight

TestFlight installs the app over the air, with no cable, and builds last 90 days. You need the paid Developer Program membership.

### One-time setup

1. **Set up signing in Xcode.** Follow steps 1–4 above and choose the team for your paid membership. Write down the **Bundle Identifier** you end up with.
2. **Create the app in App Store Connect.**
   1. Go to <https://appstoreconnect.apple.com>, then **Apps**, then the **+** button, then **New App**.
   2. **Platforms:** iOS.
   3. **Name:** anything you like, such as "Photo Swipe (yourname)". It has to be unique across the whole App Store, but no one will see it unless you publish the app.
   4. **Primary Language:** English (U.S.).
   5. **Bundle ID:** choose the one from step 1. If it isn't in the list, archive once (below) and Xcode will register it, or add it at <https://developer.apple.com/account/resources/identifiers/list>.
   6. **SKU:** any text, such as `photoswipe`.
   7. **User Access:** Full Access. Then click **Create**.

### Upload a build (repeat for every new version)

1. In Xcode's device menu at the top center, choose **Any iOS Device (arm64)**.
2. Choose **Product › Archive**. When it finishes, the **Organizer** window opens with your archive selected.
3. Click **Distribute App**, choose **TestFlight Internal Only**, and click **Distribute**. Let Xcode handle signing automatically.
4. Wait for "Upload succeeded". Apple then processes the build, which usually takes 5–30 minutes, and emails you when it's done.

**Before each new upload,** increase the build number. Click the PhotoSwipe target, open the **General** tab, and change **Build** (for example 1 → 2). App Store Connect rejects a build number it has already seen.

### Install it on your iPhone

1. In App Store Connect, open your app and go to the **TestFlight** tab.
2. If the build says **Missing Compliance**, click **Manage**. Answer that the app uses **no encryption algorithms**, or "None of the algorithms mentioned above". This app doesn't use any encryption itself.
3. Under **Internal Testing** in the sidebar, click **+**, create a group (for example "Me"), and add yourself as a tester. Then add the build to that group.
4. On your iPhone, install **TestFlight** from the App Store.
5. Open the invite email on your phone and tap **View in TestFlight**. You can also just open TestFlight and sign in with the same Apple ID. Then tap **Install**.
6. Open Photo Swipe and tap **Allow Full Access** when it asks about your photos.

## Troubleshooting

- **"No access to photos" screen.** Go to **Settings › Apps › Photo Swipe › Photos** and choose **Full Access**. If you choose **Limited Access**, the app only shows the photos you picked.
- **A spinner instead of a photo.** The photo is probably being downloaded from iCloud. Give it a moment.
- **"Delete" did nothing.** You probably tapped **Don't Allow** in the confirmation dialog. Your marked photos are still waiting, so tap Delete again.
- **The archive won't upload: "No accounts" or "No signing certificate".** Open **Xcode › Settings › Accounts** and make sure the Apple ID with the paid membership is signed in.
