
-- Bases de Datos Aplicadas
-- Fecha de entrega: 29 de Noviembre de 2024
-- Grupo: 20
-- Comision: 2900
-- Alumno: Sabaris, Juan Bautista. 44870533

/*Creación de reportes:
El sistema debe ofrecer los siguientes reportes en xml.
Mensual: ingresando un mes y año determinado mostrar el total facturado por días de la semana, incluyendo sábado y domingo.
Trimestral: mostrar el total facturado por turnos de trabajo por mes.
Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar la cantidad de productos vendidos en ese rango,
ordenado de mayor a menor.
Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar la cantidad de productos vendidos en ese rango por sucursal, 
ordenado de mayor a menor.
Mostrar los 5 productos más vendidos en un mes, por semana.
Mostrar los 5 productos menos vendidos en el mes.
Mostrar total acumulado de ventas (o sea tambien mostrar el detalle) para una fecha y sucursal particulares.*/


USE Com2900G20

GO

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

GO


CREATE OR ALTER PROCEDURE reporte.facturacionMensualPorDiaDeSemana
    @mes INT, 
    @anio INT  
AS
BEGIN
    -- Crear una consulta para obtener el total facturado por día de la semana en formato XML
    DECLARE @sql NVARCHAR(MAX);
    
    SET @sql = '
    SELECT 
        DATENAME(WEEKDAY, fecha) AS DiaSemana, 
        SUM(monto)
    FROM 
        bbda.ventaRegistrada
    WHERE 
        MONTH(fecha) = @mes AND YEAR(fecha) = @anio
    GROUP BY 
        DATENAME(WEEKDAY, fecha)
    ORDER BY 
        CASE 
            WHEN DATENAME(WEEKDAY, fecha) = ''Monday'' THEN 1
            WHEN DATENAME(WEEKDAY, fecha) = ''Tuesday'' THEN 2
            WHEN DATENAME(WEEKDAY, fecha) = ''Wednesday'' THEN 3
            WHEN DATENAME(WEEKDAY, fecha) = ''Thursday'' THEN 4
            WHEN DATENAME(WEEKDAY, fecha) = ''Friday'' THEN 5
            WHEN DATENAME(WEEKDAY, fecha) = ''Saturday'' THEN 6
            WHEN DATENAME(WEEKDAY, fecha) = ''Sunday'' THEN 7
        END
    FOR XML PATH(''ReporteFacturacion'')';

    -- Ejecutar la consulta dinámica y devolver el resultado como XML
    EXEC sp_executesql @sql, N'@mes INT, @anio INT', @mes, @anio;
END;


GO




CREATE OR ALTER PROCEDURE reporte.facturacionTrimestralPorTurnosPorMes
    @turno VARCHAR(50),
    @trimestre INT,      
    @anio INT            
AS
BEGIN
    -- Declaramos una variable para construir la consulta dinámica en formato XML
    DECLARE @sql NVARCHAR(MAX);

    -- Construimos la consulta dinámica en la variable @sql
    SET @sql = '
        SELECT 
            SUM(monto) AS TotalFacturacion,
            CASE 
                WHEN DATEPART(HOUR, hora) BETWEEN 8 AND 13 THEN ''Mañana''
                WHEN DATEPART(HOUR, hora) BETWEEN 14 AND 23 THEN ''Tarde''
            END AS Turno,
            MONTH(fecha) AS Mes
        FROM bbda.ventaRegistrada
        WHERE 
            YEAR(fecha) = @anio 
            AND ( 
                (@trimestre = 1 AND MONTH(fecha) IN (1, 2, 3)) OR
                (@trimestre = 2 AND MONTH(fecha) IN (4, 5, 6)) OR
                (@trimestre = 3 AND MONTH(fecha) IN (7, 8, 9)) OR
                (@trimestre = 4 AND MONTH(fecha) IN (10, 11, 12))
            )
            AND CASE 
                    WHEN DATEPART(HOUR, hora) BETWEEN 8 AND 13 THEN ''Mañana''
                    WHEN DATEPART(HOUR, hora) BETWEEN 14 AND 23 THEN ''Tarde''
                END = @turno
        GROUP BY 
            CASE 
                WHEN DATEPART(HOUR, hora) BETWEEN 8 AND 13 THEN ''Mañana''
                WHEN DATEPART(HOUR, hora) BETWEEN 14 AND 23 THEN ''Tarde''
            END,
            MONTH(fecha)
		FOR XML PATH(''ReporteFacturacionTrimestral'')
    ';

    -- Ejecutamos la consulta dinámica
    EXEC sp_executesql @sql,
        N'@turno VARCHAR(50), @trimestre INT, @anio INT',
        @turno = @turno, 
        @trimestre = @trimestre, 
        @anio = @anio;
