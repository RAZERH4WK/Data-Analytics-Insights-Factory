SELECT p.nombre AS 'Provincia',
	   m.nombre AS 'Materia',
	   MAX(c.nota) AS 'Mejor nota'
FROM calificaciones as c
LEFT JOIN materias AS m ON m.id_materia = c.id_materia
LEFT JOIN personas AS pe ON pe.id = c.id_estudiante
LEFT JOIN provincias AS p ON p.id_provincia = pe.id_provincia
GROUP BY p.nombre, m.nombre