
-- Bases de Datos Aplicadas
-- Fecha de entrega: 29 de Noviembre de 2024
-- Grupo: 20
-- Comision: 2900
-- Alumno: Sabaris, Juan Bautista. 44870533

/*Se requiere que importe toda la información antes mencionada a la base de datos:
• Genere los objetos necesarios (store procedures, funciones, etc.) para importar los archivos antes mencionados. Tenga en cuenta 
que cada mes se recibirán archivos de novedades con la misma estructura, pero datos nuevos para agregar a cada maestro.
• Considere este comportamiento al generar el código. Debe admitir la importación de novedades periódicamente.
• Cada maestro debe importarse con un SP distinto. No se aceptarán scripts que realicen tareas por fuera de un SP.
• La estructura/esquema de las tablas a generar será decisión suya. Puede que deba realizar procesos de transformación sobre los maestros recibidos 
para adaptarlos a la estructura requerida.*/

USE Com2900G20

GO

------------------------------------Importar---------------------------------------


CREATE OR ALTER PROCEDURE importar.importarElectronicAccessories
    @ruta NVARCHAR(255) 
AS
BEGIN
    -- Crear tabla temporal
    CREATE TABLE #TempElectronicAccessories (
        Product varchar(100),
        [Precio Unitario en dolares] decimal(10, 2)
    );
    -- Concatenar la ruta y el nombre del archivo en una sola variable
    DECLARE @rutaCompleta NVARCHAR(255);
    SET @rutaCompleta = @ruta + '\Electronic accessories.xlsx';

    -- Declarar la consulta dinámica para cargar los datos del archivo Excel
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        INSERT INTO #TempElectronicAccessories (Product, [Precio Unitario en dolares])
        SELECT Product, [Precio Unitario en dolares]
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;Database=' + @rutaCompleta + ';HDR=YES'',
            ''SELECT * FROM [Sheet1$]'')';

    -- Ejecutar la consulta dinámica
    EXEC sp_executesql @sql;

	CREATE TABLE #UniqueElectronicAccessories (
        Product varchar(100),
        [Precio Unitario en dolares] decimal(10, 2)
    );

	 INSERT INTO #UniqueElectronicAccessories (Product, [Precio Unitario en dolares])
    SELECT Product, [Precio Unitario en dolares]
    FROM (
        SELECT Product, [Precio Unitario en dolares],
               ROW_NUMBER() OVER (PARTITION BY Product ORDER BY Product) AS row_num
        FROM #TempElectronicAccessories
    ) AS temp
    WHERE row_num = 1; -- Esto selecciona solo la primera aparición de cada producto

    -- Insertar los datos de la tabla temporal en la tabla de destino

	 INSERT INTO bbda.producto (nombre, precio, clasificacion)
    SELECT u.Product, u.[Precio Unitario en dolares], 'Electronica'
    FROM #UniqueElectronicAccessories u
    WHERE NOT EXISTS (
        SELECT 1
        FROM bbda.producto p
        WHERE p.nombre = u.Product COLLATE Modern_Spanish_CI_AS
    )
	
    -- Eliminar la tabla temporal
    DROP TABLE #TempElectronicAccessories;
	DROP TABLE #UniqueElectronicAccessories;

    PRINT 'Datos de Electronic Accessories importados exitosamente';
END;


GO


CREATE OR ALTER PROCEDURE importar.importarCatalogo 
    @ruta NVARCHAR(255)   
AS
BEGIN
    CREATE TABLE #TempCatalogo (
        id INT,
        category VARCHAR(100),
        nombre VARCHAR(100),
        price DECIMAL(10, 2),
        reference_price DECIMAL(10, 2),
        reference_unit VARCHAR(10),
        fecha DATETIME
    );


    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        INSERT INTO #TempCatalogo (id, category, nombre, price, reference_price, reference_unit, fecha)
        SELECT id, category, name, price, reference_price, reference_unit, date
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
            ''Text;Database=' + @ruta + '\;HDR=YES'',
            ''SELECT * FROM [catalogo.csv]'')';

    EXEC sp_executesql @sql;

    -- Insertar en la tabla productos solo los registros que no existen
    WITH UniqueProductos AS (
        SELECT DISTINCT nombre, price, category,
               ROW_NUMBER() OVER (PARTITION BY nombre ORDER BY id) AS RowNum
        FROM #TempCatalogo
    )
    INSERT INTO bbda.producto(nombre, precio, clasificacion)
    SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(u.nombre,'Ã±','ñ'), 'Ã¡', 'á'), 'Ã©', 'é'), 'Ã­', 'í'), 'Ã³', 'ó'), 'Ãº', 'ú') AS texto_corregido, 
	u.price , u.category
    FROM UniqueProductos u
    WHERE RowNum = 1
      AND u.nombre IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM bbda.producto p
          WHERE p.nombre = u.nombre collate Modern_Spanish_CI_AS
      );

    -- Eliminar la tabla temporal
    DROP TABLE #TempCatalogo;

    PRINT 'Datos de catalogo.csv importados exitosamente';
