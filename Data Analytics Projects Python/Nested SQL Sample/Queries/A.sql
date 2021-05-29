SELECT p.nombre AS 'Provincia',
	   pe.nombre AS 'Estudiante',
	   pe.apellido AS 'Apellido',
	   m.nombre AS 'Materia',
	   c.nota AS Nota
FROM provincias AS p
INNER JOIN personas AS pe ON p.id_provincia = pe.id_provincia
INNER JOIN calificaciones AS c ON pe.id = c.id_estudiante
INNER JOIN materias AS m ON m.id_materia = c.id_materia
ORDER BY p.nombre DESC