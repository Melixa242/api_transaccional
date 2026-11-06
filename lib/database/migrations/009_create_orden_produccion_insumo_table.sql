CREATE TABLE IF NOT EXISTS `orden_produccion_insumo` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `orden_produccion_id` bigint unsigned NOT NULL,
  `insumo_id` bigint unsigned NOT NULL,
  `cantidad` decimal(12,2) NOT NULL,
  `estado` int NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `orden_produccion_insumo_orden_produccion_id_foreign` (`orden_produccion_id`),
  KEY `orden_produccion_insumo_insumo_id_foreign` (`insumo_id`),
  CONSTRAINT `orden_produccion_insumo_insumo_id_foreign` FOREIGN KEY (`insumo_id`) REFERENCES `insumos` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `orden_produccion_insumo_orden_produccion_id_foreign` FOREIGN KEY (`orden_produccion_id`) REFERENCES `orden_producciones` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
