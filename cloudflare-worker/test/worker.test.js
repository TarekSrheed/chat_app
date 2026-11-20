import assert from 'node:assert/strict';
import { generateKeyPairSync } from 'node:crypto';
import { after, before, beforeEach, test } from 'node:test';
import { importPKCS8, SignJWT } from 'jose';

import worker, {
  firestoreDocumentName,
  firestoreDocumentUrl,
} from '../src/index.js';

const projectId = 'chatapp-4a9e1';
const firebaseSigningKey = generateKeyPairSync('rsa', { modulusLength: 2048 });
const serviceAccountKey = generateKeyPairSync('rsa', { modulusLength: 2048 });
const firebasePublicJwk = {
  ...firebaseSigningKey.publicKey.export({ format: 'jwk' }),
  alg: 'RS256',
  kid: 'worker-test-key',
  use: 'sig',
};
const firebasePrivateKey = await importPKCS8(
  firebaseSigningKey.privateKey.export({
    type: 'pkcs8',
    format: 'pem',
  }),
  'RS256',
);

let originalFetch;
let group;
let message;
let documents;
let fcmRequests;
let invalidToken;
let fetchPathLog;
let firestoreCommitFailure;
let deviceTokensForQuery;
let legacyTokenForRecipient;

const env = {
  FIREBASE_PROJECT_ID: projectId,
  FIREBASE_SERVICE_ACCOUNT_JSON: JSON.stringify({
    project_id: projectId,
    client_email: 'push-worker@test.iam.gserviceaccount.com',
    private_key: serviceAccountKey.privateKey.export({
      type: 'pkcs8',
      format: 'pem',
    }),
  }),
  ALLOWED_ORIGINS: '',
  MAX_NOTIFICATION_RECIPIENTS: '30',
  RATE_LIMIT_REQUESTS: '20',
  RATE_LIMIT_WINDOW_SECONDS: '60',
};

function encodeValue(value) {
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'number') return { integerValue: String(value) };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(encodeValue) } };
  }
  return { booleanValue: value };
}

function encodeFields(fields) {
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => [key, encodeValue(value)]),
  );
}

function firestoreDocument(path, fields) {
  return {
    name: `projects/${projectId}/databases/(default)/documents/${path}`,
    fields: encodeFields(fields),
    updateTime: new Date().toISOString(),
  };
}

test('Firestore document URLs and resource names encode path segments once', () => {
  const path = 'groups/group id/messages/message-1';
  assert.equal(
    firestoreDocumentUrl(projectId, path),
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/groups/group%20id/messages/message-1`,
  );
  assert.equal(
    firestoreDocumentName(projectId, path),
    `projects/${projectId}/databases/(default)/documents/groups/group%20id/messages/message-1`,
  );
  assert.ok(!firestoreDocumentUrl(projectId, path).includes('%2520'));
  assert.ok(!firestoreDocumentName(projectId, path).includes('%2520'));
  assert.equal(
    firestoreDocumentUrl(projectId, '', ':runQuery'),
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:runQuery`,
  );
});

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

async function firebaseToken(uid = 'sender-1', signingKey = firebasePrivateKey) {
  return new SignJWT({})
    .setProtectedHeader({ alg: 'RS256', kid: 'worker-test-key' })
    .setIssuer(`https://securetoken.google.com/${projectId}`)
    .setAudience(projectId)
    .setSubject(uid)
    .setIssuedAt()
    .setExpirationTime('5m')
    .sign(signingKey);
}

