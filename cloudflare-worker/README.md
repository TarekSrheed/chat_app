# Firebase group-chat push Worker

This Worker accepts only a Firebase-authenticated `{ groupId, messageId }`
request. It loads the persisted group and message from Firestore, verifies that
the caller is a group member and the message sender, then sends FCM HTTP v1
notifications to the other members' registered devices. The Worker does not
accept message text, recipient UIDs, or device tokens from the client.

The Firebase service-account JSON is stored only as the Cloudflare secret
`FIREBASE_SERVICE_ACCOUNT_JSON`. Never add it to Flutter assets, source control,
Wrangler configuration, or a public file.

## Database contract

The Worker uses the existing Firebase project `chatapp-4a9e1` and the default
Firestore database:

- Groups: `groups/{groupId}`; the member UIDs are in `members`.
- Messages: `groups/{groupId}/messages/{messageId}`; a new message has
  `groupId`, `senderId`, `sender`, `message`, and `time`.
- Sender display name: `users/{uid}.fullName` from the existing private profile.
- `users_public/{uid}` remains client-facing profile metadata; the Worker does
  not depend on it.
- Current device tokens: `fcmTokens/{sha256(uid:token)}` with `uid`, `token`,
  and `updatedAt`.
- Existing legacy tokens: optional `users/{uid}.fcmToken`, read during rollout.
- Private Worker metadata: `notificationRateLimits/{uid}` and the server-only
  `pushDispatchStatus` fields on each message.

Firestore client rules deny access to Worker metadata. Service-account API
requests use IAM and do not depend on Firestore client rules.

## Cloudflare setup

1. In Google Cloud Console, select project `chatapp-4a9e1`. Enable the **Cloud
   Firestore API** and **Firebase Cloud Messaging API**.
2. Create a dedicated service account for this Worker. Grant it
   `roles/datastore.user` for Firestore REST access and
   `roles/firebasecloudmessaging.admin` for FCM sends. These roles grant broad
   project-level data/API access; use a reviewed custom role if your
   organization supports the required Firestore entity permissions and FCM
   `cloudmessaging.messages.create` permission.
3. Create a JSON key for that service account and keep it in a secure temporary
   location. The key must not be committed or added to the Flutter app.
4. In Cloudflare, create a Worker named `chat-app-push-api`, or deploy the
   Worker below with Wrangler. Set the following non-secret Worker variables:
   - `FIREBASE_PROJECT_ID`: `chatapp-4a9e1`
   - `ALLOWED_ORIGINS`: comma-separated exact HTTPS origins for Flutter Web
     (leave empty for native-only clients; requests without an `Origin` header
     are accepted, but still require Firebase authentication)
   - `MAX_NOTIFICATION_RECIPIENTS`: defaults to `30`
   - `RATE_LIMIT_REQUESTS`: defaults to `20`
   - `RATE_LIMIT_WINDOW_SECONDS`: defaults to `60`
5. Add the service-account JSON as a Cloudflare secret named
   `FIREBASE_SERVICE_ACCOUNT_JSON`.

### Dashboard steps

1. Open **Workers & Pages → Create → Worker** and name it
   `chat-app-push-api`.
2. In **Settings → Variables and Secrets**, add the four non-secret variables
   listed above. Add `FIREBASE_SERVICE_ACCOUNT_JSON` as a **Secret**, not a
   plain-text variable.
3. Deploy the Worker source from this directory using the commands below.
4. The client API endpoint is set in
   `lib/core/constants/api_constants.dart`.
5. For web clients, add only the exact production origins (scheme and host) to
   `ALLOWED_ORIGINS`. CORS is not an authentication control.

### Wrangler deployment

From the repository root:

```sh
cd cloudflare-worker
npm install
npx wrangler login
npx wrangler secret put FIREBASE_SERVICE_ACCOUNT_JSON
npx wrangler deploy
```

Paste the JSON key contents when prompted for the secret. Wrangler uploads it as
a Cloudflare secret; it is not placed in `wrangler.toml`.

