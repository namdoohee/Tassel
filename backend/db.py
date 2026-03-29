import sqlite3
import os
from datetime import datetime, timezone
from contextlib import contextmanager
from typing import Optional, List, Dict, Any

DB_PATH = os.path.join(os.path.dirname(__file__), "tassel.sqlite3")


@contextmanager
def get_db_connection():
    """Context manager for database connections"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # Return rows as dictionaries
    try:
        yield conn
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


def init_db():
    """Initialize database with schema"""
    schema_path = os.path.join(os.path.dirname(__file__), "schema.sql")
    with open(schema_path, 'r') as f:
        schema = f.read()
    
    with get_db_connection() as conn:
        conn.executescript(schema)
    print("Database initialized successfully")


# ============= USERS =============
def create_user(user_id: str) -> bool:
    """Create a new user if not exists"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        try:
            cursor.execute(
                "INSERT INTO users (user_id, created_at) VALUES (?, ?)",
                (user_id, datetime.now(timezone.utc).isoformat())
            )
            return True
        except sqlite3.IntegrityError:
            return False  # User already exists


def get_user(user_id: str) -> Optional[Dict]:
    """Get user by ID"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE user_id = ?", (user_id,))
        row = cursor.fetchone()
        return dict(row) if row else None


# ============= TRANSACTIONS =============
def create_transaction(user_id: str, transaction_id: int, total_amount: float, 
                      rounded_amount: float) -> Dict:
    """Create a new transaction"""
    create_user(user_id)  # Ensure user exists
    
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """INSERT INTO transactions 
               (user_id, transaction_id, total_amount, rounded_amount, paid, created_at)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (user_id, transaction_id, total_amount, rounded_amount, False, 
             datetime.now(timezone.utc).isoformat())
        )
        conn.commit()
        
        cursor.execute(
            "SELECT * FROM transactions WHERE user_id = ? AND transaction_id = ?",
            (user_id, transaction_id)
        )
        row = cursor.fetchone()
        return dict(row)


def get_transaction(user_id: str, transaction_id: int) -> Optional[Dict]:
    """Get a specific transaction"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT * FROM transactions WHERE user_id = ? AND transaction_id = ?",
            (user_id, transaction_id)
        )
        row = cursor.fetchone()
        return dict(row) if row else None


def get_all_transactions(user_id: str) -> List[Dict]:
    """Get all transactions for a user"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, user_id, transaction_id, total_amount, rounded_amount, paid, created_at FROM transactions WHERE user_id = ? ORDER BY created_at DESC",
            (user_id,)
        )
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


def update_transaction_paid(user_id: str, transaction_id: int) -> bool:
    """Mark a transaction as paid"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE transactions SET paid = 1 WHERE user_id = ? AND transaction_id = ?",
            (user_id, transaction_id)
        )
        return cursor.rowcount > 0


# ============= TASKS =============
def create_task(user_id: str, task_id: str, title: str, description: str, 
                task_type: str, deposit_amount: float, 
                tracked_app_name: Optional[str] = None) -> Dict:
    """Create a new task"""
    create_user(user_id)  # Ensure user exists
    
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """INSERT INTO tasks 
               (id, user_id, title, description, type, deposit_amount, tracked_app_name, status, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (task_id, user_id, title, description, task_type, deposit_amount, 
             tracked_app_name, 'open', datetime.now(timezone.utc).isoformat())
        )
        conn.commit()
        
        cursor.execute("SELECT * FROM tasks WHERE id = ?", (task_id,))
        row = cursor.fetchone()
        return dict(row)


def get_task(user_id: str, task_id: str) -> Optional[Dict]:
    """Get a specific task"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT * FROM tasks WHERE id = ? AND user_id = ?",
            (task_id, user_id)
        )
        row = cursor.fetchone()
        return dict(row) if row else None


def get_all_tasks(user_id: str) -> List[Dict]:
    """Get all tasks for a user"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT * FROM tasks WHERE user_id = ? ORDER BY created_at DESC",
            (user_id,)
        )
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


def close_task(user_id: str, task_id: str, result: str) -> bool:
    """Close a task with success or failure"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """UPDATE tasks 
               SET status = 'closed', result = ?, closed_at = ? 
               WHERE id = ? AND user_id = ?""",
            (result, datetime.now(timezone.utc).isoformat(), task_id, user_id)
        )
        return cursor.rowcount > 0


# ============= SPONSORSHIPS =============
def create_sponsorship(user_id: str, sponsorship_id: str, task_id: str, 
                      title: str, task_title: str, share_link: str) -> Dict:
    """Create a new sponsorship"""
    create_user(user_id)  # Ensure user exists
    
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """INSERT INTO sponsorships 
               (id, user_id, task_id, title, task_title, status, share_link, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (sponsorship_id, user_id, task_id, title, task_title, 'pending', 
             share_link, datetime.now(timezone.utc).isoformat())
        )
        conn.commit()
        
        cursor.execute("SELECT * FROM sponsorships WHERE id = ?", (sponsorship_id,))
        row = cursor.fetchone()
        return dict(row)


def get_all_sponsorships(user_id: str) -> List[Dict]:
    """Get all sponsorships for a user"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT * FROM sponsorships WHERE user_id = ? ORDER BY created_at DESC",
            (user_id,)
        )
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


# ============= STATUS =============
def create_status(user_id: str, status_id: str, payment_type: str, 
                 amount_per_payment: float) -> Dict:
    """Create a new status entry"""
    create_user(user_id)  # Ensure user exists
    
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """INSERT INTO status 
               (id, user_id, payment_type, amount_per_payment, date_time)
               VALUES (?, ?, ?, ?, ?)""",
            (status_id, user_id, payment_type, amount_per_payment, 
             datetime.now(timezone.utc).isoformat())
        )
        conn.commit()
        
        cursor.execute("SELECT * FROM status WHERE id = ?", (status_id,))
        row = cursor.fetchone()
        return dict(row)


def get_all_status(user_id: str) -> List[Dict]:
    """Get all status entries for a user"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT * FROM status WHERE user_id = ? ORDER BY date_time DESC",
            (user_id,)
        )
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


# Helper function for app.py
def get_next_transaction_id(user_id: str) -> int:
    """Get the next transaction ID for a user"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT MAX(transaction_id) as max_id FROM transactions WHERE user_id = ?",
            (user_id,)
        )
        row = cursor.fetchone()
        max_id = row['max_id'] if row and row['max_id'] else 0
        return max_id + 1