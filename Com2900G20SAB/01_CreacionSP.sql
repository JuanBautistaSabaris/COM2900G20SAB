
-- Bases de Datos Aplicadas
-- Fecha de entrega: 29 de Noviembre de 2024
-- Grupo: 20
-- Comision: 2900
-- Alumno: Sabaris, Juan Bautista. 44870533

/*Genere store procedures para manejar la inserción, modificado, borrado (si corresponde,
también debe decidir si determinadas entidades solo admitirán borrado lógico) de cada tabla.
Los nombres de los store procedures NO deben comenzar con “SP”.
El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
de entrega, número de grupo, nombre de la materia, nombres y DNI de los alumnos.
Entregar todo en un zip cuyo nombre sea Grupo_XX.zip mediante la sección de prácticas de
MIEL. Solo uno de los miembros del grupo debe hacer la entrega.
Cuando un cliente reclama la devolución de un producto se genera una nota de crédito por 
el valor del producto o un producto del mismo tipo.
Tener en cuenta que la nota de crédito debe estar asociada a una Factura con estado pagada.
*/

USE Com2900G20
GO

------------------------------------Insertar-----------------------------------------

CREATE OR ALTER PROCEDURE sucursal.insertarSucursal
    @Ciudad VARCHAR(20),
    @Direccion VARCHAR(100),
    @Horario VARCHAR(50),
    @Telefono VARCHAR(20)
AS
BEGIN
    -- Verifica si ya existe una sucursal en la misma ciudad
    IF EXISTS (SELECT 1 FROM bbda.sucursal WHERE ciudad = @Ciudad)
    BEGIN
        PRINT 'Ya existe una sucursal en esta ciudad';
    END
    ELSE
    BEGIN
        -- Inserta la sucursal en la tabla si no existe una en la misma ciudad
        INSERT INTO bbda.sucursal (ciudad, direccion, horario, telefono)
        VALUES (@Ciudad, @Direccion, @Horario, @Telefono);

        PRINT 'Sucursal insertada exitosamente';
    END
END;

GO


CREATE OR ALTER PROCEDURE empleado.insertarEmpleado
    @Nombre VARCHAR(50),
    @Apellido VARCHAR(50),
    @DNI VARCHAR(20),
    @Direccion VARCHAR(150),
    @EmailPersonal NVARCHAR(100),
    @EmailEmpresa NVARCHAR(100),
    @CUIL VARCHAR(20),
    @Cargo VARCHAR(50),
    @Sucursal VARCHAR(50),
    @Turno VARCHAR(50)
AS
BEGIN
    OPEN SYMMETRIC KEY ClaveEncriptacionEmpleado DECRYPTION BY PASSWORD = 'ventaaurorasa';

    -- Validación de longitud y formato de DNI (solo dígitos)
    IF LEN(@DNI) < 7 OR LEN(@DNI) > 8 
    BEGIN
        PRINT 'Error: El DNI debe contener 7 u 8 dígitos numéricos.';
    END
    -- Validación de presencia de "@" en los correos electrónicos
    ELSE IF CHARINDEX('@', @EmailPersonal) = 0
    BEGIN
        PRINT 'Error: El EmailPersonal debe contener el símbolo "@".';
    END
    ELSE IF CHARINDEX('@', @EmailEmpresa) = 0
    BEGIN
        PRINT 'Error: El EmailEmpresa debe contener el símbolo "@".';
    END
    -- Verifica si ya existe un empleado con el mismo DNI
    ELSE IF EXISTS (SELECT 1 FROM bbda.empleado WHERE CONVERT(NVARCHAR(500), DECRYPTBYKEY(DNI)) = @DNI)
    BEGIN
        PRINT 'El empleado con ese DNI ya existe';
    END
    ELSE
    BEGIN
        -- Inserta el empleado en la tabla si no existe uno con el mismo DNI
        INSERT INTO bbda.empleado (Nombre, Apellido, DNI, Direccion, EmailPersonal, EmailEmpresa, CUIL, Cargo, Sucursal, Turno)
        VALUES (@Nombre, @Apellido, ENCRYPTBYKEY(KEY_GUID('ClaveEncriptacionEmpleado'), CONVERT(NVARCHAR(500), @DNI)), 
                ENCRYPTBYKEY(KEY_GUID('ClaveEncriptacionEmpleado'), CONVERT(NVARCHAR(500), @Direccion)), 
                @EmailPersonal, @EmailEmpresa, 
                ENCRYPTBYKEY(KEY_GUID('ClaveEncriptacionEmpleado'), CONVERT(NVARCHAR(500),@CUIL)), 
                @Cargo, @Sucursal, @Turno);

        PRINT 'Empleado insertado exitosamente';
    END

    CLOSE SYMMETRIC KEY ClaveEncriptacionEmpleado;
