import {
  customFetch,
  createRemoteJWKSet,
  importPKCS8,
  jwtVerify,
  SignJWT,
} from 'jose';

const FIREBASE_JWKS = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
  { [customFetch]: (url, options) => globalThis.fetch(url, options) },
);
const OAUTH_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const FIRESTORE_SCOPE = 'https://www.googleapis.com/auth/datastore';
const MAX_BODY_BYTES = 2048;
const MAX_GROUP_ID_LENGTH = 128;
const MAX_MESSAGE_ID_LENGTH = 128;
const MAX_FCM_TOKENS = 400;
const MAX_NOTIFICATION_BODY_BYTES = 3000;
const TOKEN_QUERY_UID_LIMIT = 30;
const FCM_CONCURRENCY = 8;

let cachedAccessToken;

class HttpError extends Error {
  constructor(status, publicCode) {
    super(publicCode);
    this.status = status;
    this.publicCode = publicCode;
  }
}

class BackendError extends Error { }

function jsonResponse(body, status, corsHeaders) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      ...corsHeaders,
    },
  });
}

function corsHeadersFor(request, env) {
  const origin = request.headers.get('Origin');
  if (!origin) return {};
  const allowedOrigins = (env.ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
  if (!allowedOrigins.includes(origin)) {
    throw new HttpError(403, 'origin_not_allowed');
  }
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Max-Age': '600',
    Vary: 'Origin',
  };
}

async function parseRequestBody(request) {
  const contentType = request.headers.get('Content-Type') ?? '';
  if (contentType.split(';', 1)[0].trim().toLowerCase() !== 'application/json') {
    throw new HttpError(415, 'unsupported_media_type');
  }
  const contentLength = Number(request.headers.get('Content-Length') ?? 0);
  if (contentLength > MAX_BODY_BYTES) {
    throw new HttpError(413, 'request_too_large');
  }
  const body = await request.arrayBuffer();
  if (body.byteLength > MAX_BODY_BYTES) {
    throw new HttpError(413, 'request_too_large');
  }

  let value;
  try {
    value = JSON.parse(new TextDecoder().decode(body));
  } catch {
    throw new HttpError(400, 'invalid_request');
  }
  if (
    value === null ||
    typeof value !== 'object' ||
    Array.isArray(value) ||
    Object.keys(value).length !== 2 ||
    !Object.hasOwn(value, 'groupId') ||
    !Object.hasOwn(value, 'messageId')
  ) {
    throw new HttpError(400, 'invalid_request');
  }

  const idPattern = /^[A-Za-z0-9_-]{1,128}$/;
  if (
    typeof value.groupId !== 'string' ||
    value.groupId.length > MAX_GROUP_ID_LENGTH ||
    !idPattern.test(value.groupId) ||
    typeof value.messageId !== 'string' ||
    value.messageId.length > MAX_MESSAGE_ID_LENGTH ||
    !idPattern.test(value.messageId)
  ) {
    throw new HttpError(400, 'invalid_request');
  }
  return { groupId: value.groupId, messageId: value.messageId };
}

async function verifyFirebaseIdToken(request, projectId) {
  const authorization = request.headers.get('Authorization') ?? '';
  const match = /^Bearer ([^\s]+)$/i.exec(authorization);
  if (!match) throw new HttpError(401, 'unauthenticated');

  try {
    const { payload } = await jwtVerify(match[1], FIREBASE_JWKS, {
      algorithms: ['RS256'],
      audience: projectId,
      issuer: `https://securetoken.google.com/${projectId}`,
      requiredClaims: ['sub', 'iat', 'exp', 'aud', 'iss'],
    });
    if (
      typeof payload.sub !== 'string' ||
      payload.sub.length === 0 ||
      payload.sub.length > 128
    ) {
      throw new Error('Invalid subject');
    }
    return payload.sub;
  } catch {
    throw new HttpError(401, 'unauthenticated');
  }
}