async function fakeFetch(urlValue, init = {}) {
  const url = new URL(urlValue);
  const method = init.method ?? 'GET';
  fetchPathLog.push(`${method} ${url.hostname}${url.pathname}`);

  if (
    url.href.startsWith(
      'https://www.googleapis.com/service_accounts/v1/jwk/',
    )
  ) {
    return jsonResponse({ keys: [firebasePublicJwk] });
  }
  if (url.href === 'https://oauth2.googleapis.com/token') {
    return jsonResponse({ access_token: 'fake-access-token', expires_in: 3600 });
  }
  if (url.hostname === 'fcm.googleapis.com') {
    const body = JSON.parse(init.body);
    fcmRequests.push(body);
    if (body.message.token === invalidToken) {
      return jsonResponse({ error: { status: 'NOT_FOUND' } }, 404);
    }
    return jsonResponse({ name: 'projects/chatapp-4a9e1/messages/test-id' });
  }
  if (url.hostname !== 'firestore.googleapis.com') {
    throw new Error(`Unexpected request: ${url.href}`);
  }

  const documentsIndex = url.pathname.indexOf('/documents');
  let endpoint = url.pathname.slice(documentsIndex + '/documents'.length);
  if (endpoint.startsWith('/')) endpoint = endpoint.slice(1);
  if (endpoint === ':commit' && method === 'POST') {
    if (firestoreCommitFailure) {
      return jsonResponse(
        { error: { code: 400, message: firestoreCommitFailure } },
        400,
      );
    }
    const body = JSON.parse(init.body);
    for (const write of body.writes) {
      const resourcePrefix = `projects/${projectId}/databases/(default)/documents/`;
      const resourceName = write.update?.name ?? write.delete;
      assert.equal(typeof resourceName, 'string');
      assert.ok(
        resourceName.startsWith(resourcePrefix),
        `Commit write must use a Firestore resource name: ${resourceName}`,
      );
      const path = resourceName.slice(resourcePrefix.length);
      if (write.delete) {
        documents.delete(path);
        continue;
      }
      if (write.currentDocument?.exists === false && documents.has(path)) {
        return jsonResponse({ error: { status: 'ALREADY_EXISTS' } }, 409);
      }
      if (write.currentDocument?.updateTime) {
        const existing = documents.get(path);
        if (!existing || existing.updateTime !== write.currentDocument.updateTime) {
          return jsonResponse({ error: { status: 'ABORTED' } }, 409);
        }
      }

      const existing = documents.get(path);
      const fields = existing?.fields ?? {};
      for (const [field, value] of Object.entries(write.update.fields ?? {})) {
        fields[field] = value;
      }
      for (const field of write.updateMask?.fieldPaths ?? []) {
        if (!Object.hasOwn(write.update.fields ?? {}, field)) delete fields[field];
      }
      documents.set(path, {
        ...firestoreDocument(path, {}),
        fields,
        updateTime: new Date().toISOString(),
      });
    }
    return jsonResponse({ writeResults: [] });
  }

  if (endpoint === ':batchGet' && method === 'POST') {
    const paths = JSON.parse(init.body).documents.map((name) =>
      name.split('/documents/')[1],
    );
    return jsonResponse(
      paths.map((path) => {
        const fields =
          path === 'users/recipient-1' && legacyTokenForRecipient
            ? { fcmToken: legacyTokenForRecipient }
            : {};
        const found = firestoreDocument(path, fields);
        documents.set(path, found);
        return { found };
      }),
    );
  }

  if (endpoint === ':runQuery' && method === 'POST') {
    return jsonResponse(deviceTokensForQuery.map((document) => ({ document })));
  }

  if (endpoint.startsWith('groups/')) {
    const path = endpoint;
    if (path === 'groups/group-1') {
      return group
        ? jsonResponse(firestoreDocument(path, group))
        : jsonResponse({ error: { status: 'NOT_FOUND' } }, 404);
    }
    if (path === 'groups/group-1/messages/message-1') {
      if (!message) return jsonResponse({ error: { status: 'NOT_FOUND' } }, 404);
      let storedMessage = documents.get(path);
      if (!storedMessage) {
        storedMessage = firestoreDocument(path, message);
        documents.set(path, storedMessage);
      }
      return jsonResponse(storedMessage);
    }
  }
  if (endpoint === 'users/sender-1') {
    return jsonResponse(
      firestoreDocument(endpoint, { fullName: 'Group Sender' }),
    );
  }
  if (endpoint.startsWith('notificationRateLimits/')) {
    const existing = documents.get(endpoint);
    return existing
      ? jsonResponse(existing)
      : jsonResponse({ error: { status: 'NOT_FOUND' } }, 404);
  }
  throw new Error(`Unexpected Firestore request: ${method} ${endpoint}`);
}

