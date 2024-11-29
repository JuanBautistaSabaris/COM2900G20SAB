
-- Bases de Datos Aplicadas
-- Fecha de entrega: 29 de Noviembre de 2024
-- Grupo: 20
-- Comision: 2900
-- Alumno: Sabaris, Juan Bautista. 44870533

/*Siempre que se entreguen módulos de código fuente deben acompañarse de scripts de testing. 
Los juegos de prueba deben entregarse en un archivo separado al script del fuente, aunque se incluya en el mismo proyecto. 
Todo módulo ejecutable (SP, función), debe ser utilizado en al menos una prueba. */


USE Com2900G20

GO

--PARA VER LOS CAMPOS DESCIFRADOS (primero ejecutar el procedure para importar los archivos)

OPEN SYMMETRIC KEY ClaveEncriptacionEmpleado DECRYPTION BY PASSWORD = 'ventaaurorasa';
SELECT 
    Legajo, 
    Nombre, 
    Apellido, 
    CONVERT(NVARCHAR(500), DECRYPTBYKEY(DNI)) AS DNI,  
    CONVERT(NVARCHAR(500), DECRYPTBYKEY(Direccion)) AS Direccion ,  
    EmailPersonal, 
    EmailEmpresa,  
    CONVERT(NVARCHAR(500), DECRYPTBYKEY(CUIL)) AS CUIL,  
    Cargo, 
    Sucursal, 
    Turno
FROM bbda.empleado;

-- Cerrar la clave simétrica
CLOSE SYMMETRIC KEY ClaveEncriptacionEmpleado;


SELECT*FROM bbda.empleado


------------------------------------------------Tests importación archivos-------------------------------------------------------

SELECT*FROM bbda.clasificacionProducto
EXEC importar.importarClasificacionProducto @ruta='C:\Users\User\Desktop\TP_BASES_APLICADA\TP_integrador_Archivos';


SELECT*FROM bbda.producto
EXEC importar.importarProductosImportados @ruta = 'C:\Users\User\Desktop\TP_BASES_APLICADA\TP_integrador_Archivos\Productos'
EXEC importar.importarCatalogo @ruta='C:\Users\User\Desktop\TP_BASES_APLICADA\TP_integrador_Archivos\Productos';
EXEC importar.importarElectronicAccessories @ruta='C:\Users\User\Desktop\TP_BASES_APLICADA\TP_integrador_Archivos\Productos';
--
SELECT*FROM bbda.sucursal
EXEC importar.importarSucursal @ruta= 'C:\Users\User\Desktop\TP_BASES_APLICADA\TP_integrador_Archivos';

SELECT*FROM bbda.empleado
EXEC importar.importarEmpleado @ruta='C:\Users\User\Desktop\TP_BASES_APLICADA\TP_integrador_Archivos';

SELECT*FROM bbda.ventaRegistrada
EXEC importar.importarVentasRegistradas @ruta='C:\Users\User\Desktop\TP_BASES_APLICADA\TP_integrador_Archivos';



----------------------------------------Tests Reportes--------------------------------------------------------

EXEC reporte.facturacionMensualPorDiaDeSemana @mes = 1, @anio = 2019;

EXEC reporte.facturacionTrimestralPorTurnosPorMes @turno = 'Mañana', @trimestre = 1, @anio = 2019;

EXEC reporte.productosVendidosPorRangoFechas @fecha_inicio = '2019-01-01', @fecha_fin = '2019-03-14';

EXEC reporte.productosVendidosPorSucursalPorRangoFechas @fecha_inicio = '2019-01-01', @fecha_fin = '2024-11-29';

EXEC reporte.productosMasVendidosPorSemana @mes = 1, @anio = 2019;

EXEC reporte.productosMenosVendidosPorMes @mes = 1, @anio = 2019;

EXEC reporte.acumuladoVentasPorFechaYSucursal @fecha = '01-01-2019', @sucursal = 'Ramos Mejia';



----------------------------------------------Tests Insertar------------------------------------------------

--Producto Insertado correctamente
EXEC producto.insertarProducto @nombre = 'zanahoria', @precio = 700, @clasificacion = 'verdura' ;

--Producto no insertado
EXEC producto.insertarProducto @nombre = 'zapallito', @precio = -100, @clasificacion = 'verdura' ;

SELECT*FROM bbda.producto


--Empleado Insertado correctamente
EXEC empleado.insertarEmpleado @Nombre= 'ignacio', @Apellido = 'Torres' , @DNI ='43564789', 
	@Direccion= 'avenida rivadavia', @EmailPersonal='Nacho@gmail.com',@EmailEmpresa='Ula@unlam.com',@CUIL='00-44960383-0',@Cargo='Cajero',
	@Sucursal= 'San Justo',@Turno='TM';

--Empleado no insertado
EXEC empleado.insertarEmpleado  @Nombre= 'ignacio', @Apellido = 'Torres' , @DNI ='234869402192', 
	@Direccion= 'avenida rivadavia', @EmailPersonal='Nacho@gmail.com',@EmailEmpresa='Ula@unlam.com',@CUIL='00-44960383-0',@Cargo='Cajero',
	@Sucursal= 'San Justo',@Turno='TM';

