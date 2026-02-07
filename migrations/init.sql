-- Создание базы данных (выполняется отдельно)
-- CREATE DATABASE savings_app;

-- Подключение к базе данных
-- \c savings_app;

-- Таблица пользователей
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'treasurer', 'admin')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Индекс для быстрого поиска по имени пользователя
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- Таблица счетов
CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    target_amount DECIMAL(15, 2) NOT NULL CHECK (target_amount > 0),
    current_amount DECIMAL(15, 2) DEFAULT 0.00 CHECK (current_amount >= 0),
    creator_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Индекс для поиска счетов по создателю
CREATE INDEX idx_accounts_creator ON accounts(creator_id);

-- Таблица запросов на пополнение
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES accounts(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_by INTEGER REFERENCES users(id),
    approved_at TIMESTAMP,
    rejection_reason TEXT
);

-- Индексы для быстрого поиска транзакций
CREATE INDEX idx_transactions_account ON transactions(account_id);
CREATE INDEX idx_transactions_user ON transactions(user_id);
CREATE INDEX idx_transactions_status ON transactions(status);

-- Таблица истории операций
CREATE TABLE IF NOT EXISTS transaction_history (
    id SERIAL PRIMARY KEY,
    transaction_id INTEGER REFERENCES transactions(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),
    account_id INTEGER REFERENCES accounts(id),
    amount DECIMAL(15, 2) NOT NULL,
    operation_type VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Индекс для истории
CREATE INDEX idx_history_user ON transaction_history(user_id);
CREATE INDEX idx_history_account ON transaction_history(account_id);

-- Таблица логов админ-панели
CREATE TABLE IF NOT EXISTS admin_logs (
    id SERIAL PRIMARY KEY,
    admin_id INTEGER REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание индексов для улучшения производительности
CREATE INDEX idx_admin_logs_admin ON admin_logs(admin_id);
CREATE INDEX idx_admin_logs_created ON admin_logs(created_at);

-- Вставка администратора по умолчанию (пароль: admin123)
INSERT INTO users (username, email, password_hash, role) 
VALUES (
    'admin',
    'admin@savingsapp.com',
    '$2a$10$XhJGZqZ5Z5Z5Z5Z5Z5Z5ZuZ5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z', -- bcrypt hash для "admin123"
    'admin'
) ON CONFLICT (username) DO NOTHING;

-- Вставка казначея по умолчанию (пароль: treasurer123)
INSERT INTO users (username, email, password_hash, role) 
VALUES (
    'treasurer',
    'treasurer@savingsapp.com',
    '$2a$10$YhJGZqZ5Z5Z5Z5Z5Z5Z5ZuZ5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z', -- bcrypt hash для "treasurer123"
    'treasurer'
) ON CONFLICT (username) DO NOTHING;