async function makeRequest({
  uid = 'sender-1',
  token = null,
  body = { groupId: 'group-1', messageId: 'message-1' },
  method = 'POST',
  headers = {},
} = {}) {
  const authorizationToken = token ?? (await firebaseToken(uid));
  const requestHeaders = new Headers(headers);
  requestHeaders.set('Content-Type', 'application/json');
  if (authorizationToken) {
    requestHeaders.set('Authorization', `Bearer ${authorizationToken}`);
  }
  return worker.fetch(
    new Request('https://worker.example/notify', {
      method,
      headers: requestHeaders,
      body: method === 'POST' ? JSON.stringify(body) : undefined,
    }),
    env,
  );
}

before(() => {
  originalFetch = globalThis.fetch;
  globalThis.fetch = fakeFetch;
});

beforeEach(() => {
  group = {
    groupId: 'group-1',
    groupName: 'Test Group',
    members: ['sender-1', 'recipient-1'],
  };
  message = {
    groupId: 'group-1',
    senderId: 'sender-1',
    sender: 'Group Sender',
    message: 'Hello group',
    time: Date.now(),
  };
  documents = new Map();
  fcmRequests = [];
  invalidToken = null;
  fetchPathLog = [];
  firestoreCommitFailure = null;
  deviceTokensForQuery = [];
  legacyTokenForRecipient = 'valid-recipient-token';
});

after(() => {
  globalThis.fetch = originalFetch;
});

test('authenticated member sends from the stored message', async () => {
  const response = await makeRequest();
  assert.equal(response.status, 200, fetchPathLog.join('\n'));
  const body = await response.json();
  assert.equal(body.sentCount, 1);
  assert.equal(fcmRequests.length, 1);
  assert.equal(fcmRequests[0].message.notification.title, 'Test Group');
  assert.equal(fcmRequests[0].message.notification.body, 'Group Sender: Hello group');
  assert.deepEqual(fcmRequests[0].message.data, {
    groupId: 'group-1',
    messageId: 'message-1',
    senderId: 'sender-1',
  });
  assert.equal(fcmRequests[0].message.android.priority, 'HIGH');
  assert.equal(
    fcmRequests[0].message.android.notification.channel_id,
    'group_chat_messages',
  );
  assert.equal(
    fcmRequests[0].message.android.notification.click_action,
    'FLUTTER_NOTIFICATION_CLICK',
  );
  assert.deepEqual(fcmRequests[0].message.apns.headers, {
    'apns-push-type': 'alert',
    'apns-priority': '10',
  });
  assert.deepEqual(fcmRequests[0].message.apns.payload.aps, {
    alert: { title: 'Test Group', body: 'Group Sender: Hello group' },
    sound: 'default',
  });
});

test('each registered recipient device gets the stored message payload', async () => {
  group.members = ['sender-1', 'recipient-1', 'recipient-2'];
  legacyTokenForRecipient = null;
  deviceTokensForQuery = [
    firestoreDocument('fcmTokens/device-1', {
      uid: 'recipient-1',
      token: 'recipient-one-token',
    }),
    firestoreDocument('fcmTokens/device-2', {
      uid: 'recipient-2',
      token: 'recipient-two-token',
    }),
    firestoreDocument('fcmTokens/sender-device', {
      uid: 'sender-1',
      token: 'sender-token',
    }),
  ];

  const response = await makeRequest();
  assert.equal(response.status, 200);
  assert.deepEqual(
    fcmRequests.map(({ message: sentMessage }) => sentMessage.token).sort(),
    ['recipient-one-token', 'recipient-two-token'],
  );
  for (const { message: sentMessage } of fcmRequests) {
    assert.equal(sentMessage.notification.title, 'Test Group');
    assert.equal(sentMessage.notification.body, 'Group Sender: Hello group');
    assert.deepEqual(sentMessage.data, {
      groupId: 'group-1',
      messageId: 'message-1',
      senderId: 'sender-1',
    });
  }
});