END;


GO



CREATE OR ALTER PROCEDURE producto.insertarProducto
    @nombre VARCHAR(100),
    @precio DECIMAL(15, 2),
    @clasificacion VARCHAR(50)
AS
BEGIN
    -- Verifica la longitud de los parámetros
    IF LEN(@nombre) > 100
    BEGIN
        PRINT 'Error: El nombre del producto supera el límite de 100 caracteres.';
    END
    ELSE IF LEN(@clasificacion) > 50
    BEGIN
        PRINT 'Error: La clasificación del producto supera el límite de 50 caracteres.';
    END
	ELSE IF @precio < 0
    BEGIN
        PRINT 'Error: Precio menor a cero.';
    END
    ELSE IF EXISTS (SELECT 1 FROM bbda.producto WHERE nombre = @nombre)
    BEGIN
        -- Verifica si ya existe un producto con el mismo nombre
        PRINT 'El producto con ese nombre ya existe';
    END
    ELSE
    BEGIN
        -- Inserta el producto en la tabla si no existe uno con el mismo nombre
        INSERT INTO bbda.producto (nombre, precio, clasificacion)
        VALUES (@nombre, @precio, @clasificacion);

        PRINT 'Producto insertado exitosamente';
    END
END;


GO


CREATE OR ALTER PROCEDURE producto.insertarClasificacionProducto
    @LineaDeProducto VARCHAR(30),
    @Producto VARCHAR(100)
AS
BEGIN
    -- Verifica si ya existe un registro con el mismo Producto
    IF EXISTS (SELECT 1 FROM bbda.clasificacionProducto WHERE Producto = @Producto)
    BEGIN
        PRINT 'El producto ya existe en la clasificación';
    END
    ELSE
    BEGIN
        -- Inserta el registro en la tabla si no existe uno con el mismo Producto
        INSERT INTO bbda.clasificacionProducto (LineaDeProducto, Producto)
        VALUES (@LineaDeProducto, @Producto);

        PRINT 'Clasificación del producto insertada exitosamente';
    END
END;

GO



CREATE OR ALTER PROCEDURE dolar.insertarCotizacionDolar
@tipo varchar(50),
@valor decimal(10,2)
AS
BEGIN
	if exists(select 1 from bbda.cotizacionDolar c where c.tipo = @tipo)
		print('Cotizacion del dolar existente')
	else
	begin
		insert bbda.cotizacionDolar(tipo,valor) values (@tipo,@valor)
	end
END;

GO





-----------------------------------------------Modificar------------------------------------------------------


CREATE OR ALTER PROCEDURE producto.modificarProducto
    @nombre VARCHAR(100),
    @precio DECIMAL(15, 2),
    @clasificacion VARCHAR(50)
