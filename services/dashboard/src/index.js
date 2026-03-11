const path = require("path");
const express = require("express");

const app = express();
const port = process.env.PORT || 8080;

app.get("/health", (req, res) => {
  res.json({ status: "healthy", service: "dashboard" });
});

app.get("/api/summary", (req, res) => {
  res.json({
    status: "ok",
    summary: { total_alerts: 42, system_health: "99.9%" },
  });
});

// Serve frontend
app.use(express.static(path.join(__dirname, "../client/dist")));
app.get("/*", (req, res) => {
  res.sendFile(path.join(__dirname, "../client/dist/index.html"));
});

app.listen(port, () => {
  console.log(`🚀 Dashboard Service starting on port ${port}...`);
});
