#!/bin/bash

# Instalar Flutter si no está disponible
if ! command -v flutter &> /dev/null; then
    echo "Instalando Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:$(pwd)/flutter/bin"
fi

# Actualizar Flutter
echo "Actualizando Flutter..."
flutter upgrade

# Obtener dependencias
echo "Obteniendo dependencias..."
flutter pub get

# Compilar para web
echo "Compilando para web..."
flutter build web --release --no-tree-shake-icons

echo "Build completado!"
