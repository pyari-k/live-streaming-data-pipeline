# Developer & Maintenance Guide

This document contains instructions for maintaining, rebuilding, and updating this repository across sessions.

---

## 🎨 Architecture Diagram Generation

The architecture diagram assets (`architecture_diagram.pdf` and `architecture_diagram.png`) are generated using `generate_pdf.py`.

### 1. Requirements
* Python 3 with `reportlab`:
  ```bash
  pip install reportlab
  ```

### 2. How to Regenerate the Diagram
If you modify component details or styling in `generate_pdf.py`:

```bash
# Step 1: Generate the Vector PDF blueprint
python3 generate_pdf.py

# Step 2: Render high-resolution (2000px) Retina PNG for the README
qlmanage -t -s 2000 -o . architecture_diagram.pdf && mv architecture_diagram.pdf.png architecture_diagram.png
```

*(Fallback on macOS if `qlmanage` is unavailable)*:
```bash
sips -s format png architecture_diagram.pdf --out architecture_diagram.png
```

### 3. Python Script Source (Saved here so `generate_pdf.py` can be deleted)
If `generate_pdf.py` has been deleted to keep the root directory clean, you can recreate it anytime by saving this snippet:

<details>
<summary><b>Click to expand full <code>generate_pdf.py</code> script</b></summary>

