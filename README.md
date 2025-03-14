**Group Number:** 15
**Team Members:** Daniel Jeng, Aneesh Chakka, Manuel Torralba, Humberto Torralba
**Name of Project:** Alarming Visuals
**Dependencies:** Xcode 15.0.1, Swift 5.9, iOS 13.0+

**Special Instructions:**

- You must use a phone to test this app because of the camera
  - As stated above, ensure iOS version is at least 13.0 for haptics to work
- To hear alarms, turn off Do Not Disturb and Silent Mode, and turn volume up all the way.
- When an alarm goes off, do not click on the app itself, but click on the notification. This allows you to disable the alarm (we needed extensive workarounds to treat that edge case)
- You must have Internet to log in.
  | Feature | Description | Release Planned | Release Actual | Deviations (if any) | Who/Percentage Worked On |
  |------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------|
  | Login/Sign up Authentication | Users can create accounts with an email | Alpha | Alpha | None | Aneesh (100%) |
  | General Settings | Dark mode and Spanish settings are saved to each user's account, activated upon login. | Final | Final | None | Aneesh (10%), Daniel (20%), Manuel (35%), Humberto (35%) |
  | Alarm List | Users can disable/enable alarms, as well as delete them. Additionally, if the alarm list is empty, the plus sign to add an alarm glows rainbow colors. | Alpha | Alpha | None | Daniel (100%) |
  | Editing/Adding Customizable Alarms | A new alarm or an existing alarm can be edited with the following features: Alarm Time, Alarm Name, Repeats, Alarm Sound, Photo Options. | Beta | Beta | Weekly repeats were surprisingly difficult to implement without creating an infinite number of alarms in advance, so this functionality wasn't fully implemented. | Daniel (20%) Aneesh (30%) Manuel (35%) Humberto (15%) |
  | Google Vision | By taking a picture of an object, the Google Vision API labels it, determining whether the alarm can be disabled. | Beta | Beta | None | Manuel (40%), Humberto (30%), Daniel (30%) |
  | Alarm Notifications | Each alarm, when disabled, created, or deleted has many corresponding notifications (because we used scheduled local notifications, which we have to send a lot of). When in the app, multithreading and haptics continue the alarm sound (because scheduled local notifications do not launch when you are in the app) | Beta | Beta | None | Humberto (45%), Manuel (30%), Daniel (25%) |

