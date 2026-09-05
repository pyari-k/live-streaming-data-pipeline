-- ClickHouse Real-time Data Warehouse Schema & Kafka Stream Ingestion

CREATE DATABASE IF NOT EXISTS qcommerce;

-- =============================================================================
-- 1. KAFKA ENGINE: Ingests raw JSON CDC messages from Kafka topic
-- =============================================================================
CREATE TABLE IF NOT EXISTS qcommerce.orders_kafka_raw (
    raw String
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:9092',
         kafka_topic_list = 'qcommerce.public.orders',
         kafka_group_name = 'clickhouse_orders_consumer_group',
         kafka_format = 'RawBLOB',
         kafka_num_consumers = 1;

-- =============================================================================
-- 2. BRONZE LAYER: IMMUTABLE EVENT LOG (Never deletes or replaces rows)
-- Captures full lifecycle: PLACED -> PACKED -> DISPATCHED -> DELIVERED
-- =============================================================================
CREATE TABLE IF NOT EXISTS qcommerce.order_events (
    order_id UInt32,
    customer_id UInt32,
    store_id UInt32,
    rider_id Nullable(UInt32),
    order_status String,
    item_count UInt16,
    total_amount Float64,
    delivery_fee Float64,
    op String,                          -- 'c' = Create, 'u' = Update, 'r' = Snapshot
    cdc_timestamp DateTime64(3),        -- Exact timestamp event occurred
    ingested_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (order_id, cdc_timestamp);

-- Materialized View populating the Immutable Event Log
CREATE MATERIALIZED VIEW IF NOT EXISTS qcommerce.mv_order_events
TO qcommerce.order_events AS
SELECT
    JSONExtractInt(raw, 'payload', 'after', 'order_id') AS order_id,
    JSONExtractInt(raw, 'payload', 'after', 'customer_id') AS customer_id,
    JSONExtractInt(raw, 'payload', 'after', 'store_id') AS store_id,
    if(JSONHas(raw, 'payload', 'after', 'rider_id'), JSONExtractInt(raw, 'payload', 'after', 'rider_id'), NULL) AS rider_id,
    JSONExtractString(raw, 'payload', 'after', 'order_status') AS order_status,
    JSONExtractInt(raw, 'payload', 'after', 'item_count') AS item_count,
    JSONExtractFloat(raw, 'payload', 'after', 'total_amount') AS total_amount,
    JSONExtractFloat(raw, 'payload', 'after', 'delivery_fee') AS delivery_fee,
    JSONExtractString(raw, 'payload', 'op') AS op,
    toDateTime64(JSONExtractInt(raw, 'payload', 'ts_ms') / 1000.0, 3) AS cdc_timestamp,
    now() AS ingested_at
FROM qcommerce.orders_kafka_raw
WHERE JSONExtractString(raw, 'payload', 'op') IN ('c', 'u', 'r') 
  AND JSONExtractInt(raw, 'payload', 'after', 'order_id') > 0;

-- =============================================================================
-- 3. SILVER LAYER: CURRENT STATE TABLE (ReplacingMergeTree deduplicates by order_id)
-- Keeps 1 row per order with the latest state
-- =============================================================================
CREATE TABLE IF NOT EXISTS qcommerce.orders_realtime (
    order_id UInt32,
    customer_id UInt32,
    store_id UInt32,
    rider_id Nullable(UInt32),
    order_status String,
    item_count UInt16,
    total_amount Float64,
    delivery_fee Float64,
    op String,
    cdc_timestamp DateTime64(3),
    updated_at DateTime DEFAULT now()
) ENGINE = ReplacingMergeTree(cdc_timestamp)
ORDER BY order_id;

-- Materialized View populating the Current State table
CREATE MATERIALIZED VIEW IF NOT EXISTS qcommerce.mv_orders_realtime
TO qcommerce.orders_realtime AS
SELECT
    JSONExtractInt(raw, 'payload', 'after', 'order_id') AS order_id,
    JSONExtractInt(raw, 'payload', 'after', 'customer_id') AS customer_id,
    JSONExtractInt(raw, 'payload', 'after', 'store_id') AS store_id,
    if(JSONHas(raw, 'payload', 'after', 'rider_id'), JSONExtractInt(raw, 'payload', 'after', 'rider_id'), NULL) AS rider_id,
    JSONExtractString(raw, 'payload', 'after', 'order_status') AS order_status,
    JSONExtractInt(raw, 'payload', 'after', 'item_count') AS item_count,
    JSONExtractFloat(raw, 'payload', 'after', 'total_amount') AS total_amount,
    JSONExtractFloat(raw, 'payload', 'after', 'delivery_fee') AS delivery_fee,
    JSONExtractString(raw, 'payload', 'op') AS op,
    toDateTime64(JSONExtractInt(raw, 'payload', 'ts_ms') / 1000.0, 3) AS cdc_timestamp,
    now() AS updated_at
FROM qcommerce.orders_kafka_raw
WHERE JSONExtractString(raw, 'payload', 'op') IN ('c', 'u', 'r') 
  AND JSONExtractInt(raw, 'payload', 'after', 'order_id') > 0;

-- =============================================================================
-- 4. GOLD LAYER: Live Analytical View for Grafana
-- =============================================================================
CREATE VIEW IF NOT EXISTS qcommerce.v_latest_orders AS
SELECT
    order_id,
    argMax(customer_id, cdc_timestamp) AS customer_id,
    argMax(store_id, cdc_timestamp) AS store_id,
    argMax(rider_id, cdc_timestamp) AS rider_id,
    argMax(order_status, cdc_timestamp) AS order_status,
    argMax(item_count, cdc_timestamp) AS item_count,
    argMax(total_amount, cdc_timestamp) AS total_amount,
    argMax(delivery_fee, cdc_timestamp) AS delivery_fee,
    max(cdc_timestamp) AS max_cdc_ts
FROM qcommerce.orders_realtime
GROUP BY order_id;