END;
GO

GO



CREATE OR ALTER PROCEDURE importar.importarVentasRegistradas
    @ruta NVARCHAR(255) 
AS
BEGIN

    CREATE TABLE #TempVentas (
        IDFactura VARCHAR(50),TipoFactura CHAR(1),Ciudad VARCHAR(50),TipoCliente VARCHAR(30),Genero VARCHAR(10),
        Producto NVARCHAR(100),PrecioUnitario DECIMAL(10, 2),Cantidad INT,Fecha NVARCHAR(50),Hora TIME, MedioPago VARCHAR(50),
        Empleado INT,IdentificadorPago VARCHAR(25)
    );

    -- Concatenar la ruta y el nombre del archivo CSV
    DECLARE @rutaCompleta NVARCHAR(255);
    SET @rutaCompleta = @ruta + '\Ventas_registradas.csv';

    
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        BULK INSERT #TempVentas
        FROM ''' + @rutaCompleta + '''
        WITH (
            FIELDTERMINATOR = '';'',   -- Especifica el punto y coma como delimitador
            ROWTERMINATOR = ''\n'',    -- Especifica el salto de línea como terminador de fila
            FIRSTROW = 2               -- Omite la primera fila si es encabezado
        )';

    
    EXEC sp_executesql @sql;

    -- Insertar los datos de la tabla temporal en la tabla final, evitando duplicados en IDFactura

	INSERT INTO bbda.ventaRegistrada (
    ciudad, 
    tipoCliente, 
    genero, 
    monto, 
    fecha, 
    hora, 
    empleado
)
SELECT 
    CASE 
        WHEN tv.Ciudad = 'Yangon' THEN 'San Justo'
        WHEN tv.Ciudad = 'Naypyitaw' THEN 'Ramos Mejia'
        WHEN tv.Ciudad = 'Mandalay' THEN 'Lomas del Mirador'
        ELSE tv.Ciudad -- Si no coincide, se mantiene el valor original
    END AS Ciudad,
    tv.TipoCliente,
    tv.Genero,
    tv.Cantidad * tv.PrecioUnitario AS Monto,
    CONVERT(DATE, tv.Fecha, 101) AS Fecha, 
    tv.Hora, 
    tv.Empleado
FROM 
    #TempVentas AS tv;


	DECLARE @p INT;
	SELECT @p = ISNULL(MAX(idVenta), 0) FROM bbda.detalleVenta;

	INSERT INTO bbda.detalleVenta (
	idVenta,idProducto,categoria,cantidad,precio_unitario,monto)
	SELECT 
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + @p, 
        pr.idProducto,
		pr.clasificacion,
		tv.Cantidad,
        tv.PrecioUnitario, 
        tv.Cantidad*tv.PrecioUnitario
    FROM #TempVentas AS tv join bbda.producto pr on pr.nombre=tv.Producto collate Modern_Spanish_CI_AI
	where not exists (select 1 from bbda.detalleVenta d where d.idVenta=@p)


    -- Eliminar la tabla temporal
    DROP TABLE #TempVentas;
	
    PRINT 'Datos de Ventas_registradas.csv importados exitosamente';
END;

GO


CREATE OR ALTER PROCEDURE importar.importarEmpleado
    @ruta NVARCHAR(255)  
