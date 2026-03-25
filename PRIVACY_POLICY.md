# ModusMemori Privacy Policy

**Effective Date:** [INSERT DATE BEFORE PUBLISHING]
**Last Updated:** [INSERT DATE BEFORE PUBLISHING]

---

## Privacy Policy

ModusMemori ("the App") is a flashcard and spaced-repetition study tool. This Privacy Policy explains how the App handles your information.

### Summary

**ModusMemori does not collect, transmit, or share any personal data.** All data you create in the App lives exclusively on your device.

---

### Information We Collect

**We collect no information.**

The App does not collect, transmit, store on external servers, or share any personal information or usage data.

### Data Stored on Your Device

The App stores the following data **locally on your device only**, using Apple's SwiftData framework:

- Flashcard decks and cards you create
- Study session history and review records
- Spaced-repetition state for each card (ease factor, interval, next review date)

The following preferences are stored locally via Apple's UserDefaults:

- Study settings (daily card limit, new cards per day, review order)
- Display and feedback preferences (haptics, sounds)

This data never leaves your device and is not accessible to the App's developers.

### CSV Import

When you import a CSV file, the App reads the file you select using Apple's standard document picker. The file is read once to create flashcards and is not retained, copied to external storage, or transmitted anywhere.

### Third-Party Services

The App uses no third-party SDKs, analytics tools, advertising networks, or external APIs. There are no in-app purchases, accounts, or sign-in flows.

### Children's Privacy

The App does not collect any data from any users, including children under 13. It is compliant with COPPA by virtue of collecting no data at all.

### Data Deletion

To delete all App data, delete the App from your device. This permanently removes all flashcard decks, study history, and preferences.

### Changes to This Policy

If this policy changes in a future version, the updated policy will be included with that app update. The "Last Updated" date above will reflect the revision date.

### Contact

If you have questions about this privacy policy, contact:
[YOUR NAME OR COMPANY NAME]
[YOUR CONTACT EMAIL]

---

---

# Implementation Instructions

Follow these steps to implement the Privacy Policy in the App.

## Step 1: Fill in the placeholders

In this file, replace:
- `[INSERT DATE BEFORE PUBLISHING]` with today's date (e.g., `March 18, 2026`)
- `[YOUR NAME OR COMPANY NAME]` with your name or company
- `[YOUR CONTACT EMAIL]` with your support email address

## Step 2: Add a PrivacyPolicyView to the app

Create a new file at `ModusMemori/Views/Settings/PrivacyPolicyView.swift`:

```swift
import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("Effective Date: [INSERT DATE]")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Summary")
                        .font(.headline)
                    Text("ModusMemori does not collect, transmit, or share any personal data. All data you create in the App lives exclusively on your device.")

                    Text("Data Stored on Your Device")
                        .font(.headline)
                    Text("The App stores the following data locally on your device only, using Apple's SwiftData framework:\n\n• Flashcard decks and cards you create\n• Study session history and review records\n• Spaced-repetition state for each card\n\nStudy settings and preferences are stored via Apple's UserDefaults. This data never leaves your device.")

                    Text("CSV Import")
                        .font(.headline)
                    Text("When you import a CSV file, the App reads your selected file once to create flashcards. It is not retained, copied, or transmitted anywhere.")
                }

                Group {
                    Text("Third-Party Services")
                        .font(.headline)
                    Text("The App uses no third-party SDKs, analytics tools, advertising networks, or external APIs.")

                    Text("Children's Privacy")
                        .font(.headline)
                    Text("The App does not collect any data from any users, including children under 13.")

                    Text("Data Deletion")
                        .font(.headline)
                    Text("To delete all App data, delete the App from your device.")

                    Text("Contact")
                        .font(.headline)
                    Text("[YOUR NAME OR COMPANY]\n[YOUR CONTACT EMAIL]")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
```

## Step 3: Update SettingsView to navigate to PrivacyPolicyView

In `ModusMemori/Views/Settings/SettingsView.swift`, replace the existing Privacy Policy `Link` (around line 85) with a `NavigationLink`:

**Remove this:**
```swift
Link(destination: URL(string: "https://example.com/privacy")!) {
    HStack {
        Text("Privacy Policy")
        Spacer()
        Image(systemName: "arrow.up.right")
            .font(.caption)
    }
}
```

**Replace with:**
```swift
NavigationLink {
    PrivacyPolicyView()
} label: {
    Text("Privacy Policy")
}
```

## Step 4: Add the Privacy Policy URL to App Store Connect

Apple requires a privacy policy URL for all apps on the App Store. You have two options:

**Option A (Recommended): Host the policy as a webpage**
- Create a simple webpage with the policy text (GitHub Pages, your own site, etc.)
- Paste the URL into App Store Connect under **App Information → Privacy Policy URL**

**Option B: Use a free privacy policy host**
- Services like [privacypolicies.com](https://privacypolicies.com) or [app-privacy-policy.com](https://app-privacy-policy.com) can host it for free
- Paste the generated URL into App Store Connect

Then update the placeholder URL in `SettingsView.swift` if you keep a web link anywhere.

## Step 5: Update the App Store privacy labels in App Store Connect

In App Store Connect under **App Privacy**, select:
- **Data Not Collected** — since the app collects no data, check this box

This is accurate given the app's architecture (local SwiftData only, no network calls, no analytics).

## Step 6: Add a `NSPrivacyAccessedAPITypes` entry if needed (optional)

Apple may flag your app during review if it uses certain APIs without a declared reason. Check your app for use of:
- `UserDefaults` → reason code `CA92.1` (app functionality)
- File timestamp APIs → reason code `DDA9.1`

Add a `PrivacyInfo.xcprivacy` file to the app target if Xcode or App Store review flags this. Xcode 15+ has a built-in editor for this file under **File → New → Privacy Manifest**.
