

SELECT y.estudiante as Estudiante,
	   y.apellido as Apellido,
       m.nombre as Materia,
	   y.nota as Nota,
	   pr.promedio as 'Promedio de materia'
FROM materias as m
RIGHT JOIN (SELECT c.id_estudiante as id_estudiante,
				   pe.nombre as estudiante,
				   pe.apellido as apellido,
				   c.id_materia as id_materia,
				   c.nota as nota
			FROM calificaciones as c
			LEFT JOIN personas as pe
			ON pe.id = c.id_estudiante) as y
ON y.id_materia = m.id_materia
LEFT JOIN (SELECT c.id_materia as id_materia,
			      AVG(c.nota) as promedio
		   FROM calificaciones as c
		   GROUP BY c.id_materia) as pr
ON pr.id_materia = y.id_materia
WHERE y.nota >= pr.promedio