function getServiceAccount(env) {
  const raw = env.FIREBASE_SERVICE_ACCOUNT_JSON;

  if (!raw) {
    console.error('SERVICE_ACCOUNT_CHECK: secret is missing or empty');
    throw new BackendError();
  }

  let account;

  try {
    account = JSON.parse(raw);
  } catch (error) {
    console.error(
      'SERVICE_ACCOUNT_CHECK: invalid JSON',
      error?.message
    );
    throw new BackendError();
  }

  if (!account || typeof account !== 'object') {
    console.error('SERVICE_ACCOUNT_CHECK: invalid JSON structure');
    throw new BackendError();
  }

  const checks = {
    project_id_exists: typeof account.project_id === 'string',
    client_email_exists: typeof account.client_email === 'string',
    private_key_exists: typeof account.private_key === 'string',
    project_id_matches:
      account.project_id === env.FIREBASE_PROJECT_ID,
    private_key_has_pem_header:
      typeof account.private_key === 'string' &&
      account.private_key.includes('-----BEGIN PRIVATE KEY-----'),
  };

  console.log('SERVICE_ACCOUNT_CHECK:', JSON.stringify(checks));

  if (Object.values(checks).some(value => !value)) {
    throw new BackendError();
  }

  return account;
}

async function getGoogleAccessToken(env) {
  const now = Math.floor(Date.now() / 1000);
  if (
    cachedAccessToken &&
    cachedAccessToken.projectId === env.FIREBASE_PROJECT_ID &&
    cachedAccessToken.expiresAt > now + 60
  ) {
    return cachedAccessToken.token;
  }

  const account = getServiceAccount(env);
  let signingKey;
  try {
    signingKey = await importPKCS8(account.private_key, 'RS256');
  } catch {
    throw new BackendError();
  }
  const assertion = await new SignJWT({
    scope: `${FCM_SCOPE} ${FIRESTORE_SCOPE}`,
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(account.client_email)
    .setSubject(account.client_email)
    .setAudience(OAUTH_TOKEN_URL)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(signingKey);

  let response;
  try {
    response = await fetch(OAUTH_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }),
    });
  } catch {
    throw new BackendError();
  }
  if (!response.ok) throw new BackendError();
  let tokenResponse;
  try {
    tokenResponse = await response.json();
  } catch {
    throw new BackendError();
  }
  if (
    typeof tokenResponse.access_token !== 'string' ||
    typeof tokenResponse.expires_in !== 'number'
  ) {
    throw new BackendError();
  }
  cachedAccessToken = {
    projectId: env.FIREBASE_PROJECT_ID,
    token: tokenResponse.access_token,
    expiresAt: now + tokenResponse.expires_in,
  };
  return cachedAccessToken.token;
}

function encodeFirestoreDocumentPath(path) {
  return path
    .split('/')
    .map((segment) => encodeURIComponent(segment))
    .join('/');
}

function firestoreDocumentName(projectId, path) {
  const encodedPath = encodeFirestoreDocumentPath(path);
  return `projects/${encodeURIComponent(
    projectId,
  )}/databases/(default)/documents/${encodedPath}`;
}

function firestoreDocumentUrl(projectId, path, suffix = '') {
  const encodedPath = encodeFirestoreDocumentPath(path);
  const documentCollectionPath = encodedPath
    ? `/documents/${encodedPath}`
    : '/documents';
  return `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(
    projectId,
  )}/databases/(default)${documentCollectionPath}${suffix}`;
}

function firestoreValue(value) {
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'number' && Number.isInteger(value)) {
    return { integerValue: String(value) };
  }
  if (typeof value === 'boolean') return { booleanValue: value };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(firestoreValue) } };
  }
  throw new BackendError();
}

function decodeFirestoreValue(value) {
  if (Object.hasOwn(value, 'stringValue')) return value.stringValue;
  if (Object.hasOwn(value, 'integerValue')) return Number(value.integerValue);
  if (Object.hasOwn(value, 'doubleValue')) return value.doubleValue;
  if (Object.hasOwn(value, 'booleanValue')) return value.booleanValue;
  if (Object.hasOwn(value, 'timestampValue')) return value.timestampValue;
  if (Object.hasOwn(value, 'arrayValue')) {
    return (value.arrayValue.values ?? []).map(decodeFirestoreValue);
  }
  if (Object.hasOwn(value, 'mapValue')) {
    return decodeFirestoreFields(value.mapValue.fields ?? {});
  }
  return null;
}

function decodeFirestoreFields(fields = {}) {
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => [
      key,
      decodeFirestoreValue(value),
    ]),
  );
}