```python
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib import colors
from reportlab.pdfgen import canvas
import sys

def draw_card(c, x, y, w, h, bg_color, border_color, r=8):
    c.saveState()
    c.setFillColor(bg_color)
    c.setStrokeColor(border_color)
    c.setLineWidth(1.5)
    c.roundRect(x, y, w, h, r, fill=1, stroke=1)
    c.restoreState()

def draw_h_arrow(c, x1, y1, x2, y2, top_label="", bottom_label="", direction="right"):
    c.saveState()
    c.setStrokeColor(colors.HexColor("#0284c7"))
    c.setFillColor(colors.HexColor("#0284c7"))
    c.setLineWidth(2.5)
    c.line(x1, y1, x2, y2)
    
    p = c.beginPath()
    if direction == "right":
        p.moveTo(x2, y2)
        p.lineTo(x2 - 8, y2 + 5)
        p.lineTo(x2 - 8, y2 - 5)
    else:
        p.moveTo(x2, y2)
        p.lineTo(x2 + 8, y2 + 5)
        p.lineTo(x2 + 8, y2 - 5)
    p.close()
    c.drawPath(p, fill=1, stroke=0)
    
    mid_x = (x1 + x2) / 2
    c.setFont("Helvetica-Bold", 7)
    c.setFillColor(colors.HexColor("#0369a1"))
    if top_label:
        c.drawCentredString(mid_x, y1 + 5, top_label)
    if bottom_label:
        c.drawCentredString(mid_x, y1 - 13, bottom_label)
    c.restoreState()

def draw_v_arrow(c, x1, y1, x2, y2, top_label="", bottom_label=""):
    c.saveState()
    c.setStrokeColor(colors.HexColor("#0284c7"))
    c.setFillColor(colors.HexColor("#0284c7"))
    c.setLineWidth(2.5)
    c.line(x1, y1, x2, y2)
    
    p = c.beginPath()
    p.moveTo(x2, y2)
    p.lineTo(x2 - 5, y2 + 8)
    p.lineTo(x2 + 5, y2 + 8)
    p.close()
    c.drawPath(p, fill=1, stroke=0)
    
    mid_y = (y1 + y2) / 2
    c.setFont("Helvetica-Bold", 7)
    c.setFillColor(colors.HexColor("#0369a1"))
    if top_label:
        c.drawString(x1 + 8, mid_y + 4, top_label)
    if bottom_label:
        c.drawString(x1 + 8, mid_y - 7, bottom_label)
    c.restoreState()

def create_architecture_pdf(filename="architecture_diagram.pdf"):
    page_w, page_h = landscape(letter)
    c = canvas.Canvas(filename, pagesize=(page_w, page_h))
    
    c.setFillColor(colors.HexColor("#f8fafc"))
    c.rect(0, 0, page_w, page_h, fill=1, stroke=0)
    
    c.setFillColor(colors.HexColor("#0f172a"))
    c.rect(0, page_h - 70, page_w, 70, fill=1, stroke=0)
    
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 20)
    c.drawString(36, page_h - 38, "Quick Commerce Real-Time Streaming Architecture")
    
    c.setFillColor(colors.HexColor("#94a3b8"))
    c.setFont("Helvetica", 10)
    c.drawString(36, page_h - 56, "Event-Driven Data Pipeline: PostgreSQL (OLTP) -> Debezium CDC -> Kafka -> ClickHouse OLAP -> Grafana")

    card_w = 205
    card_h = 200
    gap_x = 52
    start_x = 36
    row1_y = 295
    row2_y = 45

    cards = {
        1: {
            "step": "STEP 1 • PRODUCER", "title": "Order Simulator",
            "tech": "Python 3.10 • Containerized", "tag": "TRAFFIC GENERATOR",
            "tag_bg": "#dbeafe", "tag_fg": "#1e40af",
            "bullets": [
                "• Simulates realistic grocery shoppers",
                "• Generates new orders (PLACED)",
                "• Progresses delivery status every 3 mins:",
                "   PLACED -> PACKED -> DISPATCHED -> DELIVERED",
                "• Writes directly to PostgreSQL port 5432",
                "• Fully containerized service"
            ],
            "footer": "Controlled via: docker start/stop"
        },
        2: {
            "step": "STEP 2 • OLTP SOURCE", "title": "PostgreSQL 15",
            "tech": "Port: 5432 • DB: qcommerce_db", "tag": "TRANSACTIONAL DATABASE",
            "tag_bg": "#dcfce7", "tag_fg": "#166534",
            "bullets": [
                "• Operational source of truth for orders",
                "• wal_level = logical enabled",
                "• Tables: orders, riders",
                "• Table REPLICA IDENTITY FULL",
                "• Bookmark slot: debezium_slot",
                "• Zero polling overhead on tables"
            ],
            "footer": "Connect via: DBeaver / psql"
        },
        3: {
            "step": "STEP 3 • CDC ENGINE", "title": "Debezium Connect",
            "tech": "Port: 8083 • Kafka Connect 2.4", "tag": "CHANGE DATA CAPTURE",
            "tag_bg": "#fef3c7", "tag_fg": "#92400e",
            "bullets": [
                "• Tails PostgreSQL WAL logs in memory",
                "• Intercepts row changes with 0 latency",
                "• Emits structured JSON events to Kafka",
                "• Captures 'before' & 'after' row state",
                "• Zero SELECT query load on Postgres",
                "• decimal.handling.mode = double"
            ],
            "footer": "Inspect in: Kafka UI Connect tab"
        },
        4: {
            "step": "STEP 4 • EVENT BUS", "title": "Apache Kafka",
            "tech": "Port: 9092 • Kafka UI: 8080", "tag": "DISTRIBUTED STREAM BUFFER",
            "tag_bg": "#fee2e2", "tag_fg": "#991b1b",
            "bullets": [
                "• Topic: qcommerce.public.orders",
                "• Decouples OLTP database from analytics",
                "• Resilient buffer: zero message loss",
                "• Consumer Lag: 0 (sub-second ingestion)",
                "• Visualized via Kafka UI at port 8080",
                "• Allows multiple downstream consumers"
            ],
            "footer": "Inspect at: http://localhost:8080"
        },
        5: {
            "step": "STEP 5 • OLAP ENGINE", "title": "ClickHouse 23.8",
            "tech": "Port: 8123 (HTTP) • DB: qcommerce", "tag": "REAL-TIME DATA WAREHOUSE",
            "tag_bg": "#f3e8ff", "tag_fg": "#6b21a8",
            "bullets": [
                "• Built-in Kafka Engine table (zero custom code)",
                "• Dual-Layer Design via Materialized Views:",
                "   1. Bronze: order_events (MergeTree log)",
                "   2. Silver: orders_realtime (ReplacingMergeTree)",
                "• Sub-second aggregations on millions of rows",
                "• Columnar storage with high compression"
            ],
            "footer": "Connect via: DBeaver / ClickHouse Client"
        },
        6: {
            "step": "STEP 6 • PRESENTATION", "title": "Grafana Dashboard",
            "tech": "Port: 3000 • admin / admin", "tag": "REAL-TIME VISUALIZATION",
            "tag_bg": "#ffedd5", "tag_fg": "#9a3412",
            "bullets": [
                "• Live auto-refreshing dashboard (every 5s)",
                "• 🛒 Total Orders Processed counter",
                "• 💰 Gross Real-Time Order Revenue",
                "• 📊 Orders by Status donut chart",
                "• 📈 Incoming Order Stream time-series plot",
                "• Directly queries ClickHouse SQL"
            ],
            "footer": "Open at: http://localhost:3000"
        }
    }

    def render_card(idx, x, y):
        info = cards[idx]
        draw_card(c, x, y, card_w, card_h, colors.white, colors.HexColor("#cbd5e1"), r=8)
        c.setFont("Helvetica-Bold", 7.5)
        c.setFillColor(colors.HexColor("#64748b"))
        c.drawString(x + 12, y + card_h - 20, info["step"])
        c.setFont("Helvetica-Bold", 13.5)
        c.setFillColor(colors.HexColor("#0f172a"))
        c.drawString(x + 12, y + card_h - 38, info["title"])
        c.setFont("Helvetica", 8)
        c.setFillColor(colors.HexColor("#475569"))
        c.drawString(x + 12, y + card_h - 52, info["tech"])
        tw = card_w - 24
        c.setFillColor(colors.HexColor(info["tag_bg"]))
        c.roundRect(x + 12, y + card_h - 74, tw, 16, 3, fill=1, stroke=0)
        c.setFillColor(colors.HexColor(info["tag_fg"]))
        c.setFont("Helvetica-Bold", 7)
        c.drawCentredString(x + 12 + tw / 2, y + card_h - 70, info["tag"])
        c.setFont("Helvetica", 7.8)
        c.setFillColor(colors.HexColor("#334155"))
        by = y + card_h - 93
        for bullet in info["bullets"]:
            c.drawString(x + 12, by, bullet)
            by -= 13.5
        c.setFillColor(colors.HexColor("#f1f5f9"))
        c.roundRect(x + 12, y + 10, tw, 18, 4, fill=1, stroke=0)
        c.setFont("Helvetica-Bold", 7.5)
        c.setFillColor(colors.HexColor("#0284c7"))
        c.drawCentredString(x + 12 + tw / 2, y + 16, info["footer"])

    render_card(1, start_x, row1_y)
    render_card(2, start_x + card_w + gap_x, row1_y)
    render_card(3, start_x + 2 * (card_w + gap_x), row1_y)
    
    a1_x1 = start_x + card_w + 4
    a1_x2 = start_x + card_w + gap_x - 4
    ay1 = row1_y + card_h / 2
    draw_h_arrow(c, a1_x1, ay1, a1_x2, ay1, top_label="SQL INSERT", bottom_label="& UPDATE", direction="right")
    
    a2_x1 = start_x + 2 * card_w + gap_x + 4
    a2_x2 = start_x + 2 * (card_w + gap_x) - 4
    draw_h_arrow(c, a2_x1, ay1, a2_x2, ay1, top_label="WAL LOGICAL", bottom_label="DECODING", direction="right")

    v_x = start_x + 2 * (card_w + gap_x) + (card_w / 2)
    v_y1 = row1_y - 4
    v_y2 = row2_y + card_h + 4
    draw_v_arrow(c, v_x, v_y1, v_x, v_y2, top_label="CDC JSON", bottom_label="STREAM")

    render_card(6, start_x, row2_y)
    render_card(5, start_x + card_w + gap_x, row2_y)
    render_card(4, start_x + 2 * (card_w + gap_x), row2_y)
    
    ay2 = row2_y + card_h / 2
    a4_x1 = start_x + 2 * (card_w + gap_x) - 4
    a4_x2 = start_x + 2 * card_w + gap_x + 4
    draw_h_arrow(c, a4_x1, ay2, a4_x2, ay2, top_label="NATIVE KAFKA", bottom_label="ENGINE", direction="left")
    
    a5_x1 = start_x + card_w + gap_x - 4
    a5_x2 = start_x + card_w + 4
    draw_h_arrow(c, a5_x1, ay2, a5_x2, ay2, top_label="5s REFRESH", bottom_label="SQL QUERIES", direction="left")

    c.showPage()
    c.save()

if __name__ == "__main__":
    create_architecture_pdf(sys.argv[1] if len(sys.argv) > 1 else "architecture_diagram.pdf")
```
</details>


---

## 🚀 Service Management & Lifecycle

All services are orchestrated via `docker-compose.yml`.

| Action | Command | What it does |
| :--- | :--- | :--- |
| **Start / Resume** | `docker compose start` | Wakes up existing containers in 1 sec (data preserved). |
| **Stop / Pause** | `docker compose stop` | Freezes containers & frees 100% CPU/RAM (data preserved). |
| **Full Rebuild** | `docker compose up -d --build` | Re-builds images and starts all services. |
| **Clean Shutdown** | `docker compose down` | Stops and removes container instances (keeps volumes). |

---

## ⚙️ Traffic Simulator Control

* **Start traffic**: `docker start qcommerce_simulator`
* **Stop traffic**: `docker stop qcommerce_simulator`
* **Adjust Frequency**: Edit `simulator/simulator.py` line `time.sleep(...)`, then rebuild:
  ```bash
  docker compose up -d --no-deps --build simulator
  ```

---

## 🔌 Debezium Connector Re-registration

If Kafka or Debezium is reset from scratch, register the PostgreSQL CDC connector via:

```bash
./setup_debezium.sh
```
Or via HTTP POST:
```bash
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
  http://localhost:8083/connectors/ \
  -d @debezium/register-postgres.json
```
