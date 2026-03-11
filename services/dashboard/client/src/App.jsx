import React, { useState, useEffect } from "react";

function App() {
  const [stats, setStats] = useState(null);

  useEffect(() => {
    fetch("/api/summary")
      .then((res) => res.json())
      .then((data) => setStats(data.summary));
  }, []);

  return (
    <div style={{ padding: "20px", fontFamily: "sans-serif" }}>
      <h1>🚀 Viralis Dashboard</h1>
      {stats ? (
        <div>
          <p>
            Total Alerts: <strong>{stats.total_alerts}</strong>
          </p>
          <p>
            System Health: <strong>{stats.system_health}</strong>
          </p>
        </div>
      ) : (
        <p>Loading stats...</p>
      )}
    </div>
  );
}

export default App;