AS
BEGIN
    -- Verifica si existe un producto con el nombre especificado
    IF EXISTS (SELECT 1 FROM bbda.producto WHERE nombre = @nombre)
    BEGIN
        -- Si el producto existe, actualiza sus datos
        UPDATE bbda.producto
        SET precio = @precio,
            clasificacion = @clasificacion
        WHERE nombre = @nombre;

        PRINT 'Actualizacion de producto exitosa';
    END
    ELSE
    BEGIN
        -- Si el producto no existe, muestra un mensaje
        PRINT 'No existe un producto con ese nombre';
    END
END;

GO


CREATE OR ALTER PROCEDURE empleado.actualizarEmpleado
    @Legajo INT,
    @Nombre VARCHAR(50),
    @Apellido VARCHAR(50),
    @DNI VARCHAR(20),
    @Direccion VARCHAR(150),
    @EmailPersonal NVARCHAR(100),
    @EmailEmpresa NVARCHAR(100),
    @CUIL VARCHAR(20),
    @Cargo VARCHAR(50),
    @Sucursal VARCHAR(50),
    @Turno VARCHAR(50)
AS
BEGIN
	OPEN SYMMETRIC KEY ClaveEncriptacionEmpleado DECRYPTION BY PASSWORD = 'ventaaurorasa';
    -- Verifica si existe un empleado con el legajo especificado
    IF EXISTS (SELECT 1 FROM bbda.empleado WHERE Legajo = @Legajo)
    BEGIN
        -- Si el empleado existe, actualiza sus datos
        UPDATE bbda.empleado
        SET Nombre = @Nombre,
            Apellido = @Apellido,
            DNI = ENCRYPTBYKEY(KEY_GUID('ClaveEncriptacionEmpleado'), CONVERT(NVARCHAR(500), @DNI)),
            Direccion = ENCRYPTBYKEY(KEY_GUID('ClaveEncriptacionEmpleado'), CONVERT(NVARCHAR(500), @Direccion)),
            EmailPersonal = @EmailPersonal,
            EmailEmpresa = @EmailEmpresa,
            CUIL = ENCRYPTBYKEY(KEY_GUID('ClaveEncriptacionEmpleado'), CONVERT(NVARCHAR(500), @Cuil)),
            Cargo = @Cargo,
            Sucursal = @Sucursal,
            Turno = @Turno
        WHERE Legajo = @Legajo;

        PRINT 'Actualizacion de empleado exitosa';
    END
    ELSE
    BEGIN
        -- Si el empleado no existe, muestra un mensaje
        PRINT 'No existe un empleado con ese legajo';
    END
	CLOSE SYMMETRIC KEY ClaveEncriptacionEmpleado
END;


GO


CREATE OR ALTER PROCEDURE dolar.modificarCotizacionDolar
@tipo varchar(50),
@valor decimal(10,2)
AS
BEGIN
	if not exists(select 1 from bbda.cotizacionDolar c where c.tipo = @tipo)
		print('Tipo de dolar inexistente')
	else
	begin
		update bbda.cotizacionDolar set valor=@valor where tipo=@tipo
		print('Actualizacion de dolar exitosa')
	end
END

GO

CREATE OR ALTER PROCEDURE sucursal.actualizarSucursal
    @Ciudad VARCHAR(20),
    @Direccion VARCHAR(100),
    @Horario VARCHAR(50),
    @Telefono VARCHAR(20)
AS
BEGIN
    -- Verifica si existe una sucursal en la ciudad especificada
    IF EXISTS (SELECT 1 FROM bbda.sucursal WHERE ciudad = @Ciudad)
    BEGIN
        -- Si existe una sucursal en la ciudad, actualiza sus datos
        UPDATE bbda.sucursal
        SET direccion = @Direccion,
            horario = @Horario,
            telefono = @Telefono
        WHERE ciudad = @Ciudad;

        PRINT 'Actualizacion de sucursal exitosa';
    END
    ELSE
    BEGIN
        -- Si no existe una sucursal en esa ciudad, muestra un mensaje
        PRINT 'No existe una sucursal en esa ciudad';
    END
END;

GO

