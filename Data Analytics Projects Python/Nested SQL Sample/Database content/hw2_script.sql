USE [hw2]
GO

CREATE TABLE [dbo].[personas] (
	id int IDENTITY(1,1) PRIMARY KEY,
	nombre varchar(50) NOT NULL,
	apellido varchar(50) NOT NULL,
	genero char(1),
	id_provincia int
);
GO

CREATE TABLE [dbo].[provincias] (
	id_provincia int IDENTITY(1,1) PRIMARY KEY,
	nombre varchar(50) NOT NULL
);
GO


CREATE TABLE [dbo].[materias] (
	id_materia int IDENTITY(1,1) PRIMARY KEY,
	nombre varchar(50) NOT NULL,
	id_profesor int
);
GO

CREATE TABLE [dbo].[calificaciones] (
	id_estudiante int,
	id_materia int,
	nota float NOT NULL,
	PRIMARY KEY (id_estudiante,id_materia)
);
GO



ALTER TABLE [dbo].[personas]
ADD FOREIGN KEY (id_provincia) REFERENCES [dbo].[provincias] (id_provincia);
GO

ALTER TABLE [dbo].[materias]
ADD FOREIGN KEY (id_profesor) REFERENCES [dbo].[personas] (id);
GO

ALTER TABLE [dbo].[calificaciones]
ADD FOREIGN KEY (id_materia) REFERENCES [dbo].[materias] (id_materia);
GO


ALTER TABLE [dbo].[calificaciones]
ADD FOREIGN KEY (id_estudiante) REFERENCES [dbo].[personas] (id);
GO