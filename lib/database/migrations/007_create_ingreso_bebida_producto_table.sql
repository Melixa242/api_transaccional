CREATE TABLE IF NOT EXISTS `ingreso_bebida_producto` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ingreso_bebida_id` bigint unsigned NOT NULL,
  `producto_id` bigint unsigned NOT NULL,
  `cantidad_ingresa` decimal(12,2) NOT NULL,
  `precio` decimal(12,2) NOT NULL DEFAULT '0.00',
  `estado` int NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ingreso_bebida_producto_ingreso_bebida_id_foreign` (`ingreso_bebida_id`),
  KEY `ingreso_bebida_producto_producto_id_foreign` (`producto_id`),
  CONSTRAINT `ingreso_bebida_producto_ingreso_bebida_id_foreign` FOREIGN KEY (`ingreso_bebida_id`) REFERENCES `ingreso_bebidas` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ingreso_bebida_producto_producto_id_foreign` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
