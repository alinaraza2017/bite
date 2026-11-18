# Content rating, audience, ads, and app access

> **Verify the live question text** under App content. Google adds and renames these forms. Answer only the forms that are on the screen. This draft does not invent a rating. The questionnaire calculates the rating after you submit it. Do not write "Everyone", "PEGI 3", or any other badge into the store until Console shows it.
>
> The questionnaire is the one Play labels as the content rating questionnaire (IARC). Confirm that name on the button you click.

## Content rating

Answer from what the app actually contains.

| Topic on the form | Suggested answer | Why |
|---|---|---|
| Violence | None | No violence, weapons, or blood. |
| Sexual content | None | No sexual content or nudity. |
| Bad language | None | No profanity in the app text. |
| Controlled substances | None | No alcohol, tobacco, or drug use. Chai, lassi, and doodh are in the food list. |
| Gambling | None | No bets, loot boxes, or prize draws. |
| Horror | None | No horror content. |
| User interaction with other people | No | No chat, comments, public profiles, or multiplayer. |
| Content users share with other users of Bite | No | Custom foods and logs stay on the phone. Export is a file the person sends through the share sheet. It is not posted inside Bite. |
| Shares the phone's location with other users | No | Bite does not read location. |
| Digital purchases | Yes | Monthly and yearly subscriptions through Google Play: `bite_premium_monthly` and `bite_premium_yearly`. |
| Unrestricted web browsing | No | No browser and no open web view. |
| Ads | No | No ad SDK and no ad placements. |

> **Verify:** the digital-purchases question. In-app purchases can change the rating the questionnaire produces. Accept the result Console shows. Do not edit the badge by hand.

## Target audience

**Suggested answer:** adults only. Do not tick any age group under 18.

**Why:** the project spec says the listing targets 18+. The app is not made for children. Do not opt into a "designed for families" or similar children's program if that checkbox appears.

> **Verify:** the age bands printed on the form. They are sometimes one "18 and over" box, and sometimes split (for example 18–24 and 25+). Tick every adult band the form shows, and no child band. Make `privacy_policy.md` match the bands you tick.

## Ads

**Question to look for:** whether the app contains ads.

**Answer:** No.

**Why:** Bite has no ad SDK, no banners, and no rewarded ads. A Play subscription is not an ad.

> **Verify** the exact sentence, including any question about ads in a web view. Bite has no web view.

## App access

**Suggested answer:** reviewers do not need a password. There is no Bite account.

Free use (log food, gym, 7-day progress, up to 10 custom foods, export, reset) works as soon as onboarding is finished.

Bite Premium locks two things that do work: custom foods after 10, and the chart past 7 days. The paywall also mentions a recipe builder. That screen does not build recipes in this version. Do not tell the reviewer it does.

If the form asks for instructions because some features are paid, write this and then **check that the form still wants it:**

1. Install the app from the closed-testing link.
2. Sign in on the phone with a Gmail address that is a license tester.
3. Open Premium and buy the test subscription (`bite_premium_monthly` or `bite_premium_yearly`). License testers are not charged.
4. There is no username or password.

> **Verify** whether a paywall counts as "restricted access" on the current form. A login wall and a subscription are different. If the form's own help says subscriptions do not need credentials, follow that help and do not invent a test account.

## Other declarations that may appear

If you see these, the honest answer for this app is No. Read each one. Do not skip a new form that this list does not mention.

- News app: No.
- Government or political app: No.
- Financial features (banking, loans, trading): No. A food subscription sold by Play is not a financial product of Bite.
- Health: only if a separate health form appears. Say that Bite shows calorie and macro estimates, includes the sentence "Bite gives estimates, not medical advice.", and does not diagnose, treat, or connect to a medical device. **Verify** the health questions. Do not claim a medical certification.