async function firestoreGet(env, accessToken, path) {
  let response;
  try {
    response = await fetch(firestoreDocumentUrl(env.FIREBASE_PROJECT_ID, path), {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
  } catch {
    throw new BackendError();
  }
  if (response.status === 404) return null;
  if (!response.ok) throw new BackendError();
  let document;
  try {
    document = await response.json();
  } catch {
    throw new BackendError();
  }
  return {
    fields: decodeFirestoreFields(document.fields ?? {}),
    name: document.name,
    updateTime: document.updateTime,
  };
}

async function firestoreCommit(env, accessToken, writes) {
  let response;

  try {
    response = await fetch(
      firestoreDocumentUrl(env.FIREBASE_PROJECT_ID, '', ':commit'),
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ writes }),
      },
    );
  } catch (error) {
    console.error(
      'FIRESTORE_COMMIT_NETWORK_ERROR:',
      error?.name,
      error?.message,
    );
    throw new BackendError();
  }

  if (!response.ok) {
    let firestoreMessage = response.statusText;
    try {
      const errorBody = await response.json();
      if (typeof errorBody?.error?.message === 'string') {
        firestoreMessage = errorBody.error.message;
      }
    } catch (error) {
      console.error(
        'FIRESTORE_COMMIT_ERROR_BODY_INVALID:',
        error?.name,
      );
    }

    console.error(
      'FIRESTORE_COMMIT_FAILED:',
      JSON.stringify({
        status: response.status,
        statusText: response.statusText,
        message: firestoreMessage.slice(0, 1200),
      }),
    );

    if (response.status === 409) return false;

    throw new BackendError();
  }

  return true;
}

async function applyRateLimit(env, accessToken, uid) {
  const maximum = parseBoundedInteger(env.RATE_LIMIT_REQUESTS, 20, 1, 1000);
  const windowSeconds = parseBoundedInteger(
    env.RATE_LIMIT_WINDOW_SECONDS,
    60,
    1,
    3600,
  );
  const path = `notificationRateLimits/${uid}`;
  const now = Date.now();

  for (let attempt = 0; attempt < 4; attempt += 1) {
    const current = await firestoreGet(env, accessToken, path);
    const previousWindow = current
      ? Date.parse(current.fields.windowStartedAt)
      : 0;
    const sameWindow =
      Number.isFinite(previousWindow) &&
      now - previousWindow < windowSeconds * 1000;
    const count = sameWindow ? current.fields.count : 0;
    if (!Number.isInteger(count) || count < 0) throw new BackendError();
    if (count >= maximum) return false;

    const fields = {
      uid: firestoreValue(uid),
      count: firestoreValue(count + 1),
      windowStartedAt: firestoreValue(
        new Date(sameWindow ? previousWindow : now),
      ),
    };
    const write = {
      update: {
        name: firestoreDocumentName(env.FIREBASE_PROJECT_ID, path),
        fields,
      },
      updateMask: {
        fieldPaths: ['uid', 'count', 'windowStartedAt'],
      },
      currentDocument: current
        ? { updateTime: current.updateTime }
        : { exists: false },
    };
    if (await firestoreCommit(env, accessToken, [write])) return true;
  }
  throw new BackendError();
}

function isGroupMember(members, uid) {
  return (
    Array.isArray(members) &&
    members.some(
      (member) =>
        typeof member === 'string' &&
        (member === uid || member.startsWith(`${uid}_`)),
    )
  );
}

function normalizeMemberUid(member) {
  if (typeof member !== 'string') return null;
  const separator = member.indexOf('_');
  return separator === -1 ? member : member.slice(0, separator);
}

async function claimMessageDispatch(env, accessToken, message) {
  if (message.fields.pushDispatchStatus === 'claimed') return false;
  const created = await firestoreCommit(env, accessToken, [
    {
      update: {
        name: message.name,
        fields: {
          pushDispatchStatus: firestoreValue('claimed'),
          pushDispatchClaimedAt: firestoreValue(new Date()),
        },
      },
      updateMask: {
        fieldPaths: ['pushDispatchStatus', 'pushDispatchClaimedAt'],
      },
      currentDocument: { updateTime: message.updateTime },
    },
  ]);
  return created;
}

