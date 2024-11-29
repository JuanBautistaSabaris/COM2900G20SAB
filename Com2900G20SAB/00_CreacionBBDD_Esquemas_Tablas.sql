
-- Bases de Datos Aplicadas
-- Fecha de entrega: 29 de Noviembre de 2024
-- Grupo: 20
-- Comision: 2900
-- Alumno: Sabaris, Juan Bautista. 44870533


/*Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deberá entregar
un archivo .sql con el script completo de creación (debe funcionar si se lo ejecuta “tal cual” es
entregado). Incluya comentarios para indicar qué hace cada módulo de código.
Genere esquemas para organizar de forma lógica los componentes del sistema y aplique esto
en la creación de objetos. NO use el esquema “dbo”.
El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
de entrega, número de grupo, nombre de la materia, nombres y DNI de los alumnos.
Entregar todo en un zip cuyo nombre sea Grupo_XX.zip mediante la sección de prácticas de
MIEL. Solo uno de los miembros del grupo debe hacer la entrega.
Se requiere que los datos de los empleados se encuentren encriptados, dado que los mismos contienen información personal.*/



------------------------------------------ Base de datos -----------------------------------------------------

IF NOT EXISTS (
    SELECT name 
    FROM sys.databases 
    WHERE name = N'Com2900G20')
BEGIN
    CREATE DATABASE Com2900G20;
    PRINT 'Base de datos Com2900G20 creada.';
END
ELSE
BEGIN
    PRINT 'La base de datos Com2900G20 ya existe';
END;

GO

USE Com2900G20;
GO


-- Nos aseguramos que ningún otro proceso esté utilizando la base de datos mientras se cambia la intercalación y cambiamos la intercalación (collation) de la base de datos a 'Latin1_General_CS_AS' (sensible a mayúsculas y acentos)--
ALTER DATABASE Com2900G20 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

ALTER DATABASE Com2900G20
COLLATE Latin1_General_CS_AS;
GO
ALTER DATABASE Com2900G20 SET MULTI_USER;
GO


----------------------------------------- Esquemas -----------------------------------------------------


--VERIFICA SI EXISTE EL ESQUEMA BBDA, Y SINO LO CREA
IF NOT EXISTS (
    SELECT name 
    FROM sys.schemas 
    WHERE name = N'bbda')
BEGIN
    EXEC('CREATE SCHEMA bbda');
    PRINT 'Esquema bbda creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El esquema bbda ya existe.';
END;

GO


--VERIFICA SI EXISTE EL ESQUEMA SUCURSAL, Y SINO LO CREA
IF NOT EXISTS (
    SELECT name 
    FROM sys.schemas 
    WHERE name = N'sucursal')
BEGIN
    EXEC('CREATE SCHEMA sucursal');
    PRINT 'Esquema sucursal creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El esquema sucursal ya existe.';
END;

GO


--VERIFICA SI EXISTE EL ESQUEMA EMPLEADO, Y SINO LO CREA
IF NOT EXISTS (
    SELECT name 
    FROM sys.schemas 
    WHERE name = N'empleado')
BEGIN
    EXEC('CREATE SCHEMA empleado');
    PRINT 'Esquema empleado creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El esquema empleado ya existe.';
END;

GO


--VERIFICA SI EXISTE EL ESQUEMA PRODUCTO, Y SINO LO CREA
IF NOT EXISTS (
    SELECT name 
    FROM sys.schemas 
    WHERE name = N'producto')
BEGIN
    EXEC('CREATE SCHEMA producto');
    PRINT 'Esquema producto creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El esquema producto ya existe.';
END;

GO


--VERIFICA SI EXISTE EL ESQUEMA DOLAR, Y SINO LO CREA
IF NOT EXISTS (
    SELECT name 
    FROM sys.schemas 
    WHERE name = N'dolar')
BEGIN
    EXEC('CREATE SCHEMA dolar');
    PRINT 'Esquema dolar creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El esquema dolar ya existe.';
END;

GO


