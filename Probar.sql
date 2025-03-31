DECLARE @idCampeonato INT = 4;

-- Ver equipos clasificados
SELECT 
    g.Grupo,
    p.Pais,
    tp.Posicion,
    tp.Puntos
FROM 
    Grupo g
CROSS APPLY
    dbo.fTablaPosiciones(g.Id) tp
JOIN
    Pais p ON tp.IdPais = p.Id
WHERE
    g.IdCampeonato = @idCampeonato
    AND tp.Posicion IN (1, 2)
ORDER BY
    g.Grupo,
    tp.Posicion;

-- Ejecutar procedimiento
EXEC sp_GenerarOctavosDeFinal @idCampeonato;

-- Ver resultados
SELECT
    p1.Pais AS Equipo1,
    p2.Pais AS Equipo2,
    e.Fecha,
    s.Estadio
FROM
    Encuentro e
JOIN Pais p1 ON e.idPais1 = p1.Id
JOIN Pais p2 ON e.idPais2 = p2.Id
JOIN Estadio s ON e.idEstadio = s.Id
WHERE e.idCampeonato = @idCampeonato
AND e.idFase = (SELECT Id FROM Fase WHERE Fase = 'Octavos de Final')
ORDER BY e.Fecha;