# Script para probar la API desde PowerShell

# ============================================
# TEST DE CONEXIÓN A LA API
# ============================================

# CONFIGURA AQUÍ TU IP Y PUERTO
$API_BASE = "http://192.168.1.100:8080"
$ENDPOINT = "/api/ventas"

Write-Host "🚀 Prueba de conexión a: $API_BASE$ENDPOINT" -ForegroundColor Green

# ============================================
# 1. TEST GET
# ============================================
Write-Host "`n📥 1. GET - Obtener todas las ventas" -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$API_BASE$ENDPOINT" -Method Get
    Write-Host "✅ Éxito (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "Respuesta:" -ForegroundColor Yellow
    Write-Host $response.Content | ConvertFrom-Json | ConvertTo-Json
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================
# 2. TEST POST
# ============================================
Write-Host "`n📤 2. POST - Crear nueva venta" -ForegroundColor Cyan
$body = @{
    cantidad = 5
    precio_total = 100.00
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$API_BASE$ENDPOINT" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body
    Write-Host "✅ Éxito (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "Respuesta:" -ForegroundColor Yellow
    Write-Host $response.Content | ConvertFrom-Json | ConvertTo-Json
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================
# 3. TEST GET CON ID
# ============================================
Write-Host "`n📥 3. GET - Obtener venta con ID 1" -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$API_BASE$ENDPOINT/1" -Method Get
    Write-Host "✅ Éxito (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "Respuesta:" -ForegroundColor Yellow
    Write-Host $response.Content | ConvertFrom-Json | ConvertTo-Json
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================
# 4. TEST PUT
# ============================================
Write-Host "`n🔄 4. PUT - Actualizar venta ID 1" -ForegroundColor Cyan
$body = @{
    cantidad = 10
    precio_total = 200.00
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$API_BASE$ENDPOINT/1" `
        -Method Put `
        -ContentType "application/json" `
        -Body $body
    Write-Host "✅ Éxito (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "Respuesta:" -ForegroundColor Yellow
    Write-Host $response.Content | ConvertFrom-Json | ConvertTo-Json
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================
# 5. TEST DELETE
# ============================================
Write-Host "`n🗑️  5. DELETE - Eliminar venta ID 1" -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$API_BASE$ENDPOINT/1" -Method Delete
    Write-Host "✅ Éxito (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "Respuesta:" -ForegroundColor Yellow
    Write-Host $response.Content | ConvertFrom-Json | ConvertTo-Json
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================
# 6. VERIFICACIÓN FINAL
# ============================================
Write-Host "`n🔍 6. Verificación - GET final" -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$API_BASE$ENDPOINT" -Method Get
    Write-Host "✅ Servidor responde correctamente" -ForegroundColor Green
} catch {
    Write-Host "❌ Servidor no responde: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n✅ Pruebas completadas`n" -ForegroundColor Green
