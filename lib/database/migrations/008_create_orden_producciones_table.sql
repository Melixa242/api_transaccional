CREATE TABLE IF NOT EXISTS `orden_producciones` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `numero_orden` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_programada` date NOT NULL,
  `regla_conversion_id` bigint unsigned DEFAULT NULL,
  `observaciones` text COLLATE utf8mb4_unicode_ci,
  `estado` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `orden_producciones_numero_orden_unique` (`numero_orden`),
  KEY `orden_producciones_regla_conversion_id_foreign` (`regla_conversion_id`),
  CONSTRAINT `orden_producciones_regla_conversion_id_foreign` FOREIGN KEY (`regla_conversion_id`) REFERENCES `reglas_conversion` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
