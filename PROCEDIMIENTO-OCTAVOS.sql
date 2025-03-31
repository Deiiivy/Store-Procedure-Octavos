CREATE PROCEDURE sp_GenerarOctavosDeFinal
    @idCampeonato INT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Fase WHERE Fase = 'Octavos de Final')
    BEGIN
        RAISERROR('No existe la fase "Octavos de Final"', 16, 1);
        RETURN;
    END
    
    -- Obtener cualquier estadio disponible 
    DECLARE @idEstadio INT = (SELECT TOP 1 Id FROM Estadio ORDER BY Id);
    
    -- Si no hay estadios, usar uno por defecto (1) o el mínimo disponible
    IF @idEstadio IS NULL
        SET @idEstadio = 1;
    
    DELETE FROM Encuentro 
    WHERE idCampeonato = @idCampeonato 
    AND idFase = (SELECT Id FROM Fase WHERE Fase = 'Octavos de Final');
    
    WITH Clasificados AS (
        SELECT 
            g.Grupo,
            tp.IdPais,
            tp.Posicion,
            tp.Puntos,
            tp.DifGoles,
            ROW_NUMBER() OVER (PARTITION BY g.Grupo ORDER BY tp.Puntos DESC, tp.DifGoles DESC) AS RankGrupo
        FROM 
            Grupo g
        CROSS APPLY
            dbo.fTablaPosiciones(g.Id) tp
        WHERE 
            g.IdCampeonato = @idCampeonato
    ),
    Cruces AS (
        SELECT 
            c1.IdPais AS IdPais1,
            c2.IdPais AS IdPais2,
            DATEADD(DAY, ASCII(c1.Grupo) - 65, GETDATE()) AS Fecha,
            @idEstadio AS idEstadio,
            (SELECT Id FROM Fase WHERE Fase = 'Octavos de Final') AS idFase,
            @idCampeonato AS idCampeonato
        FROM 
            Clasificados c1
        JOIN
            Clasificados c2 ON 
            (
                ASCII(c1.Grupo) + 1 = ASCII(c2.Grupo) -- Grupos consecutivos (A-B, C-D, etc.)
                AND c1.RankGrupo = 1 
                AND c2.RankGrupo = 2
            )
        WHERE
            c1.Posicion IN (1, 2) 
            AND c2.Posicion IN (1, 2)
    )
    INSERT INTO Encuentro (idPais1, idPais2, Fecha, idEstadio, idFase, idCampeonato)
    SELECT 
        IdPais1,
        IdPais2,
        Fecha,
        idEstadio,
        idFase,
        idCampeonato
    FROM 
        Cruces;
    
    DECLARE @partidosGenerados INT = @@ROWCOUNT;
    DECLARE @mensaje VARCHAR(100) = 
        CASE 
            WHEN @partidosGenerados > 0 
            THEN CONCAT('Éxito: ', @partidosGenerados, ' partidos de octavos generados.')
            ELSE 'Advertencia: No se generaron partidos. Verifica los equipos clasificados.'
        END;
    
    PRINT @mensaje;
END;