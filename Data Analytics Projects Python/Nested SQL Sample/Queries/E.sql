SELECT p.nombre as Provincia,
	   pe.nombre as Profesor,
	   m.nombre as Materia,
	   t.promedio as Promedio
FROM materias as m
LEFT JOIN personas as pe 
ON pe.id = m.id_profesor
LEFT JOIN (SELECT c.id_materia as id_materia,
				  AVG(c.nota) as promedio
		   FROM calificaciones as c
		   GROUP BY c.id_materia) as t
ON t.id_materia = m.id_materia
LEFT JOIN provincias as p
ON p.id_provincia = pe.id_provincia
