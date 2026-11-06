CREATE TABLE IF NOT EXISTS `mermas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `produccion_id` bigint unsigned NOT NULL,
  `cantidad` decimal(12,2) NOT NULL,
  `estado` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `mermas_produccion_id_foreign` (`produccion_id`),
  CONSTRAINT `mermas_produccion_id_foreign` FOREIGN KEY (`produccion_id`) REFERENCES `producciones` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