EXEC dolar.insertarCotizacionDolar @tipo= 'dolarOficial',@valor=1037 --Cambiar valor del dolár

GO


---------------------------------------Borrar-----------------------------------------------


-- SP para borrado logico tabla Clasificacion Producto
CREATE OR ALTER PROCEDURE borrar.borradoLogicoClasificacionProducto
    @Producto VARCHAR(100)
AS
BEGIN
    UPDATE bbda.clasificacionProducto
	SET FechaBaja = GETDATE()
    WHERE Producto = @Producto
END;
GO

-- SP para borrado logico tabla Producto
CREATE OR ALTER PROCEDURE borrar.borradoLogicoProducto
    @Nombre VARCHAR(100)
AS
BEGIN
    -- Verifica si existe un producto con el nombre especificado
    IF EXISTS (SELECT 1 FROM bbda.producto WHERE nombre = @Nombre)
    BEGIN
        -- Si el producto existe, realiza el borrado lógico (Inserta la Fecha de baja)
        UPDATE bbda.producto
		SET FechaBaja = GETDATE()
        WHERE nombre = @Nombre;

        PRINT 'Producto desactivado exitosamente';
    END
    ELSE
    BEGIN
        -- Si el producto no existe, muestra un mensaje
        PRINT 'No existe un producto con ese nombre';
    END
END;


GO


-- SP para borrado logico tabla Empleado
CREATE OR ALTER PROCEDURE borrar.borradoLogicoEmpleado
    @Legajo INT
AS
BEGIN
    UPDATE bbda.empleado
	SET FechaBaja = GETDATE()
    WHERE Legajo = @Legajo;
END;


GO


CREATE OR ALTER PROCEDURE borrar.borradoLogicoSucursal
    @Ciudad VARCHAR(20)
AS
BEGIN
    -- Verifica si existe una sucursal en la ciudad especificada
    IF EXISTS (SELECT 1 FROM bbda.sucursal WHERE ciudad = @Ciudad)
    BEGIN
        -- Si existe una sucursal en la ciudad, realiza el borrado lógico (Cambia la fecha de baja, de NULL a la fecha )
        UPDATE bbda.sucursal
		SET FechaBaja = GETDATE()
        WHERE ciudad = @Ciudad;

        PRINT 'Sucursal desactivada exitosamente';
    END
    ELSE
    BEGIN
        -- Si no existe una sucursal en esa ciudad, muestra un mensaje
        PRINT 'No existe una sucursal en esa ciudad';
    END
END;


GO




--Emitir nota de crédito(NC)
/*
El procedimiento emitirNotaCredito crea una nota de crédito para artículos concretos de una transacción de venta.
Recibe una serie de IDs de detalles de venta delimitados por comas, comprueba que todos los detalles correspondan a la misma venta
y que la factura vinculada a dicha venta se encuentre saldada. Posteriormente, para cada detalle proporcionado, obtiene el producto, la cantidad y el
importe de la tabla detalleVenta y los inserta en la tabla notaDeCredito. Por último, registra la nota de crédito con la
fecha actual de emisión y los datos pertinentes, facilitando la gestión de devoluciones parciales de una venta concreta.
(Bien visto)
*/

