-- Users table
CREATE TABLE IF NOT EXISTS users (
    user_id TEXT PRIMARY KEY,
    created_at TEXT NOT NULL
);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    transaction_id INTEGER NOT NULL,
    total_amount REAL NOT NULL,
    rounded_amount REAL NOT NULL,
    paid BOOLEAN NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE(user_id, transaction_id)
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('productivity', 'achievement')),
    deposit_amount REAL NOT NULL,
    sponsored_by TEXT NOT NULL DEFAULT 'nobody',
    tracked_app_name TEXT,
    status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'closed')),
    result TEXT CHECK(result IN ('success', 'failure') OR result IS NULL),
    created_at TEXT NOT NULL,
    closed_at TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Sponsorships table
CREATE TABLE IF NOT EXISTS sponsorships (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    task_id TEXT NOT NULL,
    title TEXT NOT NULL,
    task_title TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    details TEXT,
    share_link TEXT NOT NULL,
    notes TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);

-- Status/Payment History table
CREATE TABLE IF NOT EXISTS status (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    payment_type TEXT NOT NULL,
    amount_per_payment REAL NOT NULL,
    date_time TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_sponsorships_user ON sponsorships(user_id);
CREATE INDEX IF NOT EXISTS idx_status_user ON status(user_id);

-- ============= SAMPLE DATA =============
-- Sample user
INSERT OR IGNORE INTO users (user_id, created_at) VALUES 
('demo_user', '2026-03-29T00:00:00+00:00');

-- Sample transactions
INSERT OR IGNORE INTO transactions (user_id, transaction_id, total_amount, rounded_amount, paid, created_at) VALUES
('demo_user', 1, 12.50, 0.50, 0, '2026-03-28T10:30:00+00:00'),
('demo_user', 2, 25.75, 0.25, 1, '2026-03-28T14:15:00+00:00'),
('demo_user', 3, 8.99, 1.01, 0, '2026-03-28T18:45:00+00:00');

-- Sample tasks
INSERT OR IGNORE INTO tasks (id, user_id, title, description, type, deposit_amount, sponsored_by, tracked_app_name, status, result, created_at, closed_at) VALUES
('task-001', 'demo_user', 'Morning Run', 'Run for 30 minutes', 'productivity', 5.00, 'nobody', NULL, 'closed', 'success', '2026-03-28T06:00:00+00:00', '2026-03-28T06:35:00+00:00'),
('task-002', 'demo_user', 'Study Python', 'Study 2 hours of Python', 'achievement', 10.00, 'nobody', 'Python IDE', 'open', NULL, '2026-03-28T19:00:00+00:00', NULL);

-- Sample sponsorships
INSERT OR IGNORE INTO sponsorships (id, user_id, task_id, title, task_title, status, share_link, created_at) VALUES
('sponsor-001', 'demo_user', 'task-002', 'Study Python', 'Study Python', 'pending', 'https://fake-sponsor.tassel.app/s/sponsor-001', '2026-03-28T19:00:00+00:00');

-- Sample status/payment history
INSERT OR IGNORE INTO status (id, user_id, payment_type, amount_per_payment, date_time) VALUES
('status-001', 'demo_user', 'daily_roundup', 0.50, '2026-03-28T10:30:00+00:00'),
('status-002', 'demo_user', 'request_paid', 0.25, '2026-03-28T14:30:00+00:00'),
('status-003', 'demo_user', 'task_completed', 5.00, '2026-03-28T06:35:00+00:00');
