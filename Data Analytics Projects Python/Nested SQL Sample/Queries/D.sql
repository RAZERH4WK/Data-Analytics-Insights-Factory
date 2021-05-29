SELECT p.nombre as Provincia, -- Provincia de Estudiante
	   r.profesor as Profesor,
	   r.materia as Materia,
	   r.nota as 'Mejor Nota',
	   r.estudiante as Estudiante
FROM provincias as p
RIGHT JOIN (SELECT y.id_estudiante as id_estudiante,
				   y.id_materia as id_materia,
				   y.materia as materia,
				   y.id_profesor as id_profesor,
				   y.nota as nota,
				   y.estudiante as estudiante,
				   pe.nombre as profesor,
				   y.id_provincia as id_provincia
			FROM personas as pe
			RIGHT JOIN (SELECT z.id_estudiante as id_estudiante,
							   z.id_materia as id_materia,
							   z.materia as materia,
							   z.id_profesor as id_profesor,
							   z.nota as nota,
							   pe.nombre as estudiante,
							   pe.id_provincia as id_provincia
						FROM personas as pe
						RIGHT JOIN (SELECT c.id_estudiante as id_estudiante,
											n.id_materia as id_materia,
											n.materia as materia,
											n.profesor as id_profesor,
											n.nota as nota
									FROM calificaciones as c
									RIGHT JOIN (SELECT m.id_materia as id_materia,
													   m.nombre as materia,
													   m.id_profesor profesor,
													   topm.nota as nota
												FROM materias as m
												RIGHT JOIN (SELECT c.id_materia as id_materia,
																	max(c.nota) as nota
															FROM calificaciones as c
															GROUP BY c.id_materia) as topm
												ON topm.id_materia = m.id_materia) as n
									ON (n.id_materia = c.id_materia AND n.nota = c.nota) ) as z
						ON z.id_estudiante = pe.id) as y
			ON y.id_profesor = pe.id) as r
ON p.id_provincia = r.id_provincia