To change the application origins or limits, edit `[vars]` in `wrangler.toml`
and deploy again. The default `MAX_NOTIFICATION_RECIPIENTS` of `30` keeps a
single notification run within conservative Worker limits. Higher-quota
accounts may raise it, up to `400`. A group larger than the
configured maximum still saves its chat message; the Worker returns a generic
`413` and does not send notifications for that message.

## Flutter setup

Build/run with the deployed Worker URL:

```sh
flutter run
```

The Flutter API URL is configured in
`lib/core/constants/api_constants.dart`; no build define is required. Do not
define any service-account values in Flutter.

The app prompts for notification permission after sign-in, stores each device
token in `fcmTokens/{sha256(uid:token)}`, updates it on token refresh, and removes
the current device's token on sign-out. Android and Apple platform push
credentials/APNs configuration must also be set up in Firebase Console.

Visible notification behavior is platform-specific:

- In the foreground, Flutter handles `onMessage` and displays one local
  notification. iOS foreground presentation from FCM is disabled to prevent a
  duplicate.
- In the background or when terminated, FCM displays the notification payload
  using Android's `group_chat_messages` channel or the APNs alert payload. Taps
  open the group; both remote and local-notification launch paths are handled.
- The Android channel is created at app startup. Android 13+ notification
  permission must be granted by the user.
- For iOS, enable **Push Notifications** for the Runner App ID in Apple
  Developer, configure an APNs authentication key in Firebase Console, and
  enable the capability for the Runner target in Xcode. Visible alert
  notifications do not require silent/background notification mode.

The Worker sends the stored message's title/body and `groupId`/`messageId` to
each registered recipient device, with Android high priority and APNs alert
settings. Test with two devices signed in as different group members; send a
message from one and verify delivery in foreground, background, and after
terminating the recipient app from its app switcher. On Android, do not use
**Force stop** from system settings for this test: Android blocks FCM delivery
until the user opens a force-stopped app again. On iOS, force-quitting can defer
background data handlers; visible APNs alerts require valid APNs configuration
and granted notification permission.

## Existing-data migration

On the next signed-in app launch, the client migrates only its own records:

- It copies its own `fullName` and `profilePic` from `users/{uid}` to
  `users_public/{uid}` for client-side public profile display. The Worker reads
  the canonical `users/{uid}.fullName`.
- For groups whose `members` contains its UID, it creates its own
  `groups/{groupId}/members/{uid}` marker and copies non-sensitive search
  fields to `groupDirectory/{groupId}`.
- The Worker continues reading existing `users/{uid}.fcmToken` values while
  clients move to `fcmTokens`.

No service-account credential or bulk Admin SDK migration is needed. A group
appears in search after one of its existing members signs in and backfills its
directory record. Legacy membership strings of the form `uid_name` are
recognized by server authorization; the existing client query for groups uses
raw UIDs, so such legacy groups may need a manual membership cleanup.

The rules also make user documents private because they contain email addresses.
Group member names now load from `users_public`. Review the rules and existing
Firestore data before deployment; older documents with extra fields or
nonstandard shapes may require a deliberate migration.

Deploy the prototype rules only after reviewing them against your data:

```sh
firebase deploy --only firestore:rules --project chatapp-4a9e1
```

The dispatch record is an at-most-once claim created before FCM sends. It
prevents duplicate requests from sending twice, but a Worker crash after the
claim and before all FCM sends can leave a partial or missed notification; the
chat message remains safely stored. Reliable retry after partial delivery
requires a durable per-recipient outbox/queue.

## Local checks and tests

```sh
npm test
npx wrangler dev
```

The tests use mocked Firebase/FCM HTTP responses and do not send real push
notifications. `wrangler dev` requires the same secret to be supplied locally;
use an ignored `.dev.vars` file only for local development and never commit it.

The integration tests cover authenticated sends, sender exclusion, missing and
invalid authentication, non-member authorization, spoofed fields, invalid
tokens, idempotency, and missing Firestore documents. Real delivery also
requires Firebase Authentication, Firestore, FCM, Cloudflare, and device
credentials to be configured.
