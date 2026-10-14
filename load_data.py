"""Loads the Olist CSV files from data/ into the MySQL tables created by sql/01_schema.sql.

    python load_data.py

Set the connection in a .env file:  DATABASE_URL=mysql+pymysql://user:password@localhost:3306/olist
"""
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

DATA = Path(__file__).parent / "data"

# table name -> (csv file, columns to keep, date columns)
FILES = {
    "customers": ("olist_customers_dataset.csv",
                  ["customer_id", "customer_unique_id", "customer_city", "customer_state"], []),
    "sellers": ("olist_sellers_dataset.csv", ["seller_id", "seller_city", "seller_state"], []),
    "category_translation": ("product_category_name_translation.csv",
                             ["product_category_name", "product_category_name_english"], []),
    "products": ("olist_products_dataset.csv", ["product_id", "product_category_name"], []),
    "orders": ("olist_orders_dataset.csv",
               ["order_id", "customer_id", "order_status", "order_purchase_timestamp", "order_approved_at",
                "order_delivered_carrier_date", "order_delivered_customer_date", "order_estimated_delivery_date"],
               ["order_purchase_timestamp", "order_approved_at", "order_delivered_carrier_date",
                "order_delivered_customer_date", "order_estimated_delivery_date"]),
    "order_items": ("olist_order_items_dataset.csv",
                    ["order_id", "order_item_id", "product_id", "seller_id", "price", "freight_value"], []),
    "order_reviews": ("olist_order_reviews_dataset.csv", ["review_id", "order_id", "review_score"], []),
}


def main():
    load_dotenv()
    engine = create_engine(os.environ["DATABASE_URL"])
    with engine.begin() as conn:
        for table, (filename, cols, dates) in FILES.items():
            df = pd.read_csv(DATA / filename, usecols=cols, parse_dates=dates)
            conn.execute(text(f"DELETE FROM {table}"))
            df.to_sql(table, conn, if_exists="append", index=False, chunksize=5000, method="multi")
            print(f"{table:<22} {len(df):>8,} rows")


if __name__ == "__main__":
    main()
