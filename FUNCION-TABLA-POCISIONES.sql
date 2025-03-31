IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TF' AND name = 'fTablaPosiciones')
    DROP FUNCTION fTablaPosiciones;
GO

CREATE FUNCTION fTablaPosiciones(@idGrupo int)
RETURNS @TablaPosiciones TABLE(
    Posicion int,
    IdPais int,
    Pais varchar(100),
    PJ int,
    PG int,
    PE int,
    PP int,
    GF int,
    GC int,
    DifGoles int,
    Puntos int
)
AS
BEGIN
    DECLARE @idCampeonato int;
    SELECT @idCampeonato = IdCampeonato FROM Grupo WHERE Id = @idGrupo;

    INSERT INTO @TablaPosiciones
    SELECT
        ROW_NUMBER() OVER(
            ORDER BY 
                (3 * PG + PE) DESC,  -- Puntos
                (GF - GC) DESC,      -- Diferencia de goles
                GF DESC,             -- Goles a favor
                GC ASC               -- Menos goles en contra
        ) AS Posicion,
        IdPais,
        Pais,
        PJ,
        PG,
        PE,
        PP,
        GF,
        GC,
        (GF - GC) AS DifGoles,
        (3 * PG + PE) AS Puntos
    FROM (
        SELECT
            p.Id AS IdPais,
            p.Pais,
            COUNT(CASE WHEN e.Goles1 IS NOT NULL AND e.Goles2 IS NOT NULL THEN 1 END) AS PJ,
            SUM(CASE 
                WHEN (e.IdPais1 = p.Id AND e.Goles1 > e.Goles2) OR 
                     (e.IdPais2 = p.Id AND e.Goles2 > e.Goles1) 
                THEN 1 ELSE 0 END) AS PG,
            SUM(CASE 
                WHEN (e.IdPais1 = p.Id AND e.Goles1 = e.Goles2) OR 
                     (e.IdPais2 = p.Id AND e.Goles2 = e.Goles1) 
                THEN 1 ELSE 0 END) AS PE,
            SUM(CASE 
                WHEN (e.IdPais1 = p.Id AND e.Goles1 < e.Goles2) OR 
                     (e.IdPais2 = p.Id AND e.Goles2 < e.Goles1) 
                THEN 1 ELSE 0 END) AS PP,
            SUM(CASE 
                WHEN e.IdPais1 = p.Id THEN ISNULL(e.Goles1, 0)
                ELSE ISNULL(e.Goles2, 0) END) AS GF,
            SUM(CASE 
                WHEN e.IdPais1 = p.Id THEN ISNULL(e.Goles2, 0)
                ELSE ISNULL(e.Goles1, 0) END) AS GC
        FROM 
            GrupoPais gp
        JOIN 
            Pais p ON gp.IdPais = p.Id
        LEFT JOIN
            Encuentro e ON 
            (
                (e.IdPais1 = p.Id OR e.IdPais2 = p.Id) AND
                e.IdFase = 1 AND -- Fase de Grupos
                e.IdCampeonato = @idCampeonato
            )
        WHERE 
            gp.IdGrupo = @idGrupo
        GROUP BY
            p.Id, p.Pais
    ) AS Estadisticas;
    
    RETURN;
END;
GO