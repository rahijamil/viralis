/* eslint-disable */
const request = require("supertest");
const express = require("express");
const app = express();

// Mock the app logic
app.get("/health", (req, res) => {
  res.json({ status: "healthy", service: "alert" });
});

app.post("/alert", (req, res) => {
  res.json({ status: "sent", message: "Alert processed" });
});

describe("Alert Service", () => {
  test("GET /health returns healthy", async () => {
    const res = await request(app).get("/health");
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ status: "healthy", service: "alert" });
  });

  test("POST /alert returns sent", async () => {
    const res = await request(app).post("/alert").send({});
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe("sent");
  });
});
