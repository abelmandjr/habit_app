@echo off
echo Criando estrutura do projeto Flutter Habit App...

:: =========================
:: CORE
:: =========================
mkdir lib\core
mkdir lib\core\constants
mkdir lib\core\theme
mkdir lib\core\routes
mkdir lib\core\services
mkdir lib\core\database
mkdir lib\core\utils
mkdir lib\core\errors

:: =========================
:: SHARED
:: =========================
mkdir lib\shared
mkdir lib\shared\widgets
mkdir lib\shared\models

:: =========================
:: FEATURES
:: =========================

:: ONBOARDING
mkdir lib\features\onboarding\presentation
mkdir lib\features\onboarding\presentation\pages
mkdir lib\features\onboarding\presentation\widgets
mkdir lib\features\onboarding\providers

:: AUTH
mkdir lib\features\auth\data
mkdir lib\features\auth\data\datasource
mkdir lib\features\auth\data\models
mkdir lib\features\auth\data\repositories
mkdir lib\features\auth\domain
mkdir lib\features\auth\domain\entities
mkdir lib\features\auth\domain\repositories
mkdir lib\features\auth\domain\usecases
mkdir lib\features\auth\presentation
mkdir lib\features\auth\presentation\pages
mkdir lib\features\auth\presentation\widgets
mkdir lib\features\auth\presentation\providers

:: DASHBOARD
mkdir lib\features\dashboard\presentation
mkdir lib\features\dashboard\presentation\pages
mkdir lib\features\dashboard\presentation\widgets
mkdir lib\features\dashboard\presentation\providers

:: HABITS
mkdir lib\features\habits\data
mkdir lib\features\habits\data\datasource
mkdir lib\features\habits\data\models
mkdir lib\features\habits\data\repositories

mkdir lib\features\habits\domain
mkdir lib\features\habits\domain\entities
mkdir lib\features\habits\domain\repositories
mkdir lib\features\habits\domain\usecases

mkdir lib\features\habits\presentation
mkdir lib\features\habits\presentation\pages
mkdir lib\features\habits\presentation\widgets
mkdir lib\features\habits\presentation\providers

:: STATISTICS
mkdir lib\features\statistics\presentation
mkdir lib\features\statistics\presentation\pages
mkdir lib\features\statistics\presentation\widgets
mkdir lib\features\statistics\presentation\providers

:: PROFILE
mkdir lib\features\profile\presentation
mkdir lib\features\profile\presentation\pages
mkdir lib\features\profile\presentation\widgets
mkdir lib\features\profile\presentation\providers

:: ASSETS
mkdir assets
mkdir assets\icons
mkdir assets\images
mkdir assets\animations
mkdir assets\fonts

echo.
echo Estrutura criada com sucesso!
pause