END;


GO



CREATE OR ALTER PROCEDURE reporte.productosVendidosPorRangoFechas
    @fecha_inicio DATE,  
    @fecha_fin DATE      
AS
BEGIN
    -- Declaramos una variable para construir la consulta dinámica en formato XML
    DECLARE @sql NVARCHAR(MAX);

    -- Construimos la consulta dinámica en la variable @sql
    SET @sql = '
        SELECT 
            p.nombre AS Producto, 
            SUM(dv.cantidad) AS CantidadVendida
        FROM 
            bbda.detalleVenta dv
        INNER JOIN 
            bbda.ventaRegistrada vr ON dv.idVenta = vr.idVenta
        INNER JOIN 
            bbda.producto p ON dv.idProducto = p.idProducto
        WHERE 
            vr.fecha BETWEEN @fecha_inicio AND @fecha_fin
        GROUP BY 
            p.nombre
        ORDER BY 
            CantidadVendida DESC
        FOR XML PATH(''ReportePorFechas'')
    ';

    -- Ejecutamos la consulta dinámica con los parámetros de fecha
    EXEC sp_executesql @sql,
        N'@fecha_inicio DATE, @fecha_fin DATE',
        @fecha_inicio = @fecha_inicio, 
        @fecha_fin = @fecha_fin;
END;


GO




CREATE OR ALTER PROCEDURE reporte.productosVendidosPorSucursalPorRangoFechas
    @fecha_inicio DATE,  
    @fecha_fin DATE     
AS
BEGIN
    -- Declaramos una variable para construir la consulta dinámica en formato XML
    DECLARE @sql NVARCHAR(MAX);

    -- Construimos la consulta dinámica en la variable @sql
    SET @sql = '
        SELECT 
            vr.ciudad AS Sucursal,
            p.nombre AS Producto,
            SUM(dv.cantidad) AS CantidadVendida
        FROM 
            bbda.detalleVenta dv
        INNER JOIN 
            bbda.ventaRegistrada vr ON dv.idVenta = vr.idVenta
        INNER JOIN 
            bbda.producto p ON dv.idProducto = p.idProducto
        WHERE 
            vr.fecha BETWEEN @fecha_inicio AND @fecha_fin
        GROUP BY 
            vr.ciudad, p.nombre
        ORDER BY 
            CantidadVendida DESC
        FOR XML PATH(''ReportePorFechasPorSucursal'')
    ';

    -- Ejecutamos la consulta dinámica con los parámetros de fecha
    EXEC sp_executesql @sql,
        N'@fecha_inicio DATE, @fecha_fin DATE',
        @fecha_inicio = @fecha_inicio, 
        @fecha_fin = @fecha_fin;
END;


GO




CREATE OR ALTER PROCEDURE reporte.productosMasVendidosPorSemana
    @mes INT,  -- Mes para el reporte 
    @anio INT   -- Año para el reporte
