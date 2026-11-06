CREATE TABLE IF NOT EXISTS `ingreso_insumo_detalle` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ingreso_insumo_id` bigint unsigned NOT NULL,
  `insumo_id` bigint unsigned NOT NULL,
  `cantidad` decimal(12,2) NOT NULL,
  `precio_unitario` decimal(12,2) NOT NULL,
  `estado` int NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ingreso_insumo_detalle_ingreso_insumo_id_insumo_id_unique` (`ingreso_insumo_id`,`insumo_id`),
  KEY `ingreso_insumo_detalle_insumo_id_foreign` (`insumo_id`),
  CONSTRAINT `ingreso_insumo_detalle_ingreso_insumo_id_foreign` FOREIGN KEY (`ingreso_insumo_id`) REFERENCES `ingreso_insumos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ingreso_insumo_detalle_insumo_id_foreign` FOREIGN KEY (`insumo_id`) REFERENCES `insumos` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
