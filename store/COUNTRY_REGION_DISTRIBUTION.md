# Requirements for distributing apps in specific countries/regions

Play Console note for Stella Fit (`com.restfit.app`).

Official Google help (source of truth):  
[Requirements for distributing apps in specific countries/regions](https://support.google.com/googleplay/android-developer/answer/6223646)

Also useful:  
[Distribute app releases to specific countries](https://support.google.com/googleplay/android-developer/answer/7550024)

> This is a practical summary for Stella Fit, **not legal advice**. Country rules change. When Play shows a banner or email for a region, follow that prompt.

## What this screen means

When you choose **Countries / regions** for Production, Open testing, or Closed testing, you are choosing **where the app is available on Google Play**.

Important details:

- Targeting uses the user’s **Play country** (account country), not where they are traveling right now.
- **Internal testing** ignores country targeting — testers can join from anywhere.
- Testing tracks often **sync** country lists with Production unless you click **Unsync countries/regions**.

For Stella Fit’s first release, selecting **all countries / rest of world** is usually fine unless you have a reason to exclude a region.

## Suggested Stella Fit approach

| Situation | Recommendation |
|-----------|----------------|
| Closed / internal testing | Keep broad availability (or don’t worry — internal ignores countries) |
| First production rollout | Add most/all countries unless you intentionally want a soft launch |
| Soft launch | Start with a few countries, then expand |
| Paid features / IAP later | Re-check Brazil, Japan, Korea, Israel payout / disclosure rules |

Stella Fit today is a **free wellness tracker** (no paid unlocks required for core use). Many **merchant / payout** rules only kick in when you **sell** apps or in-app purchases in that country.

---

## EU — Geo-blocking Regulation (EU) 2018/302

Play shows this when you distribute in the EU.

**Idea:** Do not use **unjustified geo-blocking** to discriminate against users based on nationality, residence, or place of establishment inside the EU.

For Stella Fit that usually means:

- If you distribute in the EU, prefer **EU-wide access** (don’t block France but allow Germany without a strong legal reason).
- Don’t block EU users from the store listing / download for nationality or residence alone.
- Copyright / licensed-content apps have special cases; Stella Fit is not that kind of product.

More info: [European Commission — geo-blocking](https://commission.europa.eu/business-economy-euro/doing-business-eu/single-market/geo-blocking_en)  
Regulation text: [Regulation (EU) 2018/302](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32018R0302)

### How to review EU / country availability in Play Console

1. Open Play Console → Stella Fit  
2. Go to **Production** (or your testing track)  
3. Open **Countries / regions**  
4. **Add** or **Remove** countries as needed  

---

## Brazil

Relevant if you **sell** on Play in Brazil (paid apps / IAP) or if Play asks for merchant verification.

### Merchant verification (sales / payouts)

Merchants selling in Brazil may need to provide business details (name, address, beneficial owners, executives, ID docs). Brazilian businesses may also need CPF / CNPJ.

Google typically emails you (`Important Information Regarding Your Google Account`) and shows a Console / payments.google.com banner when this is required.

### Digital ECA (children / adolescents)

Brazil’s Digital Child and Adolescent Statute adds obligations for apps aimed at kids or likely accessed by them (age signals, loot-box rules for games, etc.).

Stella Fit is adult wellness-focused. Keep:

- Target audience accurate in Play Console  
- Content rating questionnaire up to date  
- No child-directed marketing  

Play Age Signals API may apply for Brazil age-range use cases if you build for that later.

---

## Japan

If you distribute **paid apps or in-app purchases** to consumers in Japan, Japanese law (Specified Commercial Transactions Act) may require displaying business operator **name, phone, and physical address**.

Where that lives depends on when the developer account was created (Account details / Developer page, or Payments profile for newer accounts).

Also comply with other applicable Japanese laws (e.g. Payment Services Act) if you take payments.

**Stella Fit free app with no IAP:** usually no extra Japan commerce disclosure until you add paid products.

---

## Korea

Several Korea-specific rules exist, mostly for:

- **Games** (GRAC ratings, especially 19+ / gambling-style / loot boxes)  
- Apps **harmful to juveniles** (age/name verification)  
- Apps that collect **location** for location-based services (KCC licensing)  
- **Korean-based developers** (extra contact / business registration fields)

**Stella Fit:** not a game, no gambling, no location LBS. Standard Play policies + honest content rating are the main needs unless Play flags something.

Korean developers (account in Korea) must fill extra contact fields in Account / Developer settings.

---

## Vietnam (games)

Online **games** licensing rules apply to electronic games distributed in Vietnam. Stella Fit is not a game — this section generally does not apply. If you later ship a game, check ABEI licensing guidance.

---

## Israel (developer billing address in Israel)

If your **billing address** is in Israel, Google may require identity verification (KYC) for payouts / continued distribution. Play emails you and shows a Console banner when needed. Complete it on time or disbursements / distribution can be blocked.

---

## How country targeting interacts with testing

| Track | Country targeting |
|-------|-------------------|
| Internal testing | **Not applied** — any invited tester can install |
| Closed / Open testing | Can match Production or be customized (Unsync) |
| Production | Full country/region list controls public availability |

So: fixing Google Sign-In for Play testers is about **SHA-1 / OAuth**, not about adding their country to the list (for internal testing).

---

## Practical checklist for Stella Fit

- [ ] For closed testing: countries set (or synced) as you intend  
- [ ] For production: decide all countries vs soft launch  
- [ ] If distributing in EU: avoid unjustified geo-blocking across EU users  
- [ ] Content rating + target audience filled (needed everywhere)  
- [ ] Privacy policy URL live  
- [ ] If you add **paid / IAP** later: re-read Brazil, Japan, Korea, Israel sections and complete any Play banners  
- [ ] Watch Play Console for region-specific email/banners and complete them promptly  

## Related Stella Fit docs

- [`PLAY_CONSOLE.md`](./PLAY_CONSOLE.md) — listing, Data safety, access  
- [`PLAY_APP_SIGNING_SHA1.md`](./PLAY_APP_SIGNING_SHA1.md) — Google Sign-In on Play installs  
- [`GOOGLE_SIGNIN_SETUP.md`](./GOOGLE_SIGNIN_SETUP.md) — OAuth / Firebase setup  
