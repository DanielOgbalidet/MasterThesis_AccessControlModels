import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:10000';

const testCases = [
  {
    name: 'bob_read_docA1_green',
    user: 'bob',
    action: 'read',
    resource: 'docA1',
    expectedStatus: 200,
  },
  {
    name: 'anne_write_docA2_yellow',
    user: 'anne',
    action: 'write',
    resource: 'docA2',
    expectedStatus: 200,
  },
  {
    name: 'bob_write_docA2_yellow',
    user: 'bob',
    action: 'write',
    resource: 'docA2',
    expectedStatus: 403,
  },
  {
    name: 'anne_read_docA3_red',
    user: 'anne',
    action: 'read',
    resource: 'docA3',
    expectedStatus: 200,
  },
  {
    name: 'bob_read_docA3_red',
    user: 'bob',
    action: 'read',
    resource: 'docA3',
    expectedStatus: 403,
  },
  {
    name: 'mia_read_docB2_cross_project',
    user: 'mia',
    action: 'read',
    resource: 'docB2',
    expectedStatus: 200,
  },
  {
    name: 'mia_read_docB3_red_denied',
    user: 'mia',
    action: 'read',
    resource: 'docB3',
    expectedStatus: 403,
  },
  {
    name: 'managerA_read_docA2_yellow',
    user: 'managerA',
    action: 'read',
    resource: 'docA2',
    expectedStatus: 200,
  },
  {
    name: 'managerA_write_docA2_yellow',
    user: 'managerA',
    action: 'write',
    resource: 'docA2',
    expectedStatus: 403,
  },
  {
    name: 'managerB_read_docB3_red',
    user: 'managerB',
    action: 'read',
    resource: 'docB3',
    expectedStatus: 200,
  },
  {
    name: 'managerAll_read_docD4_black_valid',
    user: 'managerAll',
    action: 'read',
    resource: 'docD4',
    time: '10:00',
    location: 'office',
    expectedStatus: 200,
  },
  {
    name: 'managerAll_read_docD4_black_bad_time',
    user: 'managerAll',
    action: 'read',
    resource: 'docD4',
    time: '20:00',
    location: 'office',
    expectedStatus: 403,
  },
  {
    name: 'managerAll_read_docD4_black_bad_location',
    user: 'managerAll',
    action: 'read',
    resource: 'docD4',
    time: '10:00',
    location: 'home',
    expectedStatus: 403,
  },
  {
    name: 'managerAll_read_docA4_black_no_assignment',
    user: 'managerAll',
    action: 'read',
    resource: 'docA4',
    time: '10:00',
    location: 'office',
    expectedStatus: 403,
  },
];

export const options = {
  scenarios: {
    level4_test: {
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

  const headers = {
    'x-user-id': tc.user,
    'x-action': tc.action,
    'x-resource-id': tc.resource,
  };

  if (tc.time) {
    headers['x-time'] = tc.time;
  }

  if (tc.location) {
    headers['x-location'] = tc.location;
  }

  const res = http.get(`${BASE_URL}/anything`, {
    headers,
    tags: {
      testcase: tc.name,
      level: 'level4',
    },
  });

  check(res, {
    [`${tc.name} expected ${tc.expectedStatus}`]: (r) => r.status === tc.expectedStatus,
  });

  sleep(0.2);
}