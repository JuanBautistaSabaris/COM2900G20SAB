
-- Bases de Datos Aplicadas
-- Fecha de entrega: 29 de Noviembre de 2024
-- Grupo: 20
-- Comision: 2900
-- Alumno: Sabaris, Juan Bautista. 44870533

/*Cuando un cliente reclama la devolución de un producto se genera una nota de crédito por el valor del producto o un producto del mismo tipo.
En el caso de que el cliente solicite la nota de crédito, solo los Supervisores tienen el permiso para generarla.
Tener en cuenta que la nota de crédito debe estar asociada a una Factura con estado pagada.
Asigne los roles correspondientes para poder cumplir con este requisito.*/


USE master
go
-------------------------------------LOGINS----------------------------------------


-- Crear login 'cosmefulanito' si no existe
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'cosmefulanito')
BEGIN
    CREATE LOGIN cosmefulanito WITH PASSWORD = 'soy', CHECK_POLICY = ON;
    PRINT 'Login "cosmefulanito" creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El login "cosmefulanito" ya existe.';
END

-- Crear login 'bautista' si no existe
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'bautista')
BEGIN
    CREATE LOGIN bautista WITH PASSWORD = 'sab', CHECK_POLICY = ON;
    PRINT 'Login "bautista" creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El login "bautista" ya existe.';
END

-- Crear login 'juan' si no existe
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'juan')
BEGIN
    CREATE LOGIN juan WITH PASSWORD = 'juan', CHECK_POLICY = ON;
    PRINT 'Login "juan" creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El login "juan" ya existe.';
END


USE Com2900G20
GO
---------------------------------Usuarios--------------------------------------------

-- Crear usuario 'cosmefulanito' si no existe
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'cosmefulanito')
BEGIN
    CREATE USER cosmefulanito FOR LOGIN cosmefulanito;
    PRINT 'Usuario "cosmefulanito" creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El usuario "cosmefulanito" ya existe.';
END

-- Crear usuario 'bautista' si no existe
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bautista')
BEGIN
    CREATE USER bautista FOR LOGIN bautista;
    PRINT 'Usuario "bautista" creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El usuario "bautista" ya existe.';
END

-- Crear usuario 'juan' si no existe
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'juan')
BEGIN
    CREATE USER juan FOR LOGIN juan;
    PRINT 'Usuario "juan" creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El usuario "juan" ya existe.';
END

GO

--------------------------------------Roles---------------------------------------

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE type = 'R' AND name = 'supervisor')
BEGIN
    CREATE ROLE supervisor;
    PRINT 'Rol "supervisor" creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El rol "supervisor" ya existe.';
END

GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE type = 'R' AND name = 'repositor')
BEGIN
    CREATE ROLE repositor;
    PRINT 'Rol "repositor" creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El rol "repositor" ya existe.';
END

GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE type = 'R' AND name = 'cajero')
BEGIN
    CREATE ROLE cajero;
    PRINT 'Rol "cajero" creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El rol "cajero" ya existe.';
END

GO

ALTER ROLE supervisor ADD MEMBER cosmefulanito;
ALTER ROLE repositor ADD MEMBER bautista;
ALTER ROLE cajero ADD MEMBER juan;

GO

-- Otorgar permisos a los para ejecutar procedimientos almacenados en los esquemas especificados
GRANT EXECUTE ON SCHEMA::bbda TO supervisor
GRANT EXECUTE ON SCHEMA::importar TO supervisor
GRANT EXECUTE ON SCHEMA::borrar TO supervisor
GRANT EXECUTE ON SCHEMA::factura to supervisor
GRANT EXECUTE ON SCHEMA::dolar to supervisor
GRANT EXECUTE ON SCHEMA::empleado to supervisor
GRANT EXECUTE ON SCHEMA::producto to supervisor
GRANT EXECUTE ON SCHEMA::nota TO supervisor

GO

DENY EXECUTE ON SCHEMA::bbda TO cajero
DENY EXECUTE ON SCHEMA::importar TO cajero
DENY EXECUTE ON SCHEMA::borrar TO cajero
DENY EXECUTE ON SCHEMA::dolar to cajero
DENY EXECUTE ON SCHEMA::empleado to cajero
DENY EXECUTE ON SCHEMA::producto to cajero
DENY EXECUTE ON SCHEMA::nota TO cajero
GRANT EXECUTE ON SCHEMA::factura to cajero

GO

DENY EXECUTE ON SCHEMA::bbda TO repositor
DENY EXECUTE ON SCHEMA::importar TO repositor
DENY EXECUTE ON SCHEMA::borrar TO repositor
DENY EXECUTE ON SCHEMA::dolar to repositor
DENY EXECUTE ON SCHEMA::empleado to repositor
DENY EXECUTE ON SCHEMA::factura to repositor
DENY EXECUTE ON SCHEMA::nota TO repositor
GRANT EXECUTE ON SCHEMA::producto to repositor