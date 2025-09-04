# tarea1_paradigmas

1. Introducción
Este manual de usuario describe el uso del programa desarrollado en lenguaje ensamblador como parte de la tarea 1 del curso Paradigmas de Programación. El sistema permite gestionar y procesar expedientes estudiantiles mediante ingreso y validación de datos, mostrando resultados en pantalla.
2. Requisitos del Sistema
- Sistema operativo: Windows, Linux o macOS (con emulador adecuado)
- Emulador: emu8086 
- Archivo fuente: tarea1.asm
- Documentación de apoyo: PDF de bitácora y documentación técnica incluida en el proyecto
3. Instalación
1. Descargue e instale emu8086 desde el sitio oficial.
2. Descomprima el archivo entregado (tarea_1_paradigmas.zip).
3. Abra el archivo tarea1.asm en el emulador.
4. Compile el programa desde el menú 'Compile'.
5. Ejecute el programa seleccionando 'Run'.
4. Uso del Programa
Al iniciar el programa, se muestra un menú principal con 5 opciones. El usuario debe ingresar el número de la opción y presionar Enter.
Opción 1: Ingresar estudiante
•	Ingrese el nombre (máx. 40 caracteres).
•	Ingrese la nota (entre 0 y 100, con hasta 5 decimales).
•	El sistema guarda el estudiante y confirma el índice en la tabla.
Opción 2: Mostrar estadísticas
Muestra en pantalla:
•	Promedio general de las notas.
•	Cantidad y porcentaje de aprobados y reprobados.
•	Estudiante con nota máxima (nombre e índice).
•	Estudiante con nota mínima (nombre e índice).
Opción 3: Buscar estudiante por índice
•	Ingrese el número de índice del estudiante (0 … cantidad registrada – 1).
•	El sistema muestra su nombre y nota.
Opción 4: Ordenar
•	Permite ordenar los estudiantes por nota.
o	1: Orden ascendente (menor a mayor).
o	2: Orden descendente (mayor a menor).
o	3: Cancelar.
•	Después de ordenar, se muestra la tabla de estudiantes.
Opción 5: Salir
•	Termina la ejecución del programa y vuelve al sistema operativo.
5. Ejemplo de Ejecución
Ejemplo:
- El usuario ingresa una nota válida en formato numérico.
- El programa procesa la información y confirma que ha sido registrada.
- En caso de error, se mostrará un mensaje indicando el problema (ejemplo: 'Nota fuera de rango').
6. Solución de Problemas Comunes
- Error: 'Invalid opcode'. Solución: verificar que se esté utilizando emu8086.
- El programa no compila. Solución: asegúrese de abrir el archivo correcto (tarea1.asm).
- El emulador se cierra. Solución: reinstalar emu8086 o usar DOSBox como alternativa.
7. Créditos
Este manual fue elaborado por los autores del proyecto con el fin de guiar a los usuarios en la instalación, ejecución y uso del programa desarrollado en lenguaje ensamblador.
