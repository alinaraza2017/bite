# Testing Bite Premium on a real phone

Bite does not have its own payment server. Google Play takes the payment on the phone, and the app asks Play what this Google account owns. A debug build from `flutter run` cannot complete that. Use a build that Play installed from your testing track.

The two subscription ids must match the code exactly:

- `bite_premium_monthly`
- `bite_premium_yearly`

## 1. Create the subscriptions

In Play Console, open the Bite app, then **Monetize → Products → Subscriptions**.

Create one subscription for each id above. The id cannot be changed later.

For each one, add a base plan:

- Monthly: billing period 1 month, and the price you want.
- Yearly: billing period 1 year, and the price you want.

Activate the base plan and the subscription. Until they are active, the paywall says the plans are not in Play Console yet.

A free trial is optional. If you add one, it is an offer on the base plan. The app shows the price text Play sends (for example `Rs 700`). It does not invent a trial line.

Upload a new app bundle that contains this billing code to the same closed-testing track, and wait until Play finishes processing it.

## 2. Add license testers

License testers are not charged. They get a test card on the payment sheet.

1. Play Console → **Settings → License testing**.
2. Add the Gmail address that is signed in on the phone. Add your own, and anyone else who will try a purchase.
3. Set the license test response to the one that responds normally (the default). Save.

The same Gmail must also be a tester on the closed track:

1. **Test and release → Testing → Closed testing → Testers**.
2. Add that Gmail to the email list, or use the Google Group you already use.
3. Copy the **opt-in link**, open it on the phone while signed in as that Gmail, and accept the invite.
4. Install Bite from that Play page. Do not sideload an APK, and do not use a debug install.

The app on the phone must be the one from that listing (same package name, signed with the upload key you already use).

## 3. What to try on the phone

Turn off airplane mode. Open Bite, go to a locked row (30-day history or recipes), and open Premium.

- The two prices should be the ones you set, in the phone's currency. They should not say `$17.99`.
- Tap the yearly price. The Play sheet opens and says it is a test purchase. Approve it. Bite should say premium is unlocked, and the locked rows should open.
- Force-stop Bite and open it again. Premium should still be on. That is the check that runs when the app starts.
- Turn on airplane mode, force-stop Bite, and open it again. Premium should stay on. Play cannot be reached, so the app keeps the last yes and the time it was saved.
- Turn airplane mode off. On the paywall, tap **Restore purchases**. It should say premium is active.
- Install Bite on a second phone with a license-tester Gmail that has not bought it, or remove the subscription in Play and restore. Play answering "you own nothing" turns premium off. That is different from airplane mode, where Play never answered.

Also try the sheet itself:

- Approve a test card: premium turns on.
- Decline, or a card Play rejects: a message is shown, and a person who was not premium stays locked.
- Close the sheet without paying: the message says the purchase was cancelled, and the saved flag stays as it was.
- If a payment stays pending, Bite says it is waiting and does not unlock yet. When Play later says it was paid, the next app open picks that up.

The **Premium (demo)** switch is only in a debug build (`flutter run`). The build from Play does not show it.

## Acknowledging a purchase

After the tester approves the card, Play has taken the test payment but it waits for the app to confirm that premium was actually turned on. Bite does that by calling `completePurchase` on a purchased or restored subscription. Pending, cancelled, and failed payments are not confirmed. If a paid subscription is never confirmed, Play refunds it after three days.