AS
BEGIN
    -- Creacion de la tabla temporal con la estructura que coincide con la hoja de Excel
    CREATE TABLE #TempEmpleados (
        Legajo VARCHAR(10),           
        Nombre NVARCHAR(50),           
        Apellido NVARCHAR(50),         
        DNI CHAR(9),				   
        Direccion VARCHAR(150),       
        EmailPersonal VARCHAR(100),   
        EmailEmpresa VARCHAR(100),    
        CUIL VARCHAR(100),             
        Cargo VARCHAR(50),             
        Sucursal VARCHAR(50),         
        Turno VARCHAR(50)              
    );

    -- Concatenar la ruta y el nombre del archivo Excel
    DECLARE @rutaCompleta NVARCHAR(255);
    SET @rutaCompleta = @ruta + '\Informacion_complementaria.xlsx';


    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
    INSERT INTO #TempEmpleados (Legajo, Nombre, Apellido, DNI, Direccion, EmailPersonal, EmailEmpresa, CUIL, Cargo, Sucursal, Turno)
    SELECT 
        [Legajo/ID] AS Legajo,
        Nombre, 
        Apellido, 
        CAST(DNI AS INT),
        Direccion, 
        REPLACE(REPLACE(REPLACE([email personal], '' '', ''''), CHAR(160), ''''), CHAR(9), '''') AS EmailPersonal, 
        REPLACE(REPLACE(REPLACE([email empresa], '' '', ''''), CHAR(160), ''''), CHAR(9), '''') AS EmailEmpresa, 
        CUIL, 
        Cargo, 
        Sucursal, 
        Turno
    FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0;Database=' + @rutaCompleta + ';HDR=YES'',
        ''SELECT * FROM [Empleados$]'')';


    EXEC sp_executesql @sql;

	OPEN SYMMETRIC KEY ClaveEncriptacionEmpleado DECRYPTION BY PASSWORD = 'ventaaurorasa';
    PRINT 'Clave simétrica abierta correctamente.';

    INSERT INTO bbda.empleado ( 
        Nombre, 
        Apellido, 
        DNI, 
        Direccion, 
        EmailPersonal, 
        EmailEmpresa, 
        CUIL, 
        Cargo, 
        Sucursal, 
        Turno
    )
    SELECT 
        Nombre, 
        Apellido, 
        ENCRYPTBYKEY(KEY_GUID('ClaveEncriptacionEmpleado'), CONVERT(NVARCHAR(500), DNI)) ,  
        ENCRYPTBYKEY(KEY_GUID('ClaveEncriptacionEmpleado'), CONVERT(NVARCHAR(500),Direccion)),  
        EmailPersonal, 
        EmailEmpresa,  
        ENCRYPTBYKEY(KEY_GUID('ClaveEncriptacionEmpleado'), CONVERT(NVARCHAR(500),CONCAT('00-', RIGHT('00000000' + CAST(DNI AS NVARCHAR(8)), 8), '-0'))),  
        Cargo, 
        Sucursal, 
        CASE 
			WHEN Turno = 'TM' THEN 'TM'
			WHEN Turno = 'TT' THEN 'TT'
			WHEN Turno = 'Jornada completa' THEN 'JC'
			ELSE Turno 
		END AS Turno
    FROM #TempEmpleados AS te
    WHERE NOT EXISTS (
        SELECT 1 
        FROM bbda.empleado AS e 
        WHERE CONVERT(NVARCHAR(500), DECRYPTBYKEY(e.DNI)) = te.DNI
    ) AND te.DNI is not null

	CLOSE SYMMETRIC KEY ClaveEncriptacionEmpleado;

    -- 6. Eliminar la tabla temporal
    DROP TABLE #TempEmpleados;

    PRINT 'Datos de Informacion Complementaria(empleados) importados exitosamente';
END;
GO



CREATE OR ALTER PROCEDURE importar.importarClasificacionProducto
    @ruta NVARCHAR(255)  
AS
BEGIN
   
    CREATE TABLE #TempClasificacionProductos (
        LineaDeProducto VARCHAR(30),
        Producto VARCHAR(70)
    );

    DECLARE @rutaCompleta NVARCHAR(255);
    SET @rutaCompleta = @ruta + '\Informacion_complementaria.xlsx';

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
    INSERT INTO #TempClasificacionProductos (LineaDeProducto, Producto)
    SELECT [Línea de producto], Producto
    FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', 
        ''Excel 12.0;Database=' + @rutaCompleta + ';HDR=YES'',
        ''SELECT * FROM [Clasificacion productos$]'')';

    EXEC sp_executesql @sql;

    INSERT bbda.clasificacionProducto(LineaDeProducto, Producto)
    SELECT tp.LineaDeProducto, tp.Producto
    FROM #TempClasificacionProductos AS tp
    WHERE NOT EXISTS (
        SELECT 1 
        FROM bbda.clasificacionProducto AS cp 
        WHERE cp.LineaDeProducto = tp.LineaDeProducto collate Modern_Spanish_CI_AS
        AND cp.Producto = tp.Producto collate Modern_Spanish_CI_AS
    );

	if not exists (select 1 from bbda.clasificacionProducto where LineaDeProducto = 'Electronica')
	begin
	INSERT bbda.clasificacionProducto(LineaDeProducto,Producto)
	values ('Electronica','Electronica'),('Importado','Importado')
	end

    -- Limpiar tabla temporal
    DROP TABLE #TempClasificacionProductos;
    
    PRINT 'Datos de Informacion Complementaria(clasificacion productos) importados exitosamente';
