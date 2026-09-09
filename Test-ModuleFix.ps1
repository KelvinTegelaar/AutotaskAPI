<#
.SYNOPSIS
Test script to verify the AutoTaskAPI module fix for state mutation bug

.DESCRIPTION
This script tests that Get-AutotaskAPIResource no longer corrupts the
$Script:Queries table, allowing New-AutotaskAPIResource to work correctly.

The bug: Get-AutotaskAPIResource was mutating the global $Script:Queries table
by replacing "/query" with "/{PARENTID}" directly on the shared object.

The fix: Clone the object before modification to avoid mutating shared state.
#>

[CmdletBinding()]
param()

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "AutoTaskAPI Module Fix Verification Test" -ForegroundColor Cyan
Write-Host "==================================================================`n" -ForegroundColor Cyan

# Import the FIXED module from local directory
Write-Host "[1] Importing FIXED module from local directory..." -ForegroundColor Yellow
$modulePath = "$PSScriptRoot"
Remove-Module AutoTaskAPI -ErrorAction SilentlyContinue
Import-Module "$modulePath\AutotaskAPI.psm1" -Force

# Authenticate
Write-Host "[2] Authenticating to AutoTask API..." -ForegroundColor Yellow
$credFile = "C:\ProgramData\MXB\NABLE-CS66194_eric.harless_AutoTask_API_Credentials.Secure.xml"
$AutoTaskAPICreds = Import-Clixml $credFile

$integrationCodeSecure = $AutoTaskAPICreds.IntegrationCode | ConvertTo-SecureString
$integrationcode = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($integrationCodeSecure)
)

$secretSecure = $AutoTaskAPICreds.Secret | ConvertTo-SecureString
$credential = New-Object System.Management.Automation.PSCredential(
    $AutoTaskAPICreds.Username, 
    $secretSecure
)

Add-AutotaskAPIAuth -ApiIntegrationCode $integrationcode -credentials $credential
Write-Host "  ✓ Authentication successful`n" -ForegroundColor Green

# Check initial Queries table state
Write-Host "[3] Checking initial `$Script:Queries table..." -ForegroundColor Yellow
$atModule = Get-Module AutoTaskAPI
$queriesBefore = & $atModule { 
    $Script:Queries | Where-Object { $_.Post -eq 'Products' } | Select-Object Index, Name, Post
}
Write-Host "  Products POST endpoints BEFORE Get-AutotaskAPIResource:" -ForegroundColor Gray
$queriesBefore | Format-Table -AutoSize | Out-String | Write-Host

# Run Get-AutotaskAPIResource (this used to corrupt the table)
Write-Host "[4] Running Get-AutotaskAPIResource -Resource Products..." -ForegroundColor Yellow
$products = Get-AutotaskAPIResource -Resource Products -SimpleSearch 'isActive eq true'
Write-Host "  ✓ Retrieved $($products.Count) products`n" -ForegroundColor Green

# Check Queries table AFTER Get call (should be unchanged)
Write-Host "[5] Checking `$Script:Queries table AFTER Get..." -ForegroundColor Yellow
$queriesAfter = & $atModule { 
    $Script:Queries | Where-Object { $_.Post -eq 'Products' } | Select-Object Index, Name, Post
}
Write-Host "  Products POST endpoints AFTER Get-AutotaskAPIResource:" -ForegroundColor Gray
$queriesAfter | Format-Table -AutoSize | Out-String | Write-Host

# Compare before and after
$corruption = $false
for ($i = 0; $i -lt $queriesBefore.Count; $i++) {
    if ($queriesBefore[$i].Name -ne $queriesAfter[$i].Name) {
        Write-Host "  ✗ CORRUPTION DETECTED!" -ForegroundColor Red
        Write-Host "    Before: $($queriesBefore[$i].Name)" -ForegroundColor Red
        Write-Host "    After:  $($queriesAfter[$i].Name)" -ForegroundColor Red
        $corruption = $true
    }
}

if (-not $corruption) {
    Write-Host "  ✓ No corruption - table unchanged (FIX WORKING!)`n" -ForegroundColor Green
} else {
    Write-Host "  ✗ Table was corrupted (FIX FAILED!)`n" -ForegroundColor Red
    exit 1
}

# Now test New-AutotaskAPIResource
Write-Host "[6] Testing New-AutotaskAPIResource..." -ForegroundColor Yellow

# Query existing product to get valid billing code
$existingProduct = $products | Select-Object -First 1
$billingCodeID = $existingProduct.productBillingCodeID

$testProduct = @{
    name = "TEST-MODULE-FIX-$(Get-Random -Minimum 1000 -Maximum 9999)"
    description = "Test product to verify module fix"
    sku = "TEST-FIX-001"
    isActive = $true
    unitCost = 0.00
    unitPrice = 1.00
    billingType = 2  # Monthly
    periodType = 2   # Monthly
    priceCostMethod = 1  # Fixed price
    isSerialized = $false
    productBillingCodeID = $billingCodeID
}

try {
    Write-Host "  Creating test product: $($testProduct.name)" -ForegroundColor Gray
    $result = New-AutotaskAPIResource -Resource Products -Body $testProduct -ErrorAction Stop
    
    if ($result.itemId) {
        Write-Host "  ✓ Product created successfully - ID: $($result.itemId)" -ForegroundColor Green
        Write-Host "  Note: Test product left in system (Products don't support DELETE)`n" -ForegroundColor Gray
        
        Write-Host "==================================================================" -ForegroundColor Green
        Write-Host "✓ ALL TESTS PASSED - MODULE FIX VERIFIED!" -ForegroundColor Green
        Write-Host "==================================================================`n" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "  ✗ Product creation returned no itemId`n" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ✗ Product creation FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    }
    Write-Host "`n==================================================================" -ForegroundColor Red
    Write-Host "✗ TEST FAILED - MODULE FIX NOT WORKING" -ForegroundColor Red
    Write-Host "==================================================================`n" -ForegroundColor Red
    exit 1
}