CREATE OR ALTER PROCEDURE nota.emitirNotaCredito
    @detalleIDs NVARCHAR(MAX)       -- Cadena de IDs de detalleVenta separados por comas
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que todos los IDs de detalle pertenezcan a la misma venta y que la factura esté pagada
    DECLARE @idVenta INT, @estadoFactura VARCHAR(20);
    SELECT @idVenta = idVenta
    FROM bbda.detalleVenta
    WHERE detalleID in (
        SELECT *
        FROM bbda.splitString(@detalleIDs, ',')
    );

    -- Validar que todos los detalles pertenezcan al mismo idVenta
    IF EXISTS (
        SELECT 1
        FROM bbda.detalleVenta
        WHERE detalleID IN (SELECT * FROM bbda.SplitString(@detalleIDs, ','))
        AND idVenta <> @idVenta
    )
    BEGIN
        print('Los detalles de venta no pertenecen a la misma venta.');
    END;

    -- Validar que la factura asociada esté en estado "pagada"
    SELECT @estadoFactura = estado
    FROM bbda.factura
    WHERE idVenta = @idVenta;

    IF @estadoFactura <> 'pagada'
    BEGIN
        print('La factura asociada no está en estado "pagada".');
    END;
	ELSE
	BEGIN

    -- 2. Obtener la fecha de emisión de la nota de crédito
    DECLARE @fechaEmision DATE;
    SET @fechaEmision = CONVERT(DATE, GETDATE());

    -- 3. Registrar los productos en la tabla notaDeCredito
    INSERT INTO bbda.notaDeCredito (idVenta, fechaEmision, producto, cantidad, monto)
    SELECT 
        dv.idVenta,
        @fechaEmision,
        p.nombre AS producto,
        dv.cantidad,
        dv.cantidad * dv.precio_unitario AS monto
    FROM 
        bbda.detalleVenta AS dv
    INNER JOIN 
        bbda.producto AS p ON dv.idProducto = p.idProducto
    WHERE 
        dv.detalleID IN (SELECT * FROM bbda.splitString(@detalleIDs, ','));

    -- Mensaje de éxito
    PRINT 'Nota de crédito emitida con éxito.';
	END
END;

GO



--Funcion para cortar cadenas(correcta)

    CREATE OR ALTER FUNCTION splitString (@string NVARCHAR(MAX), @delimiter CHAR(1))
    RETURNS @output TABLE (data NVARCHAR(MAX))
    AS
    BEGIN
        DECLARE @start INT, @end INT
        SET @start = 1
        SET @end = CHARINDEX(@delimiter, @string)

        WHILE @end > 0
        BEGIN
            INSERT INTO @output (data) VALUES(SUBSTRING(@string, @start, @end - @start))
            SET @start = @end + 1
            SET @end = CHARINDEX(@delimiter, @string, @start)
        END

        INSERT INTO @output (data) VALUES(SUBSTRING(@string, @start, LEN(@string) - @start + 1))
        RETURN
	END

GO


--SP registro de venta
/*Recibe una cadena 'producto1 x2,producto2 x3' */

/*Primero, se crea un registro de la venta con un monto inicial de cero en la tabla ventaRegistrada, 
y luego se procesan los productos vendidos, que se reciben como una cadena de texto que incluye nombres de productos y 
cantidades. Esta cadena se divide y se inserta en una tabla temporal, desde la cual se obtiene el precio y monto de cada
producto para luego almacenarlos en la tabla detalleVenta. El monto total de la venta se calcula y se actualiza en la tabla 
ventaRegistrada. Luego genera una factura para la venta, calculando el monto con y sin IVA, 
almacenando estos valores en la tabla factura. También se registra el pago correspondiente en la tabla pago y, finalmente, 
se actualiza el estado de la factura a "pagada" con la información del pago. */


CREATE OR ALTER PROCEDURE factura.registrarVentaConCodigos
    @ciudad VARCHAR(20),
    @tipoCliente VARCHAR(10),
    @genero VARCHAR(10),
    @empleado INT,
    @cadenaProductos NVARCHAR(MAX), -- Cadena con códigos de productos y cantidades
    @metodoPago VARCHAR(50), -- Método de pago para registrar el pago
    @puntoVenta VARCHAR(50)
