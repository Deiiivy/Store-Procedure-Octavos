CREATE OR ALTER PROCEDURE sp_GenerarOctavosDeFinal
    @idCampeonato INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Fase WHERE Fase = 'Octavos de Final')
        BEGIN
            INSERT INTO Fase (Fase) VALUES ('Octavos de Final');
            PRINT 'Fase "Octavos de Final" creada automáticamente.';
        END
        
        DECLARE @idFaseOctavos INT = (SELECT Id FROM Fase WHERE Fase = 'Octavos de Final');
        DECLARE @idEstadio INT = (SELECT MIN(Id) FROM Estadio);
        
        IF @idEstadio IS NULL
        BEGIN
            INSERT INTO Estadio (Estadio) VALUES ('Estadio Temporal');
            SET @idEstadio = SCOPE_IDENTITY();
        END
        
        DELETE FROM Encuentro 
        WHERE idCampeonato = @idCampeonato AND idFase = @idFaseOctavos;
        
        DECLARE @Clasificados TABLE (
            Grupo CHAR(1),
            Posicion INT,
            IdPais INT,
            Pais VARCHAR(100),
            OrdenGrupo INT
        );
        
        INSERT INTO @Clasificados
        SELECT 
            g.Grupo,
            tp.Posicion,
            tp.IdPais,
            p.Pais,
            ROW_NUMBER() OVER (ORDER BY g.Grupo)
        FROM Grupo g
        CROSS APPLY dbo.fTablaPosiciones(g.Id) tp
        JOIN Pais p ON tp.IdPais = p.Id
        WHERE g.IdCampeonato = @idCampeonato AND tp.Posicion IN (1, 2);
        
        IF (SELECT COUNT(DISTINCT Grupo) FROM @Clasificados) <> 8
        BEGIN
            RAISERROR('Requiere 8 grupos con 2 equipos clasificados cada uno', 16, 1);
            RETURN;
        END
        
        DECLARE @Partidos TABLE (
            OrdenPartido INT,
            IdPais1 INT,
            Equipo1 VARCHAR(100),
            IdPais2 INT,
            Equipo2 VARCHAR(100),
            Grupo1 CHAR(1),
            Grupo2 CHAR(1)
        );
        
        INSERT INTO @Partidos
        SELECT 
            ROW_NUMBER() OVER (ORDER BY c1.Grupo),
            c1.IdPais, c1.Pais, c2.IdPais, c2.Pais, c1.Grupo, c2.Grupo
        FROM @Clasificados c1
        JOIN @Clasificados c2 ON c1.Posicion = 1 AND c2.Posicion = 2 AND
           ((c1.Grupo = 'A' AND c2.Grupo = 'B') OR (c1.Grupo = 'C' AND c2.Grupo = 'D') OR
            (c1.Grupo = 'E' AND c2.Grupo = 'F') OR (c1.Grupo = 'G' AND c2.Grupo = 'H'));
        
        INSERT INTO @Partidos
        SELECT 
            4 + ROW_NUMBER() OVER (ORDER BY c1.Grupo),
            c1.IdPais, c1.Pais, c2.IdPais, c2.Pais, c1.Grupo, c2.Grupo
        FROM @Clasificados c1
        JOIN @Clasificados c2 ON c1.Posicion = 1 AND c2.Posicion = 2 AND
           ((c1.Grupo = 'B' AND c2.Grupo = 'A') OR (c1.Grupo = 'D' AND c2.Grupo = 'C') OR
            (c1.Grupo = 'F' AND c2.Grupo = 'E') OR (c1.Grupo = 'H' AND c2.Grupo = 'G'));
        
        INSERT INTO Encuentro (idPais1, idPais2, idEstadio, idFase, idCampeonato)
        SELECT IdPais1, IdPais2, @idEstadio, @idFaseOctavos, @idCampeonato
        FROM @Partidos ORDER BY OrdenPartido;
        
        SELECT
            p.OrdenPartido AS [Partido],
            p.Equipo1,
            p.Equipo2,
            p.Grupo1 + '1 vs ' + p.Grupo2 + '2' AS [Formato],
            (SELECT TOP 1 Estadio FROM Estadio WHERE Id = @idEstadio) AS Estadio
        FROM @Partidos p
        ORDER BY p.OrdenPartido;
            
        RETURN 0;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMsg VARCHAR(200) = 'Error en campeonato ' + CAST(@idCampeonato AS VARCHAR) + ': ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
        RETURN -1;
    END CATCH
END;
GO