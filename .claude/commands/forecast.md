---
description: Generate a weighted sales forecast from toflow pipeline data — best/likely/worst scenarios, commit vs. upside, gap analysis
argument-hint: "<optional: period, e.g. 'Q2 2025' or 'this month'>"
---

# /forecast

Pull your live pipeline from toflow and generate a weighted forecast with risk-adjusted scenarios, commit vs. upside breakdown, and gap analysis.

## Usage

```
/forecast [period]
```

Forecast period: $ARGUMENTS

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                        FORECAST                                  │
├─────────────────────────────────────────────────────────────────┤
│  DATA PULL (live from toflow)                                    │
│  ✓ list_pipelines + list_stages → stage probabilities           │
│  ✓ list_records (deal) → all open + recently closed deals       │
│  ✓ validate_and_preview_report + run_report → aggregated data   │
│    - Deals dataset: group by stage, close_month, close_quarter  │
│    - Metrics: sum(value), avg(probability), count(deal_id)      │
│  ✓ Closed-won deals this period → actual bookings to date       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Execution Flow

### Step 1: Set the Forecast Period

If $ARGUMENTS provided: parse period (e.g., "Q2 2025" = Apr 1 – Jun 30 2025)
If not provided: ask "What period are you forecasting? (e.g., this month, Q2, full year)"

Also ask: "What's your quota for this period?" (or infer from context if previously stated)

### Step 2: Get Pipeline Structure

```
1. list_pipelines() → get pipeline(s)
2. list_stages(pipeline_id=...) → get stages with default probabilities
   - Use toflow stage probabilities if set
   - Fall back to standard defaults (see below)
```

**Default stage probabilities (if not set in toflow):**
| Stage Position | Label | Probability |
|---------------|-------|-------------|
| 1 (earliest) | Prospecting / Lead | 10% |
| 2 | Discovery / Qualification | 20% |
| 3 | Demo / Evaluation | 40% |
| 4 | Proposal / Quote | 60% |
| 5 | Negotiation / Contract | 80% |
| Last | Closed Won | 100% |

### Step 3: Pull Open Deals in Period

```
list_records(
  resource_type=deal,
  filters=[
    {field: "status", operator: "is_not", value: "lost"},
    {field: "expected_close_date", operator: "lte", value: period_end_date}
  ],
  sort="value:desc",
  page_size=100
)
```

### Step 4: Pull Closed-Won Deals (Actual Bookings)

```
list_records(
  resource_type=deal,
  filters=[
    {field: "status", operator: "is", value: "won"},
    {field: "expected_close_date", operator: "gte", value: period_start_date},
    {field: "expected_close_date", operator: "lte", value: period_end_date}
  ]
)
→ Sum values = already_closed amount
```

### Step 5: Run Aggregate Reports

```
// By stage (for weighted forecast)
validate_and_preview_report(dataset_id=10, query={
  group_by: "stage_name",
  metrics: [
    {field: "value", aggregation: "sum"},
    {field: "deal_id", aggregation: "count"},
    {field: "probability", aggregation: "avg"}
  ],
  filters: [{field: "expected_close_date", operator: "lte", value: period_end_date},
            {field: "status", operator: "neq", value: "lost"}]
})
run_report(...)

// By close month (for timing view)
run report with group_by: "close_month"
```

### Step 6: Calculate Forecast Scenarios

For each open deal, classify:

**Commit** (high confidence):
- Stage probability >= 80% (Negotiation/Contract)
- OR Intent = "Very Hot" + stage >= 60%

**Best case:**
- All open deals in period close at their expected date

**Likely (weighted):**
- Sum of (deal_value × stage_probability) for all open deals

**Worst case:**
- Only Commit deals close

```
weighted_forecast = sum(deal.value × stage_probability for each deal)
best_case = already_closed + sum(all open deal values)
likely_case = already_closed + weighted_forecast
worst_case = already_closed + sum(commit deal values)
gap_to_quota = quota - likely_case
coverage_ratio = (already_closed + sum(open deal values)) / quota
```

### Step 7: Identify Risk Flags

Flag individual deals that inflate the forecast unrealistically:
- Past close date
- No activity 14+ days
- Close date this week but still in early stage
- Very high value + Cold intent

---

## Output

```markdown
# Sales Forecast: [Period]

**Generated:** [Date] | **Data:** toflow Live Pipeline

---

## Summary

| Metric | Value |
|--------|-------|
| **Quota** | $[X] |
| **Closed to Date** | $[X] ([X]% of quota) |
| **Open Pipeline** | $[X] |
| **Weighted Forecast** | $[X] |
| **Gap to Quota** | $[X] |
| **Pipeline Coverage** | [X]x |

---

## Forecast Scenarios

| Scenario | Amount | % of Quota | Assumptions |
|----------|--------|------------|-------------|
| **Best Case** | $[X] | [X]% | All [N] open deals close on time |
| **Likely (Weighted)** | $[X] | [X]% | Stage-probability weighted |
| **Worst Case** | $[X] | [X]% | Only Commit deals close |

---

## Pipeline by Stage

| Stage | Deals | Value | Probability | Weighted |
|-------|-------|-------|-------------|---------|
| [Stage] | [N] | $[X] | [X]% | $[X] |
| **Total** | [N] | $[X] | — | $[X] |

---

## By Close Month

| Month | Deals | Value | Weighted |
|-------|-------|-------|---------|
| [Month] | [N] | $[X] | $[X] |

---

## Commit vs. Upside

### Commit (High Confidence — will stake forecast on these)

| Deal | Value | Stage | Close Date | Why Commit |
|------|-------|-------|------------|------------|
| [Deal] | $[X] | [Stage] | [Date] | [Reason — stage, intent, active] |

**Total Commit:** $[X]

### Upside (Could close, but risk exists)

| Deal | Value | Stage | Close Date | Risk Factor |
|------|-------|-------|------------|-------------|
| [Deal] | $[X] | [Stage] | [Date] | [Risk — stale, early stage, etc.] |

**Total Upside:** $[X]

---

## Risk Flags (Remove from Forecast or Address)

| Deal | Value | Risk | Action |
|------|-------|------|--------|
| [Deal] | $[X] | Close date passed | Update date or close lost |
| [Deal] | $[X] | No activity 14+ days | Re-engage or downgrade |
| [Deal] | $[X] | Closing this week, still in Discovery | Push out close date |

---

## Gap Analysis

**To hit quota, you need:** $[X] more

**Options:**
1. **Accelerate [Deal]** — $[X], currently in [Stage]. If you close by [date], you reach [X]% of quota.
2. **Revive [Stale Deal]** — $[X], last active [date]. Re-engage [contact name].
3. **New pipeline needed** — At [X]x coverage, you need $[X] in new deals to be safe.

---

## Recommendations

- [ ] [Specific action for top-priority deal]
- [ ] [Re-engage stale deal with most value]
- [ ] [Pipeline building action if coverage < 2x]
- [ ] [Clean up past-close-date deals for accuracy]
```

---

## Coverage Guidance

| Coverage Ratio | Signal |
|---------------|--------|
| 4x+ | Healthy — good cushion |
| 3x | Target state |
| 2x | Thin — start generating pipeline now |
| <2x | Risky — urgent pipeline action required |

---

## Tips

1. **Commit only what you'd bet on** — Upside is for everything else
2. **Update close dates** — Stale close dates destroy forecast accuracy
3. **Intent field matters** — A "Very Hot" deal in Proposal stage > a "Cold" deal in Negotiation
4. **Coverage below 2x** — Stop reviewing and start prospecting
