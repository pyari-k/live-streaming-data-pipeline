import os
import time
import random
import psycopg2
from datetime import datetime

DB_HOST = os.getenv("POSTGRES_HOST", "postgres")
DB_NAME = os.getenv("POSTGRES_DB", "qcommerce_db")
DB_USER = os.getenv("POSTGRES_USER", "postgres")
DB_PASS = os.getenv("POSTGRES_PASSWORD", "postgres")

STATUS_FLOW = {
    "PLACED": "PACKED",
    "PACKED": "DISPATCHED",
    "DISPATCHED": "DELIVERED"
}

def get_connection():
    while True:
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASS,
                port=5432
            )
            print("Connected to PostgreSQL OLTP successfully.")
            return conn
        except Exception as e:
            print(f"Waiting for Postgres... error: {e}")
            time.sleep(3)

def generate_order(conn):
    with conn.cursor() as cur:
        customer_id = random.randint(100, 999)
        store_id = random.randint(1, 10)
        rider_id = random.randint(1, 5)
        item_count = random.randint(1, 8)
        total_amount = round(random.uniform(12.50, 150.00), 2)
        delivery_fee = round(random.uniform(1.50, 4.99), 2)
        
        cur.execute("""
            INSERT INTO orders (customer_id, store_id, rider_id, order_status, item_count, total_amount, delivery_fee)
            VALUES (%s, %s, %s, 'PLACED', %s, %s, %s)
            RETURNING order_id;
        """, (customer_id, store_id, rider_id, item_count, total_amount, delivery_fee))
        
        order_id = cur.fetchone()[0]
        conn.commit()
        print(f"[{datetime.now().strftime('%H:%M:%S')}] 🛒 Created NEW Order #{order_id} - ${total_amount} (PLACED)")

def progress_existing_orders(conn):
    with conn.cursor() as cur:
        # Find active orders that are not DELIVERED
        cur.execute("""
            SELECT order_id, order_status 
            FROM orders 
            WHERE order_status != 'DELIVERED' 
            ORDER BY updated_at ASC 
            LIMIT 5;
        """)
        active_orders = cur.fetchall()
        
        if not active_orders:
            return

        # Pick one order to update
        order_id, current_status = random.choice(active_orders)
        next_status = STATUS_FLOW.get(current_status)
        
        if next_status:
            cur.execute("""
                UPDATE orders 
                SET order_status = %s, updated_at = CURRENT_TIMESTAMP 
                WHERE order_id = %s;
            """, (next_status, order_id))
            conn.commit()
            print(f"[{datetime.now().strftime('%H:%M:%S')}] 🚚 Updated Order #{order_id}: {current_status} -> {next_status}")

def main():
    print("Starting Quick Commerce Transaction Simulator...")
    conn = get_connection()
    
    while True:
        try:
            # 60% chance to create new order, 40% chance to update status of an active order
            if random.random() < 0.6:
                generate_order(conn)
            else:
                progress_existing_orders(conn)
                
            # Wait 180 seconds (3 minutes) between events for calm, observable learning
            time.sleep(180)
        except Exception as e:
            print(f"Error in simulation loop: {e}")
            conn = get_connection()

if __name__ == "__main__":
    main()
