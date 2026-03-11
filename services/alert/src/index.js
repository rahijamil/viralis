const express = require("express");
const app = express();
const port = process.env.PORT || 8080;

app.get("/health", (req, res) => {
  res.json({ status: "healthy", service: "alert" });
});

app.post("/alert", (req, res) => {
  res.json({ status: "sent", message: "Alert processed" });
});

app.listen(port, () => {
  console.log(`🚀 Alert Service starting on port ${port}...`);
});
