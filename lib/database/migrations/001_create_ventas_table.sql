CREATE TABLE IF NOT EXISTS `ventas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `cliente_id` bigint unsigned NOT NULL,
  `fecha_venta` date NOT NULL,
  `observaciones` text COLLATE utf8mb4_unicode_ci,
  `opcion_pago` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Efectivo',
  `descuento` decimal(12,2) NOT NULL DEFAULT '0.00',
  `total` double NOT NULL DEFAULT '0',
  `estado` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `ventas_cliente_id_foreign` (`cliente_id`),
  CONSTRAINT `ventas_cliente_id_foreign` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