AS
BEGIN
    -- Declaramos una variable para el SQL dinámico
    DECLARE @sql NVARCHAR(MAX);

    -- Construimos la consulta dinámica en la variable @sql
    SET @sql = '
        WITH ProductosConRanking AS (
            SELECT 
                DATEPART(WEEK, vr.fecha) AS Semana, -- Calcula la semana de la venta
                p.nombre AS Producto,
                SUM(dv.cantidad) AS CantidadVendida,
                ROW_NUMBER() OVER (PARTITION BY DATEPART(WEEK, vr.fecha), vr.ciudad ORDER BY SUM(dv.cantidad) DESC) AS Ranking
            FROM 
                bbda.ventaRegistrada vr
            INNER JOIN 
                bbda.detalleVenta dv ON vr.idVenta = dv.idVenta
            INNER JOIN 
                bbda.producto p ON dv.idProducto = p.idProducto
            WHERE 
                MONTH(vr.fecha) = @mes AND YEAR(vr.fecha) = @anio -- Filtra por mes y año
            GROUP BY 
                DATEPART(WEEK, vr.fecha), p.nombre, vr.ciudad
        )
        SELECT 
            Semana,
            Producto,
            CantidadVendida
        FROM 
            ProductosConRanking
        WHERE 
            Ranking <= 5 -- Solo los 5 productos más vendidos
        ORDER BY 
            Semana,  Ranking
        FOR XML PATH(''Reporte5ProductosPorSemana'');
    ';

    -- Ejecutamos la consulta dinámica con los parámetros del mes y año
    EXEC sp_executesql @sql, N'@mes INT, @anio INT', @mes, @anio;
END;


GO




CREATE OR ALTER PROCEDURE reporte.productosMenosVendidosPorMes
    @mes INT,  -- Mes para el reporte 
    @anio INT   -- Año para el reporte
AS
BEGIN
    -- Declaramos una variable para el SQL dinámico
    DECLARE @sql NVARCHAR(MAX);

    -- Construimos la consulta dinámica en la variable @sql
    SET @sql = '
        WITH ProductosConRanking AS (
            SELECT 
                p.nombre AS Producto,  -- Nombre del producto
                SUM(dv.cantidad) AS CantidadVendida,
                ROW_NUMBER() OVER (ORDER BY SUM(dv.cantidad) ASC) AS Ranking  -- Ordenamos de menor a mayor por cantidad vendida
            FROM 
                bbda.ventaRegistrada vr
            INNER JOIN bbda.detalleVenta dv ON vr.idVenta = dv.idVenta
            INNER JOIN bbda.producto p ON dv.idProducto = p.idProducto
            WHERE 
                MONTH(vr.fecha) = @mes AND YEAR(vr.fecha) = @anio  -- Filtra por mes y año
            GROUP BY 
                p.nombre  -- Agrupamos por nombre de producto
        )
        SELECT 
            Producto,
            CantidadVendida
        FROM 
            ProductosConRanking
        WHERE 
            Ranking <= 5  -- Solo los 5 productos menos vendidos
        ORDER BY 
            CantidadVendida ASC  -- Ordenamos de menor a mayor cantidad vendida
        FOR XML PATH(''Reporte5ProductosMenosVendidos'');
    ';

    -- Ejecutamos la consulta dinámica con los parámetros del mes y año
    EXEC sp_executesql @sql, N'@mes INT, @anio INT', @mes, @anio;
END;


GO


CREATE OR ALTER PROCEDURE reporte.acumuladoVentasPorFechaYSucursal
    @fecha DATE,  -- Fecha para el reporte
    @sucursal VARCHAR(50)  -- Sucursal para el reporte
AS
BEGIN
    -- Crear una consulta para obtener el total acumulado de ventas por fecha y sucursal en formato XML
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = '
    SELECT 
        p.nombre AS Producto,  -- Nombre del producto desde la tabla productos
        SUM(dv.cantidad) AS CantidadVendida,
        SUM(dv.precio_unitario * dv.cantidad) AS TotalFacturado,
        f.ciudad AS Sucursal,
        f.fecha
    FROM 
        bbda.detalleVenta dv
    INNER JOIN bbda.ventaRegistrada f
        ON f.idVenta = dv.idVenta
    INNER JOIN bbda.producto p
        ON p.idProducto = dv.idProducto
    WHERE 
        f.fecha = @fecha AND f.ciudad = @sucursal
    GROUP BY 
        p.nombre, f.ciudad, f.fecha
    ORDER BY 
        TotalFacturado DESC
    FOR XML PATH(''ReporteTotalAcumuladoVentas'')
    ';

    -- Ejecutar la consulta dinámica y devolver el resultado como XML
    EXEC sp_executesql @sql, N'@fecha DATE, @sucursal VARCHAR(50)', @fecha, @sucursal;
END;


GO