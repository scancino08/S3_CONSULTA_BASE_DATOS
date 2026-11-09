/* ====================================================================
   PRY2205 - Consulta de Bases de Datos
   Semana 3 - Actividad sumativa: "Aplicando funciones de agrupacion"
   Usuario BD : PRY2205_S3
   Ejecutar   : abrir este archivo en SQL Developer con la conexion
                PRY2205_ACTIVIDAD_S3 y presionar F5 (Ejecutar script).
   Pedira 2 valores de sustitucion:
     - VALOR_TOTAL_GASTO_COMUN (Caso 1)  ej: 100000
     - CODIGO_SUCURSAL         (Caso 2)  ej: 30
   ==================================================================== */

SET VERIFY OFF
SET FEEDBACK ON
SET LINESIZE 250
SET PAGESIZE 100
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

/* ====================================================================
   CASO 1: Analisis de Propiedades
   - Resumen por tipo de propiedad
   - Solo tipos cuyo total de gasto comun supera el valor ingresado
   - Clasificacion: hasta $1.000.000 = ESTANDAR, sobre eso = PREMIUM
   - Orden: total gasto comun descendente
   ==================================================================== */
SELECT p.id_tipo_propiedad                                                   AS TIPO,
       COUNT(*)                                                              AS TOTAL_PROPIEDADES,
       TO_CHAR(MAX(p.valor_arriendo),
               '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')              AS MAX_ARRIENDO,
       TO_CHAR(ROUND(AVG(p.valor_arriendo)),
               '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')              AS PROMEDIO_ARRIENDO,
       TO_CHAR(MIN(p.valor_arriendo),
               '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')              AS MIN_ARRIENDO,
       CASE
         WHEN MAX(p.valor_arriendo) <= 1000000 THEN UNISTR('EST\00C1NDAR')
         ELSE 'PREMIUM'
       END                                                                   AS CLASIFICACION,
       TO_CHAR(SUM(NVL(p.valor_gasto_comun, 0)),
               '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')              AS TOTAL_GASTOS_COMUNES
FROM   propiedad p
GROUP BY p.id_tipo_propiedad
HAVING SUM(NVL(p.valor_gasto_comun, 0)) > &VALOR_TOTAL_GASTO_COMUN
ORDER BY SUM(NVL(p.valor_gasto_comun, 0)) DESC;


/* ====================================================================
   CASO 2: Analisis de antiguedad de empleados
   - Categoria 3 (Ejecutivo de Arriendo), mas de 5 anios de antiguedad
   - Que NO pertenezcan a la sucursal ingresada por el operador
   - Nivel de sueldo: ALTO (> 2.000.000) / MEDIO (<= 2.000.000)
   - Bono: 5-10 anios = 5% | 11-20 anios = 10% | mas de 20 = 15%
   - Orden: sueldo descendente
   ==================================================================== */
SELECT e.nombre_emp || ' ' || e.appaterno_emp                                AS "Nombre Empleado",
       TO_CHAR(e.sueldo_emp,
               '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')              AS "Sueldo con Formato",
       CASE
         WHEN e.sueldo_emp > 2000000 THEN 'ALTO'
         ELSE 'MEDIO'
       END                                                                   AS "Clasificación Sueldo",
       e.anios                                                               AS "Años Antigüedad",
       'Corresponde bono '
         || LPAD(CASE
                   WHEN e.anios > 20 THEN 15
                   WHEN e.anios > 10 THEN 10
                   ELSE 5
                 END, 2)
         || '%:'
         || LPAD(TO_CHAR(ROUND(e.sueldo_emp * CASE
                                                WHEN e.anios > 20 THEN 0.15
                                                WHEN e.anios > 10 THEN 0.10
                                                ELSE 0.05
                                              END),
                         '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.'''), 13)  AS "BONO"
FROM  (SELECT emp.*,
              TRUNC(MONTHS_BETWEEN(SYSDATE, emp.fecing_emp) / 12) AS anios
       FROM   empleado emp) e
WHERE  e.id_categoria_emp = 3
AND    e.id_sucursal <> &CODIGO_SUCURSAL
AND    e.anios > 5
ORDER BY e.sueldo_emp DESC;


/* ====================================================================
   CASO 3: Lista de clientes
   - Clasificacion por renta:
       PREMIUM >= 1.000.000 | ALTA 600.000-999.999
       MEDIA 300.000-599.999 | BAJA < 300.000
   - Cantidad de clientes y renta promedio (redondeada) por clasificacion
   - Solo se consideran promedios de renta sobre $200.000
   - Estado telefono: "Sin Telefono" si NINGUN cliente del grupo tiene
     telefono registrado; "con Telefono" si al menos uno lo tiene
   ==================================================================== */
SELECT c.clasificacion_renta                                                 AS CLASIFICACION_RENTA,
       COUNT(*)                                                              AS CANTIDAD_CLIENTES,
       TO_CHAR(ROUND(AVG(c.renta_cli)),
               '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')              AS RENTA_PROMEDIO,
       CASE
         WHEN MAX(NVL(c.celular_cli, 0)) = 0 THEN UNISTR('Clientes Sin Tel\00E9fono')
         ELSE UNISTR('Clientes con Tel\00E9fono')
       END                                                                   AS ESTADO_TELEFONO
FROM  (SELECT cli.renta_cli,
              cli.celular_cli,
              CASE
                WHEN cli.renta_cli >= 1000000 THEN 'PREMIUM'
                WHEN cli.renta_cli >= 600000  THEN 'ALTA'
                WHEN cli.renta_cli >= 300000  THEN 'MEDIA'
                ELSE 'BAJA'
              END AS clasificacion_renta
       FROM   cliente cli) c
GROUP BY c.clasificacion_renta
HAVING AVG(c.renta_cli) > 200000
ORDER BY AVG(c.renta_cli) DESC;