END;
GO



CREATE OR ALTER PROCEDURE importar.importarProductosImportados
    @ruta NVARCHAR(255)  
AS
BEGIN
    CREATE TABLE #TempProductos (
        IdProducto VARCHAR(10),  
        NombreProducto NVARCHAR(100),
        Proveedor NVARCHAR(100),
        Categoria VARCHAR(100),
        CantidadPorUnidad VARCHAR(50),
        PrecioUnidad DECIMAL(10, 2)
    );

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        INSERT INTO #TempProductos (IdProducto, NombreProducto, Proveedor, Categoria, CantidadPorUnidad, PrecioUnidad)
        SELECT IdProducto, NombreProducto, Proveedor, Categoría, CantidadPorUnidad, PrecioUnidad
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', 
            ''Excel 12.0;Database=' + @ruta + '\Productos_importados.xlsx;HDR=YES'',
            ''SELECT * FROM [Listado de Productos$]'');';

    EXEC sp_executesql @sql;


	INSERT INTO bbda.producto(nombre,precio,clasificacion)
	select tp.NombreProducto,tp.PrecioUnidad * d.valor , 'Importado'
	from #TempProductos AS tp
	JOIN bbda.cotizacionDolar d on d.tipo='dolarOficial'
	WHERE NOT EXISTS (
		SELECT 1
		FROM bbda.producto as p
		WHERE p.nombre = tp.NombreProducto collate Modern_Spanish_CI_AS
	)
	AND tp.IdProducto IS NOT NULL;  

    DROP TABLE #TempProductos;

	PRINT 'Datos de Productos_Importados importados exitosamente';
END;

go



CREATE OR ALTER PROCEDURE importar.importarSucursal
    @ruta VARCHAR(255) 
AS
BEGIN

    DECLARE @RutaCompleta VARCHAR(500);
    DECLARE @sql NVARCHAR(MAX);

    SET @RutaCompleta = @ruta + '\Informacion_complementaria.xlsx';
    
    CREATE TABLE #TempSucursal (
        Ciudad VARCHAR(20),
        Reemplazar_por VARCHAR(100),
        direccion VARCHAR(255),
        Horario VARCHAR(50),
        Telefono VARCHAR(50)
    );

    SET @sql = N'
        INSERT INTO #TempSucursal (Ciudad, Reemplazar_por, direccion, Horario, Telefono)
        SELECT 
            Ciudad, 
            [Reemplazar por], 
            direccion, 
            Horario, 
            Telefono
        FROM 
            OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', 
                       ''Excel 12.0; Database=' + @RutaCompleta + ';'', 
                       ''SELECT * FROM [sucursal$]'')';

    EXEC sp_executesql @sql;

    INSERT INTO bbda.sucursal (ciudad, direccion, horario, telefono)
    SELECT 
        ts.Reemplazar_por,
        ts.direccion,
        ts.Horario,
        ts.Telefono
    FROM #TempSucursal ts
    WHERE NOT EXISTS (
        SELECT 1
        FROM bbda.sucursal s
        WHERE s.ciudad = ts.Reemplazar_por COLLATE Modern_Spanish_CI_AS
    );

    DROP TABLE #TempSucursal;

	PRINT 'Datos de Informacion Complementaria(sucursal) importados exitosamente';
END;