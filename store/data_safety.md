# Data safety form

> **Verify every question label in the live form** before you submit. Google changes the wording. Open Play Console Help and read the article titled **Provide information for Google Play's Data safety section**. If a question below does not match the screen, follow the screen, not this file.
>
> This draft does not quote a policy number.

## Suggested first answer

**Question to look for:** whether the app collects or shares any of the required user data types.

**Answer:** No.

**Why:**

- Profile, meals, custom foods, workouts, sets, and weight are stored in the app's private storage on the phone. Bite has no server, so that data is not sent to Bite.
- There is no sign-up, so Bite does not receive a name, email, or phone number.
- There is no analytics SDK and no advertising SDK.
- **Export data** writes a JSON file and opens the Android share sheet. The person picks the other app. Bite does not upload the file.
- Premium is bought through Google Play. Bite stores only a yes/no and the time Play last answered. Bite does not receive the card number or the Google password.

## Data that exists on the phone

Use this if a reviewer, or a later question, asks what the app handles. It is not a list of boxes to tick while the first answer stays No.

| Data | Where it lives | Why the suggested answer is still No |
|---|---|---|
| Sex, age, height, weight, activity, goal | Phone only | Used to estimate targets. Not sent to Bite. |
| Meals, custom foods, oil level, portions | Phone only | The food log. Not sent to Bite. |
| Workouts, sets, estimated burn | Phone only | The gym log. Not sent to Bite. |
| Body weight over time | Phone only | The weight chart. Not sent to Bite. |
| Premium yes/no and check time | Phone only | A cache so offline use does not lock a paying person out. |
| JSON export | Leaves the phone only if the person shares it | Bite does not choose the destination. |

## Points you must check on the help page

Do not tick these from memory.

1. **Collected.** Confirm the help page still treats "collected" as data transmitted off the device. Data that never leaves the phone is the reason for answering No.
2. **Shared.** Confirm whether a file the person sends through the system share sheet counts as the app sharing data. In Bite, the person taps Export and chooses the app.
3. **Play Billing.** Confirm the current help text about purchase data that Google Play processes, which the app does not receive. Only declare a financial or purchase category if that page says you must. Do not add categories "to be safe".
4. **Follow-up questions.** Encryption in transit, deletion requests, and an independent security review usually appear after you answer Yes to collection. If you answered No and those questions still appear, stop and re-read them. Do not answer Yes to encryption. Bite does not send logs to a server of its own, and nobody has done an independent security review.
5. **Health data.** The log is health and fitness information, but it stays on the phone. Only tick a health type if the definition on the form includes on-device data. Read that definition in the form. Do not guess.

## If you later add any of these, this draft is wrong

Analytics, ads, a Bite account, crash reporting that leaves the phone, or uploading the JSON yourself. Update this form and `privacy_policy.md` together. The two must say the same thing.
