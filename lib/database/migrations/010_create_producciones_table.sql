CREATE TABLE IF NOT EXISTS `producciones` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `orden_produccion_insumo_id` bigint unsigned DEFAULT NULL,
  `regla_conversion_id` bigint unsigned DEFAULT NULL,
  `producto_id` bigint unsigned DEFAULT NULL,
  `cantidad_insumo` decimal(12,2) NOT NULL DEFAULT '0.00',
  `cantidad_obtenida` decimal(12,2) NOT NULL DEFAULT '0.00',
  `nivel` int unsigned NOT NULL DEFAULT '0',
  `estado` int NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `producciones_orden_produccion_insumo_id_unique` (`orden_produccion_insumo_id`),
  KEY `producciones_regla_conversion_id_foreign` (`regla_conversion_id`),
  KEY `producciones_producto_id_foreign` (`producto_id`),
  CONSTRAINT `producciones_orden_produccion_insumo_id_foreign` FOREIGN KEY (`orden_produccion_insumo_id`) REFERENCES `orden_produccion_insumo` (`id`) ON DELETE SET NULL,
  CONSTRAINT `producciones_producto_id_foreign` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON DELETE SET NULL,
  CONSTRAINT `producciones_regla_conversion_id_foreign` FOREIGN KEY (`regla_conversion_id`) REFERENCES `reglas_conversion` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
