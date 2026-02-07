package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
)

var DB *sql.DB

// InitDB инициализирует подключение к PostgreSQL
func InitDB() error {
	// Получаем параметры подключения из переменных окружения
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "5432")
	dbUser := getEnv("DB_USER", "postgres")
	dbPassword := getEnv("DB_PASSWORD", "postgres")
	dbName := getEnv("DB_NAME", "savings_app")
	dbSSLMode := getEnv("DB_SSLMODE", "disable")

	// Формируем строку подключения
	connStr := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		dbHost, dbPort, dbUser, dbPassword, dbName, dbSSLMode,
	)

	// Открываем подключение
	var err error
	DB, err = sql.Open("postgres", connStr)
	if err != nil {
		return fmt.Errorf("ошибка открытия подключения к БД: %w", err)
	}

	// Проверяем подключение
	if err = DB.Ping(); err != nil {
		return fmt.Errorf("ошибка проверки подключения к БД: %w", err)
	}

	log.Println("✅ Успешное подключение к PostgreSQL")

	// Устанавливаем максимальное количество открытых соединений
	DB.SetMaxOpenConns(25)
	DB.SetMaxIdleConns(5)

	return nil
}

// CloseDB закрывает подключение к базе данных
func CloseDB() {
	if DB != nil {
		DB.Close()
		log.Println("🔌 Подключение к БД закрыто")
	}
}

// Вспомогательная функция для получения переменных окружения
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
