SELECT pe.nombre as Nombre,
	   pe.apellido as Apellido,
	   m.nombre as Materia,
	   c.nota as Nota,
	   CASE
			WHEN c.nota <= 60 THEN 'Reprobado'
			WHEN c.nota > 60 AND c.nota < 71 THEN 'Ampliación'
			WHEN c.nota >=  71 AND c.nota < 96 THEN 'Aprobado'
			WHEN c.nota >=  96  THEN 'Aprobado con Honores'
			ELSE ''
	  END AS Estado
FROM calificaciones as c
LEFT JOIN materias as m
ON m.id_materia = c.id_materia
LEFT JOIN personas as pe
ON pe.id = c.id_estudiante