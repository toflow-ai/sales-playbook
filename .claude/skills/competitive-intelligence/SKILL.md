---
name: competitive-intelligence
description: Research competitors and build an interactive HTML battlecard. Uses toflow deal data for win/loss patterns + web research for market intel. Trigger with "competitive intel", "research competitors", "how do we compare to [competitor]", "battlecard for [competitor]", "what's new with [competitor]".
compatibility: Requires mcp__toflow tools + WebSearch
---

# Competitive Intelligence

Research competitors from two sources: toflow deal data (win/loss patterns, deal notes) and web research (product, pricing, recent releases). Outputs an interactive HTML battlecard artifact.

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                  COMPETITIVE INTELLIGENCE                        │
├─────────────────────────────────────────────────────────────────┤
│  PRIMARY: toflow Win/Loss Data                                   │
│  ✓ list_records (deal, status=won) → won deal patterns          │
│  ✓ list_records (deal, status=lost) → lost deal patterns        │
│  ✓ list_notes → search notes for competitor mentions            │
│  ✓ Deal-level intel: stage, value, company size, signals        │
├─────────────────────────────────────────────────────────────────┤
│  SUPPLEMENT: Web Research                                        │
│  + Competitor product pages, pricing, changelog, reviews        │
│  + Recent news, funding, releases (last 90 days)                │
│  + G2/Capterra reviews for customer sentiment                   │
│  + Job postings for growth direction signals                    │
├─────────────────────────────────────────────────────────────────┤
│  OUTPUT: Interactive HTML Battlecard Artifact                    │
│  ✓ Comparison matrix (you vs. all competitors)                  │
│  ✓ Clickable competitor tabs with full battlecard               │
│  ✓ Talk tracks, objection handling, landmine questions          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Execution Flow

### Step 1: Identify Competitors

If user names specific competitors: use those.
Otherwise ask: "Who are your main competitors? (up to 5 names)"

Also confirm: "What's your company and product?" (if not already known from context)

### Step 2: Pull toflow Win/Loss Data

```
// Won deals — what helped us win
list_records(
  resource_type=deal,
  filters=[{field: "status", operator: "is", value: "won"}],
  page_size=50
)

// Lost deals — where we lost
list_records(
  resource_type=deal,
  filters=[{field: "status", operator: "is", value: "lost"}],
  page_size=50
)

// Search notes for competitor mentions
For each competitor name:
  list_notes(search=competitor_name, page_size=20)
  → Extract: objections raised, why won/lost, customer quotes, field intel
```

From this data, derive:
- Win rate patterns (company size, stage when won/lost)
- Competitor objections that appeared in lost deals
- Customer language about competitor (from notes)
- Deal value patterns (do we win bigger or smaller deals?)

### Step 3: Web Research Per Competitor

For each competitor, run:
```
1. "[Competitor] product features" → what they offer
2. "[Competitor] pricing" → pricing model, entry price
3. "[Competitor] news 2025" → recent announcements
4. "[Competitor] changelog OR releases" → what they shipped (last 90 days)
5. "[Competitor] reviews site:g2.com OR site:capterra.com" → customer sentiment
6. "[Competitor] vs alternatives" → their positioning
7. "[Competitor] careers" → hiring signals (where are they investing?)
```

Also research your own company for the latest:
```
1. "[Your company] product updates OR changelog" → what you've shipped
2. "[Your company] vs [competitor]" → existing comparisons to pull from
```

### Step 4: Structure Per-Competitor Data

For each competitor, build:

```yaml
name: [Competitor]
profile:
  founded: [Year]
  funding: [Stage + amount]
  employees: [Count/Range]
  target_market: [Who they sell to]
  pricing_model: [Per seat / usage / flat]
  market_position: [Leader / Challenger / Niche]

what_they_sell: [Product summary]
their_positioning: [How they describe themselves]

recent_releases: [Last 90 days — what they shipped + impact]

where_they_win:
  - area, their_advantage, your_counter

where_you_win:
  - area, your_advantage, proof_point

pricing:
  model, entry_price, enterprise, hidden_costs, talk_track

talk_tracks:
  early_mention: [Strategy if they come up early]
  displacement: [If customer currently uses them]
  late_addition: [If added late to evaluation]

objections:
  - objection_from_customer → your_response

landmines:
  - [Question that naturally exposes their weakness]

win_loss (from toflow):
  win_rate: [X]% (if calculable)
  win_factors: [What deals we win against them look like]
  loss_factors: [What deals we lose to them look like]
```

### Step 5: Generate HTML Battlecard

Produce a self-contained HTML artifact with:
- Dark theme, professional styling
- Tab navigation: Overview Matrix + one tab per competitor
- Expandable sections within each tab
- Color-coded win/loss indicators

**Color system:**
```css
--bg-primary: #0a0d14;
--bg-elevated: #0f131c;
--bg-surface: #161b28;
--accent: #3b82f6;
--you-win: #10b981;
--they-win: #ef4444;
--tie: #f59e0b;
```

**HTML structure:**
```html
<header> Your Company Competitive Battlecard | [Date] | Competitors: [List] </header>
<nav class="tabs">
  <button>Comparison Matrix</button>
  <button>[Competitor 1]</button>
  ...
</nav>
<section id="matrix"> Feature comparison grid + quick win/loss guide </section>
<section id="competitor-1">
  <div class="profile">Company info, funding, target market</div>
  <div class="recent-releases">Last 90 days</div>
  <div class="differentiation">Where they win / where you win</div>
  <div class="pricing">Model, cost, hidden costs, talk track</div>
  <div class="talk-tracks">Early / Displacement / Late scenarios</div>
  <div class="objections">Common objections + responses</div>
  <div class="landmines">Questions to plant naturally</div>
  <div class="win-loss">toflow data: win rate, patterns</div>
</section>
<script> Tab switching + expand/collapse logic </script>
```

---

## Output After Generation

```markdown
## Battlecard Created

**Your Company:** [Name]
**Competitors Analyzed:** [List]
**Data Sources:** toflow Win/Loss + Web Research

### Win/Loss Summary from toflow

| Competitor | Won Against | Lost To | Win Rate |
|------------|-------------|---------|----------|
| [Comp] | [N deals] | [N deals] | [X]% |

### Field Intel from Deal Notes

Key competitor mentions found in deal notes:
- "[Competitor]: [Quote or pattern from notes]"

---

**How to use the battlecard:**
- Before a call: open competitor tab, review talk tracks
- During a call: use landmine questions naturally
- After win/loss: add new patterns to notes in toflow

**Keep fresh:** Run monthly or before major competitive deals.
```

---

## Refresh Guidance

| Trigger | Action |
|---------|--------|
| Monthly | Quick refresh — new releases, pricing changes |
| Before major deal | Deep refresh for the specific competitor |
| After win/loss | Run `/call-summary` and log competitive intel in notes |
| Competitor announcement | Immediate update on that competitor |

---

## Landmine Questions (Examples)

Questions that expose competitor weaknesses without badmouthing:
- "How do you handle [known weak area]?"
- "What's been your experience with [integration they lack]?"
- "How does that tool handle [scaling scenario they struggle with]?"
- "What happens to your data if you need to switch?"

Plant naturally in discovery — never trash-talk.
