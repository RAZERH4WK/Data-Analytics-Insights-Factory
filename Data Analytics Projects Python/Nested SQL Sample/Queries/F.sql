SELECT * 
FROM (SELECT p.nombre as Provincia,
	         z.genero as Genero,
	         z.materia as Materia,
	         AVG(z.nota) as 'Nota promedio'
      FROM provincias as p
		RIGHT JOIN (SELECT pe.genero as genero,
						   pe.id_provincia as id_provincia,
						   x.id_estudiante as id_estudiante,
						   x.id_materia as id_materia,
						   x.nota as nota,
						   x.materia as materia
					FROM personas as pe
					RIGHT JOIN (SELECT c.id_estudiante as id_estudiante,
									   c.id_materia as id_materia,
									   c.nota as nota,
									   m.nombre as materia
								FROM calificaciones as c
								LEFT JOIN materias as m
								ON m.id_materia = c.id_materia) as x
					ON x.id_estudiante = pe.id) as z
		ON z.id_provincia = p.id_provincia
		GROUP BY p.nombre, z.genero, z.materia) as y
WHERE y.Materia = 'Blender visuals' AND y.Provincia = 'Praga'