async function batchGetDocuments(env, accessToken, paths) {
  if (paths.length === 0) return new Map();
  let response;
  try {
    response = await fetch(
      firestoreDocumentUrl(env.FIREBASE_PROJECT_ID, '', ':batchGet'),
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ documents: paths }),
      },
    );
  } catch {
    throw new BackendError();
  }
  if (!response.ok) throw new BackendError();
  let records;
  try {
    records = await response.json();
  } catch {
    throw new BackendError();
  }
  const documents = new Map();
  for (const record of records) {
    if (record.found) {
      documents.set(record.found.name, {
        fields: decodeFirestoreFields(record.found.fields ?? {}),
        name: record.found.name,
        updateTime: record.found.updateTime,
      });
    }
  }
  return documents;
}

async function queryDeviceTokens(env, accessToken, uids) {
  const tokens = [];
  for (let start = 0; start < uids.length; start += TOKEN_QUERY_UID_LIMIT) {
    const uidBatch = uids.slice(start, start + TOKEN_QUERY_UID_LIMIT);
    let response;
    try {
      response = await fetch(
        firestoreDocumentUrl(env.FIREBASE_PROJECT_ID, '', ':runQuery'),
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            structuredQuery: {
              from: [{ collectionId: 'fcmTokens' }],
              where: {
                fieldFilter: {
                  field: { fieldPath: 'uid' },
                  op: 'IN',
                  value: {
                    arrayValue: {
                      values: uidBatch.map((uid) => firestoreValue(uid)),
                    },
                  },
                },
              },
              limit: MAX_FCM_TOKENS,
            },
          }),
        },
      );
    } catch {
      throw new BackendError();
    }
    if (!response.ok) throw new BackendError();
    let records;
    try {
      records = await response.json();
    } catch {
      throw new BackendError();
    }
    if (records.length >= MAX_FCM_TOKENS) {
      throw new HttpError(413, 'too_many_devices');
    }
    for (const record of records) {
      if (!record.document) continue;
      const fields = decodeFirestoreFields(record.document.fields ?? {});
      if (
        uidBatch.includes(fields.uid) &&
        typeof fields.token === 'string' &&
        fields.token.length > 0 &&
        fields.token.length <= 4096
      ) {
        tokens.push({
          uid: fields.uid,
          token: fields.token,
          documentPath: tokenDocumentPath(record.document.name),
        });
      }
    }
  }
  return tokens;
}

function tokenDocumentPath(documentName) {
  const marker = '/documents/';
  const index = documentName.indexOf(marker);
  return index < 0 ? null : documentName.slice(index + marker.length);
}