SELECT*FROM bbda.empleado



--Clasificacion de producto Insertada correctamente
EXEC producto.insertarClasificacionProducto @LineaDeProducto= 'Almacen',@Producto= 'agua_gaseosa';

SELECT*FROM bbda.clasificacionProducto


--Sucursal Insertada correctamente
EXEC sucursal.insertarSucursal @Ciudad= 'Morón',@Direccion='av rivadavia',@Horario='9 a 13', @Telefono='2236710901';

SELECT*FROM bbda.sucursal



-------------------------------------------------Tests Modificacion-----------------------------------------------------------------

--Producto modifiicado correctamente
EXEC producto.modificarProducto @nombre='Acelgas',@precio=2000,@clasificacion='verdura';

--Producto no modificado
EXEC producto.modificarProducto @nombre='casa',@precio=2000,@clasificacion='verdura';

SELECT*FROM bbda.producto


--Empleado modifiicado correctamente
EXEC empleado.actualizarEmpleado
    @Legajo = 257030,@Nombre = 'Pablo', @Apellido = 'Fernández',@DNI = '123456789',@Direccion = 'Avenidad Mayo 230',@EmailPersonal = 'pablo.fernandez@gmail.com',
    @EmailEmpresa = 'juan.perez@empresa.com',@CUIL = '20-12345678-9',@Cargo = 'Cajero', @Sucursal = 'San Justo',@Turno = 'TM';

--Empleado no modificado
EXEC empleado.actualizarEmpleado
    @Legajo = 57030,@Nombre = 'Pablo', @Apellido = 'Fernández',@DNI = '123456789',@Direccion = 'Avenidad Mayo 230',@EmailPersonal = 'pablo.fernandez@gmail.com',
    @EmailEmpresa = 'juan.perez@empresa.com',@CUIL = '20-12345678-9',@Cargo = 'Cajero', @Sucursal = 'San Justo',@Turno = 'TM';

SELECT*FROM bbda.empleado


--Sucursal modifiicada correctamente
EXEC sucursal.actualizarSucursal @Ciudad = 'San Justo',@Direccion = 'Av. Santa 3780',@Horario = 'Lunes a Viernes 8:00 - 17:00',
    @Telefono = '011-9876-5432';

--Sucursal no modificada
EXEC sucursal.actualizarSucursal @Ciudad = 'Merlo',@Direccion = 'Av. Santa 3780',@Horario = 'Lunes a Viernes 8:00 - 17:00',
    @Telefono = '011-9876-5432';

SELECT*FROM bbda.sucursal

------------------------------------------------------Tests Borrado Logico------------------------------------------------------------

--Empleado borrado correctamente
EXEC borrar.borradoLogicoEmpleado @Legajo= 257020;

--No logro borrar Empleado
EXEC borrar.borradoLogicoEmpleado @Legajo= 256930;

SELECT*FROM bbda.empleado


--Clasificacion borrada correctamente
EXEC borrar.borradoLogicoClasificacionProducto @Producto='conejo_y_cordero';

--No logro borrar Clasificacion
EXEC borrar.borradoLogicoClasificacionProducto @Producto='casa';

SELECT*FROM bbda.clasificacionProducto


--Producto borrado correctamente
EXEC borrar.borradoLogicoProducto @Nombre= 'Manzana golden';

--No logro borrar producto
EXEC borrar.borradoLogicoProducto @Nombre= 'casa';

SELECT*FROM bbda.producto


--Sucursal borrada correctamente
EXEC  borrar.borradoLogicoSucursal @Ciudad = 'San Justo';

--No logro borrar sucursal
EXEC  borrar.borradoLogicoSucursal @Ciudad = 'Merlo';

SELECT*FROM bbda.sucursal


---------------------------------------------------------------Tests Emitir NC y Registro de venta----------------------------------------------------


EXEC factura.registrarVentaConCodigos
    @ciudad = 'San Justo',
    @tipoCliente = 'Normal',
    @genero = 'Male',
    @empleado = 257020,
    @cadenaProductos = '2272 x2,1272 x1',
	@metodoPago = 'Cash',
	@puntoVenta = 'caja 1'

	SELECT*FROM bbda.ventaRegistrada
	SELECT*FROM bbda.detalleVenta
	SELECT*FROM bbda.factura
	SELECT*FROM bbda.pago

	TRUNCATE TABLE bbda.detalleVenta
	SELECT*FROM bbda.producto

	SELECT*FROM bbda.detalleVenta d join bbda.producto p on d.idProducto=p.idProducto



--El rol "cajero" no tiene permiso
EXECUTE AS LOGIN= 'juan'
EXEC nota.emitirNotaCredito @detalleIDs =  '7'

REVERT

--El rol "supervisor" si
EXECUTE AS LOGIN= 'cosmefulanito'
EXEC nota.emitirNotaCredito @detalleIDs =  '7'
SELECT*FROM bbda.detalleVenta

REVERT

SELECT*FROM bbda.notaDeCredito