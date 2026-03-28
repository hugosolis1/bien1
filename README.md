# Calculadora Planetaria

Calculadora de posiciones planetarias precisa usando **Swiss Ephemeris** - el estándar de la industria astrológica.

## Características

- **Cálculos precisos**: Usa Swiss Ephemeris con precisión de 0.001 arcsegundos
- **Posiciones planetarias**: Sol, Luna, Mercurio, Venus, Marte, Júpiter, Saturno, Urano, Neptuno, Plutón, Quirón
- **Casas astrológicas**: Ascendente (ASC), Medium Coeli (MC), Descendente (DESC), Imum Coeli (IC)
- **Modos de cálculo**: Geocéntrico / Heliocéntrico
- **Zodiaco**: Tropical / Sidereal (con múltiples ayanamsas: Lahiri, Fagan Bradley, Raman, Krishnamurti)
- **Búsqueda de grado planetario**: Encuentra cuándo un planeta cruza un grado específico

## Instalación para desarrollo

```bash
# Clonar el repositorio
git clone https://github.com/TU_USUARIO/planetary_calculator.git
cd planetary_calculator

# Instalar dependencias
flutter pub get

# Ejecutar en desarrollo
flutter run
```

## Compilar para iOS (IPA)

### Opción 1: Usando Codemagic (Recomendado - Gratis)

1. Sube este proyecto a GitHub
2. Ve a [codemagic.io](https://codemagic.io) e inicia sesión con GitHub
3. Crea una nueva aplicación y selecciona este repositorio
4. Configura el build para iOS
5. El IPA se generará automáticamente

### Opción 2: Mac local con Xcode

```bash
# En Mac con Xcode instalado
flutter pub get
flutter build ipa --release
```

## Uso

1. Selecciona fecha y hora (UTC)
2. Elige modo de cálculo (Geocéntrico/Heliocéntrico)
3. Elige zodiaco (Tropical/Sideral)
4. Presiona "Calcular Posiciones"
5. Verás las posiciones precisas de todos los planetas

## Búsqueda de grado

1. Ve a la pestaña "Buscar Grado"
2. Selecciona el planeta
3. Ingresa el grado a buscar
4. Define el rango de fechas
5. Presiona "Buscar"

## Notas técnicas

- **Precisión**: 0.001 arcsegundos (Swiss Ephemeris)
- **Efemérides**: Incluidas en el paquete sweph
- **Compatible**: iOS, Android, Web, Desktop

## Licencia

MIT License
