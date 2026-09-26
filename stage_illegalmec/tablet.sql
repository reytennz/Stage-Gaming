-- Bu dosya artık zorunlu değil: server.lua ve depo.lua başlangıçta
-- CREATE TABLE IF NOT EXISTS ile bu tabloları otomatik oluşturuyor.
-- Referans / manuel kurulum istersen aşağıdakini phpMyAdmin'de çalıştırabilirsin.

CREATE TABLE IF NOT EXISTS `mechanic_shops` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `mekanik_ismi` VARCHAR(64) NOT NULL,
  `sifresi` VARCHAR(255) NOT NULL,
  `sahibi` VARCHAR(64) NOT NULL,
  `owner_id` INT NOT NULL,
  `eleman` TINYINT(1) DEFAULT NULL,
  `duty_x` FLOAT DEFAULT NULL,
  `duty_y` FLOAT DEFAULT NULL,
  `duty_z` FLOAT DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_mekanik_ismi` (`mekanik_ismi`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mechanic_depo` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `sahibi` VARCHAR(64) NOT NULL,
  `slot` INT NOT NULL,
  `esya` VARCHAR(64) DEFAULT NULL,
  `miktar` INT DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_sahibi_slot` (`sahibi`,`slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
