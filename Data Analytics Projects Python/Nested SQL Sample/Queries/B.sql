SELECT pe.nombre AS 'Nombre',
	   pe.apellido AS 'Apellido',
	   m.nombre AS 'Materia',
	   pr.estudiantes AS 'Cantidad de Estudiantes',
	   pr.promedio AS 'Promedio de Nota'
FROM (SELECT m.id_profesor AS id,
	   m.nombre AS materia,
	   m.id_materia AS id_materia,
	   AVG(c.nota) AS promedio,
	   COUNT(c.id_estudiante) AS estudiantes
FROM materias AS m
INNER JOIN  calificaciones AS c ON c.id_materia = m.id_materia
GROUP BY m.id_profesor, m.nombre, m.id_materia) AS pr
LEFT JOIN personas AS pe ON pe.id = pr.id
LEFT JOIN materias AS m ON m.id_materia = pr.id_materia