async function sendFcmMessage(env, accessToken, token, payload) {
  let response;
  try {
    response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(
        env.FIREBASE_PROJECT_ID,
      )}/messages:send`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token,
            notification: {
              title: payload.title,
              body: payload.body,
            },
            data: payload.data,
            android: {
              priority: 'HIGH',
              notification: {
                channel_id: 'group_chat_messages',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                sound: 'default',
              },
            },
            apns: {
              headers: {
                'apns-push-type': 'alert',
                'apns-priority': '10',
              },
              payload: {
                aps: {
                  alert: {
                    title: payload.title,
                    body: payload.body,
                  },
                  sound: 'default',
                },
              },
            },
          },
        }),
      },
    );
  } catch {
    return { sent: false, invalid: false };
  }

  if (response.ok) return { sent: true, invalid: false };
  if (response.status === 404) return { sent: false, invalid: true };
  if (response.status !== 400) return { sent: false, invalid: false };

  try {
    const error = await response.json();
    const fcmError = error.error?.details?.find(
      (detail) =>
        detail['@type'] ===
        'type.googleapis.com/google.firebase.fcm.v1.FcmError',
    );
    return {
      sent: false,
      invalid: fcmError?.errorCode === 'UNREGISTERED',
    };
  } catch {
    return { sent: false, invalid: false };
  }
}

async function mapWithConcurrency(items, concurrency, callback) {
  const results = [];
  for (let start = 0; start < items.length; start += concurrency) {
    results.push(
      ...(await Promise.all(
        items.slice(start, start + concurrency).map(callback),
      )),
    );
  }
  return results;
}

async function removeInvalidTokens(env, accessToken, devices) {
  const writes = [];
  for (const device of devices) {
    for (const path of device.deviceDocuments) {
      if (path) {
        writes.push({
          delete: firestoreDocumentName(env.FIREBASE_PROJECT_ID, path),
        });
      }
    }
    for (const legacy of device.legacyDocuments) {
      writes.push({
        update: {
          name: firestoreDocumentName(
            env.FIREBASE_PROJECT_ID,
            `users/${legacy.uid}`,
          ),
          fields: {},
        },
        updateMask: { fieldPaths: ['fcmToken'] },
        currentDocument: { updateTime: legacy.updateTime },
      });
    }
  }
  if (writes.length === 0) return;
  for (let start = 0; start < writes.length; start += 450) {
    const succeeded = await firestoreCommit(
      env,
      accessToken,
      writes.slice(start, start + 450),
    );
    if (!succeeded) {
      console.error('Unable to remove one or more stale FCM tokens.');
    }
  }
}

async function collectRecipientTokens(
  env,
  accessToken,
  members,
  senderId,
) {
  const recipientUids = [
    ...new Set(
      members
        .map(normalizeMemberUid)
        .filter(
          (uid) =>
            typeof uid === 'string' && uid.length > 0 && uid !== senderId,
        ),
    ),
  ];
  const maximumRecipients = parseBoundedInteger(
    env.MAX_NOTIFICATION_RECIPIENTS,
    30,
    1,
    400,
  );
  if (recipientUids.length > maximumRecipients) {
    throw new HttpError(413, 'group_too_large');
  }
  if (recipientUids.length === 0) {
    return { recipientCount: 0, devices: [] };
  }

  const accountPaths = recipientUids.map(
    (uid) => `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${uid}`,
  );
  const accounts = await batchGetDocuments(env, accessToken, accountPaths);
  const recipients = new Set(recipientUids);
  const tokens = await queryDeviceTokens(env, accessToken, recipientUids);

  for (const uid of recipientUids) {
    const accountPath = `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${uid}`;
    const legacyToken = accounts.get(accountPath)?.fields.fcmToken;
    if (
      typeof legacyToken === 'string' &&
      legacyToken.length > 0 &&
      legacyToken.length <= 4096
    ) {
      tokens.push({
        uid,
        token: legacyToken,
        documentPath: null,
        legacyUpdateTime: accounts.get(accountPath)?.updateTime,
      });
    }
  }

  const uniqueTokens = new Map();
  for (const device of tokens) {
    if (!recipients.has(device.uid)) continue;
    const existing = uniqueTokens.get(device.token);
    if (existing) {
      existing.deviceDocuments.push(device.documentPath);
      if (device.legacyUpdateTime) {
        existing.legacyDocuments.push({
          uid: device.uid,
          updateTime: device.legacyUpdateTime,
        });
      }
    } else {
      uniqueTokens.set(device.token, {
        ...device,
        deviceDocuments: [device.documentPath],
        legacyDocuments: device.legacyUpdateTime
          ? [{ uid: device.uid, updateTime: device.legacyUpdateTime }]
          : [],
      });
    }
  }
  if (uniqueTokens.size > MAX_FCM_TOKENS) {
    throw new HttpError(413, 'too_many_devices');
  }

  return {
    recipientCount: recipientUids.length,
    devices: [...uniqueTokens.values()],
  };
}

async function deliverNotifications(
  env,
  accessToken,
  recipientDevices,
  payload,
) {
  const results = await mapWithConcurrency(
    recipientDevices.devices,
    FCM_CONCURRENCY,
    async (device) => ({
      device,
      result: await sendFcmMessage(env, accessToken, device.token, payload),
    }),
  );
  await removeInvalidTokens(
    env,
    accessToken,
    results
      .filter(({ result }) => result.invalid)
      .map(({ device }) => device),
  );
  const sentCount = results.filter(({ result }) => result.sent).length;
  return {
    recipientCount: recipientDevices.recipientCount,
    sentCount,
    failedCount: results.length - sentCount,
  };
}

function parseBoundedInteger(value, fallback, minimum, maximum) {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed >= minimum && parsed <= maximum
    ? parsed
    : fallback;
}

function truncateUtf8(value, maximumBytes) {
  const encoder = new TextEncoder();
  let result = '';
  let byteLength = 0;
  for (const character of value) {
    const characterLength = encoder.encode(character).byteLength;
    if (byteLength + characterLength > maximumBytes) break;
    result += character;
    byteLength += characterLength;
  }
  return result;
}

async function handleAuthenticatedRequest(request, env) {
  const { groupId, messageId } = await parseRequestBody(request);
  const uid = await verifyFirebaseIdToken(request, env.FIREBASE_PROJECT_ID);
  const accessToken = await getGoogleAccessToken(env);
  if (!(await applyRateLimit(env, accessToken, uid))) {
    throw new HttpError(429, 'rate_limited');
  }

  const [group, message] = await Promise.all([
    firestoreGet(env, accessToken, `groups/${groupId}`),
    firestoreGet(env, accessToken, `groups/${groupId}/messages/${messageId}`),
  ]);
  if (!group || !message) throw new HttpError(404, 'resource_not_found');
  if (!isGroupMember(group.fields.members, uid)) {
    throw new HttpError(404, 'resource_not_found');
  }
  if (message.fields.senderId !== uid) {
    throw new HttpError(403, 'forbidden');
  }
  if (message.fields.groupId !== groupId) {
    throw new HttpError(404, 'resource_not_found');
  }

  const senderNameDocument = await firestoreGet(
    env,
    accessToken,
    `users/${uid}`,
  );
  const senderName = senderNameDocument?.fields.fullName;
  const messageText = message.fields.message;
  const groupName = group.fields.groupName;
  if (
    typeof senderName !== 'string' ||
    senderName.length === 0 ||
    senderName.length > 80 ||
    typeof messageText !== 'string' ||
    messageText.length === 0 ||
    messageText.length > 4000 ||
    typeof groupName !== 'string' ||
    groupName.length === 0 ||
    groupName.length > 80 ||
    !Array.isArray(group.fields.members)
  ) {
    throw new HttpError(404, 'resource_not_found');
  }

  const recipients = group.fields.members.filter(
    (member) =>
      typeof member === 'string' && normalizeMemberUid(member) !== uid,
  );
  const maximumRecipients = parseBoundedInteger(
    env.MAX_NOTIFICATION_RECIPIENTS,
    30,
    1,
    400,
  );
  if (new Set(recipients.map(normalizeMemberUid)).size > maximumRecipients) {
    throw new HttpError(413, 'group_too_large');
  }
  if (message.fields.pushDispatchStatus === 'claimed') {
    return { status: 'duplicate', recipientCount: 0, sentCount: 0 };
  }

  const recipientDevices = await collectRecipientTokens(
    env,
    accessToken,
    group.fields.members,
    uid,
  );
  if (!(await claimMessageDispatch(env, accessToken, message))) {
    return { status: 'duplicate', recipientCount: 0, sentCount: 0 };
  }

  const result = await deliverNotifications(
    env,
    accessToken,
    recipientDevices,
    {
      title: groupName,
      body: truncateUtf8(
        `${senderName}: ${messageText}`,
        MAX_NOTIFICATION_BODY_BYTES,
      ),
      data: {
        groupId,
        messageId,
        senderId: uid,
      },
    },
  );
  return { status: 'processed', ...result };
}

export default {
  async fetch(request, env) {
    let corsHeaders = {};
    try {
      corsHeaders = corsHeadersFor(request, env);
      if (request.method === 'OPTIONS') {
        return new Response(null, { status: 204, headers: corsHeaders });
      }
      if (request.method !== 'POST') {
        throw new HttpError(405, 'method_not_allowed');
      }
      const result = await handleAuthenticatedRequest(request, env);
      return jsonResponse(result, 200, corsHeaders);
    } catch (error) {
      if (error instanceof HttpError) {
        if (error.status >= 500) {
          console.error(
            'Push HTTP error:',
            error.status,
            error.publicCode
          );
        }

        return jsonResponse(
          { error: error.publicCode },
          error.status,
          corsHeaders
        );
      }

      console.error(
        'Push request failed:',
        error?.name,
        error?.message,
        error?.stack
      );

      return jsonResponse(
        { error: 'service_unavailable' },
        503,
        corsHeaders
      );
    }
  },
};

export {
  decodeFirestoreFields,
  decodeFirestoreValue,
  firestoreDocumentName,
  firestoreDocumentUrl,
};
