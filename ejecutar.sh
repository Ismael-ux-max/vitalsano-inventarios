#!/bin/sh
# Compila y ejecuta el sistema de inventario de VitalSano (requiere JDK 11 o superior).
cd "$(dirname "$0")" || exit 1
mkdir -p out
javac -encoding UTF-8 -d out src/modelo/*.java src/negocio/*.java src/interfaz/*.java || exit 1
java -Dfile.encoding=UTF-8 -Dstdout.encoding=UTF-8 -cp out interfaz.Main
