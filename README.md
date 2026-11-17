# Buzz Drill

Quizbowl practice: tossups read word by word, bonuses, buzzpoints, and stats you can combine with friends.

## Get it

**→ [tygerthelyon.github.io/buzzdrill](https://tygerthelyon.github.io/buzzdrill/)**: open this on your phone. It shows
the right install for your phone.

- **Android:** [Download BuzzDrill.apk](https://github.com/tygerthelyon/buzzdrill/releases/latest/download/BuzzDrill.apk),
  open it, and allow your browser to install apps if asked.
- **iPhone / iPad:** open [buzzdrill.qbdrill.workers.dev](https://buzzdrill.qbdrill.workers.dev/?install) in Safari,
  tap Share, then **Add to Home Screen**. (Apple allows direct installs only from the App Store.)
- **Computer:** just use [buzzdrill.qbdrill.workers.dev](https://buzzdrill.qbdrill.workers.dev/).

Free, and no account is needed to play. Pick a name and password only if you want to share stats with friends.

## What's here

- `docs/`: the download page (GitHub Pages).
- `android/`: the Android app. It's a Trusted Web Activity: a small shell that opens the Buzz Drill site full screen,
  so it updates whenever the site does. `build-apk.ps1` builds it; the signing key is kept elsewhere, never in this
  repo.

The app itself is one web page, served by a Cloudflare Worker. Its source lives in a private repo.
