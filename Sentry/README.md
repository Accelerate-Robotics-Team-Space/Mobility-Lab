# Sentry

## Current Version
This version is 8.55.0

https://github.com/getsentry/sentry-cocoa/releases

## Integration Guide
[link](https://docs.sentry.io/platforms/apple/guides/ios/manual-setup/)

### Integrate Sentry into your Xcode project by using our pre-compiled frameworks.

To integrate Sentry into your Xcode project, follow these steps:

1. Download the latest version of the SDK from the Sentry Cocoa [Releases page](https://github.com/getsentry/sentry-cocoa/releases).
2. Each release contains the following four framework options:
   - `Sentry-Dynamic.xcframework.zip`: Dynamic framework
   - `Sentry.xcframework.zip`: Static framework
   - `SentrySwiftUI.xcframework.zip`: Static Framework with SwiftUI support
   - `Sentry-WithoutUIKitOrAppKit.xcframework.zip`: Static framework without UIKit or AppKit linking and related features
3. Import the chosen framework into your Xcode project target.

### Usage Guidelines:

- Use `Sentry-Dynamic`, `Sentry`, or `Sentry-WithoutUIKitOrAppKit` independently. Only one of these should be included in your project at a time. 
- If you're using `SentrySwiftUI`, it must be combined with `Sentry-Dynamic`.

### Configuration
[link](https://docs.sentry.io/platforms/apple/guides/ios/manual-setup/#configuration)

We recommend initializing the SDK on the main thread as soon as possible – in your AppDelegate application:didFinishLaunchingWithOptions method, for example:

> [!NOTE] 
> The following code sample will let you choose your personal config from the dropdown, once you're [logged in](https://sentry.io/auth/login/?next=https://sentry-docs-next.sentry.dev//platforms/apple/guides/ios/manual-setup/).

```swift
import Sentry // Make sure you import Sentry
// ....
func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    SentrySDK.start { options in
        options.dsn = "https://examplePublicKey@o0.ingest.sentry.io/0"
        options.debug = true // Enabled debug when first installing is always helpful
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0
    }
    return true
}
```

If you're using SwiftUI and your app doesn't implement an app delegate, initialize the SDK within the [App conformer's initializer](https://developer.apple.com/documentation/swiftui/app/main()):

> [!NOTE]
> The following code sample will let you choose your personal config from the dropdown, once you're [logged in](https://sentry.io/auth/login/?next=https://sentry-docs-next.sentry.dev//platforms/apple/guides/ios/manual-setup/).

```swift
import Sentry
@main
struct SwiftUIApp: App {
    init() {
        SentrySDK.start { options in
            options.dsn = "https://examplePublicKey@o0.ingest.sentry.io/0"
            options.debug = true // Enabled debug when first installing is always helpful
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0
        }
    }
}
```

### Configuration Options

[link](https://docs.sentry.io/platforms/apple/guides/ios/configuration/options/)

### Tags

[link](https://docs.sentry.io/platforms/apple/guides/ios/enriching-events/tags/)

```swift
import Sentry
SentrySDK.configureScope { scope in
    scope.setTag(value: "de-at", key: "page_locale")
}
```

### Users

[link](https://docs.sentry.io/platforms/apple/guides/ios/enriching-events/identify-user/)

```swift
import Sentry
let user = User()
user.email = "john.doe@example.com"
// Start the SDK before setting the user, otherwise it will be ignored.
SentrySDK.setUser(user)
```

### 'Source Context' Integration

[link](https://docs.sentry.io/platforms/apple/guides/ios/sourcecontext/#1-manually-upload-with-the-sentry-cli)

### DSym Uploads

[link](https://docs.sentry.io/platforms/apple/guides/ios/dsym/#sentry-cli)