test('Firestore commit failures log status and message without the response body', async (context) => {
  firestoreCommitFailure = 'Invalid Firestore document resource name';
  const errorLogs = [];
  context.mock.method(console, 'error', (...args) => errorLogs.push(args));

  const response = await makeRequest();
  assert.equal(response.status, 503);
  const commitLog = errorLogs.find(([label]) => label === 'FIRESTORE_COMMIT_FAILED:');
  assert.ok(commitLog);
  const details = JSON.parse(commitLog[1]);
  assert.equal(details.status, 400);
  assert.equal(details.message, firestoreCommitFailure);
  assert.equal(Object.hasOwn(details, 'body'), false);
});

test('sender is excluded from notification recipients', async () => {
  group.members = ['sender-1', 'recipient-1'];
  const response = await makeRequest();
  assert.equal(response.status, 200);
  assert.equal(fcmRequests.length, 1);
  assert.equal(fcmRequests[0].message.token, 'valid-recipient-token');
});

test('unauthenticated requests are rejected', async () => {
  const response = await makeRequest({ token: '' });
  assert.equal(response.status, 401);
  assert.equal(fcmRequests.length, 0);
});

test('unsupported methods and disallowed browser origins are rejected', async (context) => {
  await context.test('unsupported method', async () => {
    const response = await makeRequest({ method: 'GET' });
    assert.equal(response.status, 405);
  });

  await context.test('disallowed origin', async () => {
    const response = await makeRequest({
      headers: { Origin: 'https://untrusted.example' },
    });
    assert.equal(response.status, 403);
  });
});

test('invalid Firebase ID tokens are rejected', async () => {
  const wrongKey = await importPKCS8(
    serviceAccountKey.privateKey.export({
      type: 'pkcs8',
      format: 'pem',
    }),
    'RS256',
  );
  const response = await makeRequest({ token: await firebaseToken('sender-1', wrongKey) });
  assert.equal(response.status, 401);
  assert.equal(fcmRequests.length, 0);
});

test('non-members cannot trigger notifications', async () => {
  const response = await makeRequest({ uid: 'outsider-1' });
  assert.equal(response.status, 404);
  assert.equal(fcmRequests.length, 0);
});

test('clients cannot spoof sender IDs or notification content', async () => {
  const response = await makeRequest({
    body: {
      groupId: 'group-1',
      messageId: 'message-1',
      senderId: 'recipient-1',
    },
  });
  assert.equal(response.status, 400);
  assert.equal(fcmRequests.length, 0);
});

test('invalid FCM tokens do not fail the whole request', async () => {
  invalidToken = 'valid-recipient-token';
  const deviceTokenDocument = firestoreDocument('fcmTokens/device-hash', {
    uid: 'recipient-1',
    token: invalidToken,
  });
  deviceTokensForQuery = [deviceTokenDocument];
  documents.set('fcmTokens/device-hash', deviceTokenDocument);

  const response = await makeRequest();
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.sentCount, 0);
  assert.equal(body.failedCount, 1);
  assert.equal(documents.has('fcmTokens/device-hash'), false);
  assert.equal(
    documents.get('users/recipient-1').fields.fcmToken,
    undefined,
  );
});

test('duplicate requests only dispatch once', async () => {
  const first = await makeRequest();
  const second = await makeRequest();
  assert.equal(first.status, 200);
  assert.equal(second.status, 200);
  assert.equal((await second.json()).status, 'duplicate');
  assert.equal(fcmRequests.length, 1);
  assert.equal(
    documents.get('groups/group-1/messages/message-1').fields
      .pushDispatchStatus.stringValue,
    'claimed',
  );
});

test('missing groups and messages return a safe not-found response', async (context) => {
  await context.test('missing group', async () => {
    group = null;
    const response = await makeRequest();
    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), { error: 'resource_not_found' });
  });

  await context.test('missing message', async () => {
    message = null;
    const response = await makeRequest();
    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), { error: 'resource_not_found' });
  });
});

test('message sender must match the authenticated Firebase UID', async () => {
  message.senderId = 'other-user';
  const response = await makeRequest();
  assert.equal(response.status, 403);
  assert.equal(fcmRequests.length, 0);
});

test('message must match the requested group path', async () => {
  message.groupId = 'another-group';
  const response = await makeRequest();
  assert.equal(response.status, 404);
  assert.equal(fcmRequests.length, 0);
});