--VERIFICA SI EXISTE EL ESQUEMA FACTURA, Y SINO LO CREA
IF NOT EXISTS (
    SELECT name 
    FROM sys.schemas 
    WHERE name = N'factura')
BEGIN
    EXEC('CREATE SCHEMA factura');
    PRINT 'Esquema factura creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El esquema factura ya existe.';
END;

GO


--VERIFICA SI EXISTE EL ESQUEMA NOTA, Y SINO LO CREA
IF NOT EXISTS (
    SELECT name 
    FROM sys.schemas 
    WHERE name = N'nota')
BEGIN
    EXEC('CREATE SCHEMA nota');
    PRINT 'Esquema nota creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El esquema nota ya existe.';
END;

GO


--VERIFICA SI EXISTE EL ESQUEMA BORRAR, Y SINO LO CREA
IF NOT EXISTS (
    SELECT name 
    FROM sys.schemas 
    WHERE name = N'borrar')
BEGIN
    EXEC('CREATE SCHEMA borrar');
    PRINT 'Esquema borrar creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El esquema borrar ya existe.';
END;

GO


--VERIFICA SI EXISTE EL ESQUEMA IMPORTAR, Y SINO LO CREA
IF NOT EXISTS (
    SELECT name 
    FROM sys.schemas 
    WHERE name = N'importar')
BEGIN
    EXEC('CREATE SCHEMA importar');
    PRINT 'Esquema importar creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El esquema importar ya existe.';
END;

GO


--VERIFICA SI EXISTE EL ESQUEMA REPORTE, Y SINO LO CREA
IF NOT EXISTS (
    SELECT name 
    FROM sys.schemas 
    WHERE name = N'reporte')
BEGIN
    EXEC('CREATE SCHEMA reporte');
    PRINT 'Esquema reporte creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El esquema reporte ya existe.';
END;

GO


-----------------------------Clave para cifrar a los empleados-----------------------------


IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'ClaveEncriptacionEmpleado')
BEGIN
    CREATE SYMMETRIC KEY ClaveEncriptacionEmpleado
    WITH ALGORITHM = AES_128
    ENCRYPTION BY PASSWORD = 'ventaaurorasa';
END;

GO

---------------------------------Creación de tablas----------------------------------------


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'bbda.sucursal') AND type in (N'U'))
BEGIN
CREATE TABLE bbda.sucursal (
    idSucursal int identity (1,1) primary key,
	ciudad varchar(20) unique,
	direccion varchar(100),
	horario varchar(50),
	telefono varchar(20),
    FechaBaja DATE DEFAULT NULL                   -- Campo para borrado lógico
)
END;

GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'bbda.empleado') AND type in (N'U'))
BEGIN
    CREATE TABLE bbda.empleado (
        Legajo INT identity(257019,1) PRIMARY KEY,     --Legajo de empleado existente>=257020              
        Nombre VARCHAR(50),                      
        Apellido VARCHAR(50),                     
        DNI VARBINARY(500) NOT NULL,             -- DNI del empleado, almacenado encriptado
        Direccion VARBINARY(500),                -- Dirección del empleado, almacenada encriptada
        EmailPersonal VARCHAR(100),              
        EmailEmpresa VARCHAR(100),             
        CUIL VARBINARY(500) NOT NULL,            -- CUIL del empleado, almacenado encriptado
        Cargo VARCHAR(50) CHECK (Cargo IN ('Cajero', 'Supervisor', 'Gerente de sucursal')), 
        Sucursal VARCHAR(20) foreign key references bbda.sucursal(ciudad),                    
        Turno VARCHAR(50) CHECK (Turno IN ('TM', 'TT', 'JC')), 
        FechaBaja DATE DEFAULT NULL              -- Campo para borrado lógico
)
END;

GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'bbda.clasificacionProducto') AND type in (N'U'))
BEGIN
    CREATE TABLE bbda.clasificacionProducto (
		IdClasificacion int identity(1,1) primary key,
        LineaDeProducto VARCHAR(30) CHECK (LineaDeProducto IN ('Electronica','Almacen', 'Perfumeria', 'Hogar', 'Frescos', 'Bazar', 'Limpieza', 'Otros', 'Congelados', 'Bebidas', 'Mascota', 'Comida','Importado')), 
		Producto VARCHAR(100) unique,
        FechaBaja DATE DEFAULT NULL                -- Campo para borrado lógico
)
END;


GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'bbda.producto') AND type in (N'U'))
BEGIN
CREATE TABLE bbda.producto (
    idProducto int identity(1,1) primary key,
	nombre varchar(100) unique,
	precio decimal(15,2),
	clasificacion varchar(100),
    FechaBaja DATE DEFAULT NULL                    -- Campo para borrado lógico
	CONSTRAINT FK_clasificacionProducto FOREIGN KEY (clasificacion) 
    REFERENCES bbda.clasificacionProducto(Producto)
)
END;


GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'bbda.cotizacionDolar') AND type in (N'U'))
BEGIN
CREATE TABLE bbda.cotizacionDolar (
	idCotizacion int identity(1,1) primary key,
    tipo varchar(50),
	valor decimal(10,2)
)
END;


GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'bbda.ventaRegistrada') AND type in (N'U'))
BEGIN
CREATE TABLE bbda.ventaRegistrada (
	idVenta int identity(1,1) primary key,
	ciudad varchar(20),
	tipoCliente varchar(10),
	genero varchar(10),
	monto decimal(10,2),
	fecha date,
	hora time,
	empleado int
)
END;


GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'bbda.detalleVenta') AND type in (N'U'))
BEGIN
CREATE TABLE bbda.detalleVenta (
    detalleID int identity(1,1) primary key,
	idVenta int foreign key references bbda.ventaRegistrada(idVenta),
	idProducto int foreign key references bbda.producto(idProducto),
	categoria varchar(100),
	cantidad int,
	precio_unitario decimal (10,2),
	monto decimal(10,2)
)
END;


GO



IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'bbda.factura') AND type in (N'U'))
BEGIN
CREATE TABLE bbda.factura (
    idFactura INT IDENTITY (1,1) PRIMARY KEY,
    idVenta int foreign key references bbda.ventaRegistrada(idVenta), 
    tipoFactura VARCHAR(50) CHECK (tipoFactura IN ('A', 'B', 'C')),
    tipoDeCliente VARCHAR(50) check (tipoDeCliente in ('Normal','Member')),
    fecha DATE,
    hora TIME,
    medioDePago VARCHAR(50) CHECK (medioDePago in ('Credit card','Cash','Ewallet')),
    empleado int foreign key references bbda.empleado(Legajo),
    montoSinIVA DECIMAL(10, 2),
	montoConIVA DECIMAL(10,2),
	IVA DECIMAL(10,2),
    puntoDeVenta VARCHAR(50),
	cuit varchar(20),
	estado VARCHAR(20) CHECK (estado in ('pagada','pendiente','anulada','vencida','reembolsada'))
)
END;


GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'bbda.pago') AND type in (N'U'))
BEGIN
	CREATE TABLE bbda.pago (
    idPago INT IDENTITY(1,1) PRIMARY KEY,    -- Identificador único del pago
    idFactura INT,                           -- Identificador de la factura asociada (FK)
    fecha DATETIME NOT NULL,                
    monto DECIMAL(10, 2) NOT NULL,           
    metodoPago VARCHAR(50) NOT NULL,  
	CONSTRAINT fk_factura FOREIGN KEY (idFactura) REFERENCES bbda.factura(idFactura) 
)
END


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'bbda.notaDeCredito') AND type in (N'U'))
BEGIN
CREATE TABLE bbda.notaDeCredito (
    notaID int identity(1,1) primary key,
	idVenta int foreign key references bbda.ventaRegistrada(idVenta),
	fechaEmision date,
	producto varchar(100),
	cantidad int,
	monto decimal(10,2)
)
END

