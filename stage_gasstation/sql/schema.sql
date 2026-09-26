CREATE TABLE IF NOT EXISTS `gas_stations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(16) UNIQUE NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `owner` VARCHAR(64) DEFAULT NULL,
    `posX` FLOAT NOT NULL,
    `posY` FLOAT NOT NULL,
    `posZ` FLOAT NOT NULL,
    `rot` FLOAT DEFAULT 0,
    `level` INT DEFAULT 1,
    `balance` BIGINT DEFAULT 0,
    `petrol_stock` INT DEFAULT 0,
    `diesel_stock` INT DEFAULT 0,
    `petrol_price` INT DEFAULT 48,
    `diesel_price` INT DEFAULT 52,
    `petrol_buy` INT DEFAULT 40,
    `diesel_buy` INT DEFAULT 43,
    `for_sale` TINYINT DEFAULT 0,
    `sale_price` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `gas_station_products` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `station_id` INT NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `buy_price` INT NOT NULL,
    `sell_price` INT NOT NULL,
    `stock` INT DEFAULT 0,
    `active` TINYINT DEFAULT 1,
    FOREIGN KEY (`station_id`) REFERENCES `gas_stations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `gas_station_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `station_id` INT NOT NULL,
    `type` ENUM('income','expense') NOT NULL,
    `category` VARCHAR(32) NOT NULL,
    `amount` INT NOT NULL,
    `description` VARCHAR(128),
    `player` VARCHAR(64),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`station_id`) REFERENCES `gas_stations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `gas_station_ads` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `station_id` INT NOT NULL,
    `title` VARCHAR(64) NOT NULL,
    `message` VARCHAR(255) NOT NULL,
    `budget` INT NOT NULL,
    `duration` INT NOT NULL,
    `expires_at` TIMESTAMP NOT NULL,
    `active` TINYINT DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`station_id`) REFERENCES `gas_stations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `gas_station_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `station_id` INT,
    `action` VARCHAR(64) NOT NULL,
    `details` TEXT,
    `player` VARCHAR(64),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `gas_station_extra_markers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `station_id` INT NOT NULL,
    `posX` FLOAT NOT NULL,
    `posY` FLOAT NOT NULL,
    `posZ` FLOAT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`station_id`) REFERENCES `gas_stations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `gas_station_stats` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `station_id` INT NOT NULL,
    `date` DATE NOT NULL,
    `petrol_sold` INT DEFAULT 0,
    `diesel_sold` INT DEFAULT 0,
    `market_sold` INT DEFAULT 0,
    `customers` INT DEFAULT 0,
    `income` BIGINT DEFAULT 0,
    `expense` BIGINT DEFAULT 0,
    UNIQUE KEY `station_date` (`station_id`, `date`),
    FOREIGN KEY (`station_id`) REFERENCES `gas_stations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
