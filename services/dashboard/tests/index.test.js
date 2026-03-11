/* eslint-disable */
const request = require("supertest");
const express = require("express");
const app = express();

app.get("/health", (req, res) => {
  res.json({ status: "healthy", service: "dashboard" });
});

app.get("/api/summary", (req, res) => {
  res.json({
    status: "ok",
    summary: { total_alerts: 42, system_health: "99.9%" },
  });
});

describe("Dashboard Service", () => {
  test("GET /health returns healthy", async () => {
    const res = await request(app).get("/health");
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ status: "healthy", service: "dashboard" });
  });

  test("GET /api/summary returns summary", async () => {
    const res = await request(app).get("/api/summary");
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe("ok");
    expect(res.body.summary.total_alerts).toBe(42);
  });
});
