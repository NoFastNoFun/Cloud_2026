import http from "k6/http";
import { check, sleep } from "k6";
import { Rate } from "k6/metrics";

const businessErrors = new Rate("business_errors");
const baseUrl = __ENV.BASE_URL || "http://localhost";
const loadProfile = (__ENV.LOAD_PROFILE || "full").toLowerCase();

const fullStages = [
  { duration: "5m", target: 1000 },
  { duration: "10m", target: 5000 },
  { duration: "15m", target: 20000 },
  { duration: "20m", target: 50000 },
  { duration: "20m", target: 70000 },
  { duration: "20m", target: 90000 },
  { duration: "30m", target: 90000 },
  { duration: "10m", target: 0 }
];

const quickStages = [
  { duration: "1m", target: 50 },
  { duration: "3m", target: 200 },
  { duration: "3m", target: 500 },
  { duration: "3m", target: 0 }
];

const selectedStages = loadProfile === "quick" ? quickStages : fullStages;
const startVUs = loadProfile === "quick" ? 10 : 100;
const defaultEndpoints = loadProfile === "quick" ? ["/"] : ["/", "/healthz", "/img/"];
const endpoints = (__ENV.ENDPOINTS || defaultEndpoints.join(","))
  .split(",")
  .map((e) => e.trim())
  .filter(Boolean);

const requestHeaders = {
  "User-Agent": __ENV.USER_AGENT || "Mozilla/5.0 (Windows NT 10.0; Win64; x64) k6-load-test",
  Accept: "text/html,application/json,*/*"
};

export const options = {
  scenarios: {
    black_friday_ramp: {
      executor: "ramping-vus",
      startVUs,
      gracefulRampDown: "30s",
      stages: selectedStages
    }
  },
  thresholds: {
    http_req_duration: ["p(95)<2000"],
    http_req_failed: ["rate<0.01"],
    business_errors: ["rate<0.01"]
  }
};

export function setup() {
  console.log(`k6 profile=${loadProfile} baseUrl=${baseUrl}`);
}

function pickEndpoint() {
  return endpoints[Math.floor(Math.random() * endpoints.length)];
}

export default function () {
  const endpoint = pickEndpoint();
  const res = http.get(`${baseUrl}${endpoint}`, {
    headers: requestHeaders,
    tags: { endpoint }
  });

  const ok = check(res, {
    "status is 2xx or 3xx": (r) => r.status >= 200 && r.status < 400
  });

  businessErrors.add(!ok);
  sleep(Math.random() * 1.2 + 0.3);
}
