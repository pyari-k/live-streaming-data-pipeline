-- Quick Commerce OLTP Database Initialization

CREATE TABLE IF NOT EXISTS riders (
    rider_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    vehicle_type VARCHAR(50) DEFAULT 'bike',
    current_status VARCHAR(50) DEFAULT 'AVAILABLE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    store_id INT NOT NULL,
    rider_id INT REFERENCES riders(rider_id),
    order_status VARCHAR(50) NOT NULL DEFAULT 'PLACED',
    item_count INT NOT NULL DEFAULT 1,
    total_amount NUMERIC(10, 2) NOT NULL,
    delivery_fee NUMERIC(5, 2) DEFAULT 2.50,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Ensure full row state is captured in PostgreSQL WAL for Debezium CDC updates
ALTER TABLE orders REPLICA IDENTITY FULL;
ALTER TABLE riders REPLICA IDENTITY FULL;

-- Seed initial riders
INSERT INTO riders (name, vehicle_type, current_status) VALUES
('Rider Alex', 'ev_scooter', 'AVAILABLE'),
('Rider Brenda', 'bike', 'AVAILABLE'),
('Rider Carlos', 'ev_scooter', 'AVAILABLE'),
('Rider Diana', 'bike', 'AVAILABLE'),
('Rider Evan', 'scooter', 'AVAILABLE');
