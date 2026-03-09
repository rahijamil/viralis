# 🛠️ PRODUCT REQUIREMENTS DOCUMENT (PRD)

**Project:** Viralis v1.0

**Status:** Ready for Implementation

## 1. Product Purpose

The specific problem Viralis v1.0 solves is **"The Insight Gap."** It automates the transition from raw data detection (spikes) to qualitative understanding (reasoning) using an autonomous agentic workflow, delivering alerts to users before a trend reaches mainstream saturation.

---

## 2. Feature List & Prioritization (MoSCoW)

| Category | Must-Have (P0) | Should-Have (P1) | Could-Have (P2) | Won't-Have (v1) |
| --- | --- | --- | --- | --- |
| **Ingestion** | Hybrid API + Crawl4AI | RSS & News Feeds | Video Transcript Scraper | Meta/Instagram API |
| **Intelligence** | Trend Detection Algo | Agentic "Why" Report | Predictive Decay Score | Image/Meme OCR |
| **Delivery** | Dashboard & Discord | Email Briefs | Slack Integration | SMS Alerts |
| **Search** | Keyword Search | Vector/Semantic Search | Natural Language Query | User Collaboration |

---

## 3. User Stories & Acceptance Criteria

### **User Story 1: The Alert**

> *As a Content Creator, I want to receive a Discord alert when a topic spikes by >20% in 1 hour so I can be the first to post.*

* **Acceptance Criteria:**
* System must detect spikes relative to a rolling 7-day baseline.
* Alert must include: Topic Name, Platform Source, and a 1-sentence AI summary.
* Latency from detection to Discord message must be $< 60$ seconds.



### **User Story 2: The Deep Dive**

> *As a PR Manager, I want an AI-generated "Context Report" for a trend so I don't have to read 100 comments.*

* **Acceptance Criteria:**
* Report must synthesize data from at least 2 different platforms (e.g., X + Reddit).
* Must use Crawl4AI to extract and summarize the *root* linked article.
* Report must provide a "Sentiment Direction" (Positive/Negative/Controversial).



---

## 4. Functional Requirements

* **FR-1: Data Deduplication:** The system must hash incoming posts to ensure the same news story from multiple sources is treated as a single "Event."
* **FR-2: Agentic Orchestration:** The "Analyst Agent" must trigger only when a "Velocity Threshold" is met to save on LLM token costs.
* **FR-3: Threshold Management:** Users must be able to set custom sensitivity levels (e.g., "Only alert on 50% spikes").

---

## 5. Non-Functional Requirements

* **Performance:** * **Latency:** API response time for dashboard data $< 300$ms.
* **Processing:** Time from raw scrape to Vector DB embedding $< 5$s.


* **Scalability:** Microservices must be stateless and deployable via **Kubernetes (K8s)** to handle horizontal scaling during viral events.
* **Security:** * Mandatory **OAuth 2.0** for user authentication.
* API Key rotation for all third-party data providers.


* **Observability:** Implementation of **OpenTelemetry** to track agent "Reasoning Traces" for debugging hallucinations.

## 5.3 Load Testing & Scalability Requirements

### 5.3.1 Concurrent User Targets

| Tier | Expected Concurrent | Peak Load Target | Burst Capacity |
|------|---------------------|------------------|----------------|
| **MVP Launch** | 100 users | 500 users | 1,000 users |
| **Year 1** | 1,000 users | 5,000 users | 10,000 users |
| **Year 2** | 5,000 users | 20,000 users | 50,000 users |
| **Enterprise** | N/A | N/A | 100,000+ (with dedicated instances) |

### 5.3.2 Load Testing Scenarios

**Scenario 1: Viral Event Spike**
```
Context: A major trend breaks (e.g., Super Bowl moment)
User Behavior:
- 80% dashboard viewing
- 15% creating new topics
- 5% exporting reports
Load Profile:
- 0 → 5,000 users in 2 minutes
- Sustain for 30 minutes
- Gradual decline over 2 hours
Success Criteria:
- 95th percentile latency < 500ms
- Zero errors
- Auto-scaling triggers within 2 minutes
```

**Scenario 2: Morning Rush Hour**
```
Context: 9 AM EST - creators checking daily briefs
User Behavior:
- 60% viewing heatmap
- 30% reading trend details
- 10% configuring alerts
Load Profile:
- 0 → 2,000 users over 30 minutes
- Maintain for 2 hours
Success Criteria:
- Response time < 300ms p95
- No degradation in AI processing
```

**Scenario 3: API Burst (Enterprise)**
```
Context: Enterprise client polling API every minute
User Behavior:
- Automated API calls
- Batch trend exports
Load Profile:
- 100 concurrent API clients
- 1,000 requests/second
Success Criteria:
- Rate limiting activates appropriately
- 429 responses < 1%
- No cascading failures
```

### 5.3.3 Load Testing Implementation

```yaml
# k6 load test configuration
scenarios:
  viral_spike:
    executor: ramping-arrival-rate
    startRate: 10
    timeUnit: 1s
    stages:
      - target: 100  # 100 req/sec
        duration: 2m
      - target: 500  # 500 req/sec
        duration: 5m
      - target: 1000 # peak
        duration: 5m
      - target: 0
        duration: 2m
    
thresholds:
  http_req_duration: ["p(95)<500"]
  http_req_failed: ["rate<0.01"]
  iteration_duration: ["max<2000"]
```

### 5.3.4 Auto-scaling Configuration

```yaml
# Horizontal Pod Autoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ingestion-service
spec:
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: kafka_consumer_lag
      target:
        type: AverageValue
        averageValue: 1000
```

---

## 6. User Flow & Logic Map

### **6.1 The Autonomous Loop (Backend)**

1. **Ingestion Service:** Polls X/Reddit APIs $\rightarrow$ Detects anomalous volume.
2. **Crawl Service:** Triggered by Ingestion $\rightarrow$ Visits top 3 links in the spike via **Crawl4AI** $\rightarrow$ Converts to Markdown.
3. **Inference Service (The Agent):** Takes Markdown + Social Snippets $\rightarrow$ Runs LLM Analysis $\rightarrow$ Generates "Context Report."
4. **Vector Store:** Embeds report for semantic search.
5. **Notification Service:** Pushes to Discord Webhook and Updates Live Dashboard.

### **6.2 Dashboard Interaction (Frontend)**

* **View A (The Heatmap):** Visual grid of active trends sized by velocity.
* **View B (The Inspect Panel):** Clicking a trend slides out the AI Report, sentiment charts, and raw source links.

## 7. Launch Checklist

### Alpha (Week 4)
- [ ] 1 data source (Reddit) fully operational
- [ ] Basic trend detection algorithm
- [ ] Manual alert testing with 5 beta users

### Beta (Week 8)
- [ ] 3+ data sources integrated
- [ ] Agentic reasoning working at 70% accuracy
- [ ] 50 active users providing feedback

### Production (Week 12)
- [ ] 90% detection accuracy
- [ ] < 15 min end-to-end latency
- [ ] Self-healing pipelines operational