# Consent-First Creator Drafting Desk

A local-first Flutter starter for drafting, provenance tracking, review, and owner approval. The app does not publish content.

## Cloud builds

GitHub Actions builds both targets on every push to `main` and on manual dispatch:
- Android release APK
- Windows desktop ZIP

Open the repository's **Actions** tab, select **Build Android and Windows**, and open the newest successful run. Download the Android or Windows artifact from the run's **Artifacts** section. Artifacts are retained for 14 days.

## Current prototype scope

- Local JSON persistence in the application support directory.
- Drafts, revision increments, and local audit events.
- Adult/consent confirmation before each image import.
- Required image provenance notes.
- AI disclosure and audience-warning gates before review.
- Owner approval bound to the current revision; editing invalidates prior approval.
- Persistent kill switch.
- No API client, authentication service, scheduler, social posting, payments, or network publishing.

## Important limitations

This is an early prototype, not a security or legal certification. Consent confirmation is not proof of rights ownership or a licence. The user must independently verify that they have the necessary rights and permissions. Audit data and drafts are local and are not tamper-proof. Imported media is copied into the app's local support directory; protect the device and any backups.

The Windows archive contains the release runner files. Keep the files together and launch the included executable. On Android, install the APK only on a device you control and allow installation from the source you use if Android asks.

## Privacy

The repository contains source code only. Do not commit personal records, private images, credentials, signing keys, or app data. The repository is currently public unless you change its visibility in GitHub settings.
