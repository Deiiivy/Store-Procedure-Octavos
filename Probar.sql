EXEC sp_GenerarOctavosDeFinal @idCampeonato = 4;

-- Ver resultados
SELECT 
    p1.Pais AS Equipo1, 
    p2.Pais AS Equipo2,
    f.Fase
FROM 
    Encuentro e
JOIN Pais p1 ON e.idPais1 = p1.Id
JOIN Pais p2 ON e.idPais2 = p2.Id
JOIN Fase f ON e.idFase = f.Id
WHERE 
    e.idCampeonato = 4
    AND f.Fase = 'Octavos de Final';