import http from "k6/http";
import { check, sleep } from "k6";
import { Rate } from "k6/metrics";

const businessErrors = new Rate("business_errors");
const baseUrl = __ENV.BASE_URL || "http://localhost";

export const options = {
  scenarios: {
    black_friday_ramp: {
      executor: "ramping-vus",
      startVUs: 100,
      gracefulRampDown: "30s",
      stages: [
        { duration: "5m", target: 1000 },
        { duration: "10m", target: 5000 },
        { duration: "15m", target: 20000 },
        { duration: "20m", target: 50000 },
        { duration: "20m", target: 70000 },
        { duration: "20m", target: 90000 },
        { duration: "30m", target: 90000 },
        { duration: "10m", target: 0 }
      ]
    }
  },
  thresholds: {
    http_req_duration: ["p(95)<2000"],
    http_req_failed: ["rate<0.01"],
    business_errors: ["rate<0.01"]
  }
};

function pickEndpoint() {
  const endpoints = ["/", "/healthz", "/img/"];
  return endpoints[Math.floor(Math.random() * endpoints.length)];
}

export default function () {
  const endpoint = pickEndpoint();
  const res = http.get(`${baseUrl}${endpoint}`, {
    tags: { endpoint }
  });

  const ok = check(res, {
    "status is 2xx or 3xx": (r) => r.status >= 200 && r.status < 400
  });

  businessErrors.add(!ok);
  sleep(Math.random() * 1.2 + 0.3);
}