AS
BEGIN
    BEGIN TRY
        -- Declarar variables necesarias
        DECLARE @fecha DATE;
        SET @fecha = CONVERT(DATE, GETDATE());
        DECLARE @hora TIME;
        SET @hora = CONVERT(TIME, GETDATE());
        DECLARE @idVenta INT, @montoTotal DECIMAL(10, 2) = 0;
        DECLARE @idFactura INT, @idPago INT;
        DECLARE @montoConIVA DECIMAL(10, 2), @IVA DECIMAL(10, 2) = 0.21;

        -- Dividir la cadena de productos en partes y cargarla en una tabla temporal
        DECLARE @productoDetalle TABLE (codigoProducto INT, cantidad INT);

        INSERT INTO @productoDetalle (codigoProducto, cantidad)
        SELECT 
            CAST(RTRIM(LTRIM(SUBSTRING(data, 1, CHARINDEX('x', data) - 2))) AS INT) AS codigoProducto,
            CAST(RTRIM(LTRIM(SUBSTRING(data, CHARINDEX('x', data) + 1, LEN(data)))) AS INT) AS cantidad
        FROM 
            bbda.splitString(@cadenaProductos, ',');

        -- Validar que todos los códigos de producto existen en la tabla `productos`
        IF EXISTS (
            SELECT 1
            FROM @productoDetalle AS pd
            LEFT JOIN bbda.producto AS p ON pd.codigoProducto = p.idProducto
            WHERE p.idProducto IS NULL
        )
        BEGIN
            THROW 50001, 'Error: Uno o más códigos de producto no existen.', 1;
        END;

        -- Crear la venta con monto inicial en cero
        INSERT INTO bbda.ventaRegistrada (ciudad, tipoCliente, genero, monto, fecha, hora, empleado)
        VALUES (@ciudad, @tipoCliente, @genero, 0, @fecha, @hora, @empleado);

        SET @idVenta = SCOPE_IDENTITY();

        -- Insertar en `detalleVenta` usando la tabla temporal
        INSERT INTO bbda.detalleVenta (idVenta, idProducto, categoria, cantidad, precio_unitario, monto)
        SELECT 
            @idVenta,
            p.idProducto,
            p.clasificacion AS categoria,
            pd.cantidad,
            p.precio AS precio_unitario,
            pd.cantidad * p.precio AS monto
        FROM 
            @productoDetalle AS pd
        INNER JOIN 
            bbda.producto AS p ON pd.codigoProducto = p.idProducto;

        -- Calcular el monto total de la venta
        SELECT @montoTotal = SUM(pd.cantidad * p.precio)
        FROM 
            @productoDetalle AS pd
        INNER JOIN 
            bbda.producto AS p ON pd.codigoProducto = p.idProducto;

        -- Actualizar el monto total en la tabla ventasRegistradas
        UPDATE bbda.ventaRegistrada
        SET monto = @montoTotal
        WHERE idVenta = @idVenta;

        -- Generar la factura para la venta
        DECLARE @tipoFactura VARCHAR(50) = 'A', @estadoFactura VARCHAR(20) = 'pendiente';
        SET @montoConIVA = @montoTotal * (1 + @IVA);

        INSERT INTO bbda.factura (idVenta, tipoFactura, tipoDeCliente, fecha, hora, medioDePago, empleado, 
                                   montoSinIVA, montoConIVA, IVA, estado, puntoDeVenta, cuit)
        VALUES (@idVenta, @tipoFactura, @tipoCliente, @fecha, @hora, 'Cash', @empleado, 
                @montoTotal, @montoConIVA, @montoTotal * @IVA, @estadoFactura, @puntoVenta, '20-22222222-3');

        SET @idFactura = SCOPE_IDENTITY();

        -- Registrar el pago
        INSERT INTO bbda.pago (idFactura, fecha, monto, metodoPago)
        VALUES (@idFactura, GETDATE(), @montoConIVA, @metodoPago);

        SET @idPago = SCOPE_IDENTITY();

        -- Actualizar el estado de la factura a "pagada"
        UPDATE bbda.factura
        SET estado = 'pagada'
        WHERE idFactura = @idFactura;
    END TRY
    BEGIN CATCH
        -- Manejo del error: re-lanzar el mensaje capturado
        THROW;
    END CATCH
END;