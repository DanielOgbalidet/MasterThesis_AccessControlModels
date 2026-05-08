import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:10000';

const testCases = [
  {
    name: 'anne_write_docA1',
    user: 'anne',
    action: 'write',
    resource: 'docA1',
    expectedStatus: 200,
  },
  {
    name: 'bob_read_docA2',
    user: 'bob',
    action: 'read',
    resource: 'docA2',
    expectedStatus: 200,
  },
  {
    name: 'bob_write_docA1',
    user: 'bob',
    action: 'write',
    resource: 'docA1',
    expectedStatus: 403,
  },
  {
    name: 'dana_write_docB2',
    user: 'dana',
    action: 'write',
    resource: 'docB2',
    expectedStatus: 200,
  },
  {
    name: 'dana_write_docA1',
    user: 'dana',
    action: 'write',
    resource: 'docA1',
    expectedStatus: 403,
  },
];

export const options = {
  scenarios: {
    level2_test: {
      executor: 'constant-vus',
      vus: 5,
      duration: '30s',
    },
  },
  thresholds: {
    checks: ['rate>0.99'],
    http_req_duration: ['p(95)<1000', 'avg<500'],
  },
};

export default function () {
  const tc = testCases[Math.floor(Math.random() * testCases.length)];

  const res = http.get(`${BASE_URL}/anything`, {
    headers: {
      'x-user-id': tc.user,
      'x-action': tc.action,
      'x-resource-id': tc.resource,
    },
    tags: {
      testcase: tc.name,
      level: 'level2',
    },
  });

  check(res, {
    [`${tc.name} expected ${tc.expectedStatus}`]: (r) => r.status === tc.expectedStatus,
  });

  sleep(0.2);
}