WITH LatestAppFilter AS (
    SELECT 
        A."ID" AS "TargetAppID",
        H."SSN" AS "Primary_SSN",
        MIN(A."DateSubmitted") OVER(PARTITION BY H."SSN") AS "FirstSubmissionDate",
        COUNT(*) OVER(PARTITION BY H."SSN") AS "Total_Applications",
        FIRST_VALUE(A."ID") OVER(
            PARTITION BY H."SSN" 
            ORDER BY A."DateSubmitted" DESC NULLS LAST, A."ID" DESC
        ) AS "LatestDateAppID",
        ROW_NUMBER() OVER(
            PARTITION BY H."SSN" 
            ORDER BY A."ID" DESC
        ) AS rn
    FROM "Application" AS A
    INNER JOIN "Household" AS H ON A."ID" = H."ApplicationID"
    LEFT JOIN "Benefit" AS B ON A."ID" = B."ApplicationID"
    LEFT JOIN "BenefitFamily" AS BF ON B."ID" = BF."BenefitID" AND H."SSN" = BF."SSN"
    WHERE A."ApplicationTypeID" = 1
        AND H."IsPrimaryApplicant" = 't'
        AND A."Num" NOT LIKE '%ՆԽ%'
        AND A."Num" NOT LIKE '%HO%'
        AND (
            COALESCE(BF."AbsenceReasonID", H."AbsenceReasonID") IS NULL
            OR 
            EXISTS (
                SELECT 1 
                FROM "Household" H2
                LEFT JOIN "Benefit" B2 ON H2."ApplicationID" = B2."ApplicationID"
                LEFT JOIN "BenefitFamily" BF2 ON B2."ID" = BF2."BenefitID" AND H2."SSN" = BF2."SSN"
                WHERE H2."ApplicationID" = A."ID"
                  AND COALESCE(BF2."AbsenceReasonID", H2."AbsenceReasonID") IS NULL
            )
        )
)
SELECT 
    laf."TargetAppID" AS "V01",
    app."Content" -> 'CitizenData' -> 'ActualAddress' ->> 'Region' AS "V02",
    app."Content" -> 'CitizenData' -> 'ActualAddress' ->> 'Community' AS "V03",
    laf."LatestDateAppID" AS "V04",
    CASE 
        WHEN app."Status" = 5 THEN 1
        WHEN app."Status" IN (0, 1, 2, 3, 4, 6, 7, 8, 9, 22, 27, 28) THEN 2
        WHEN app."Status" IN (31, 30, 26, 25, 20) THEN 3
        ELSE NULL
    END AS "V05",
    CASE 
        WHEN app."Status" IN (5, 21) THEN 1 
        ELSE 0 
    END AS "V06",
    CASE 
        WHEN app."Status" IN (5, 21) AND b."PayStartDate" IS NOT NULL THEN
            (EXTRACT(YEAR FROM AGE(COALESCE(b."StopDate", CURRENT_DATE), b."PayStartDate")) * 12) +
            EXTRACT(MONTH FROM AGE(COALESCE(b."StopDate", CURRENT_DATE), b."PayStartDate"))
        ELSE NULL
    END AS "V07",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationRejection" ar 
            WHERE ar."ApplicationID" = laf."TargetAppID" 
              AND ar."RejectionReasonID" = 1
        ) THEN 1
        ELSE 0
    END AS "V10",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationRejection" ar 
            WHERE ar."ApplicationID" = laf."TargetAppID" 
              AND ar."RejectionReasonID" = 5
        ) THEN 1
        ELSE 0
    END AS "V11",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationRejection" ar 
            WHERE ar."ApplicationID" = laf."TargetAppID" 
              AND ar."RejectionReasonID" = 6
        ) THEN 1
        ELSE 0
    END AS "V12",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationRejection" ar 
            WHERE ar."ApplicationID" = laf."TargetAppID" 
              AND ar."RejectionReasonID" = 7
        ) THEN 1
        ELSE 0
    END AS "V13",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationRejection" ar 
            WHERE ar."ApplicationID" = laf."TargetAppID" 
              AND ar."RejectionReasonID" = 3
        ) THEN 1
        ELSE 0
    END AS "V14",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationRejection" ar 
            WHERE ar."ApplicationID" = laf."TargetAppID" 
              AND ar."RejectionReasonID" = 8
        ) THEN 1
        ELSE 0
    END AS "V15",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationStopFactor" asf 
            WHERE asf."ApplicationID" = laf."TargetAppID" 
              AND asf."StopFactorID" IS NOT NULL
        ) THEN 1 
        ELSE 0 
    END AS "V16",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationRejection" ar 
            WHERE ar."ApplicationID" = laf."TargetAppID" 
              AND ar."RejectionReasonID" = 4
        ) THEN 1 
        ELSE 0 
    END AS "V17",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationStopFactor" asf 
            WHERE asf."ApplicationID" = laf."TargetAppID" 
              AND asf."StopFactorID" = 1
        ) THEN 1 
        ELSE 0 
    END AS "V18",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationStopFactor" asf 
            WHERE asf."ApplicationID" = laf."TargetAppID" 
              AND asf."StopFactorID" = 2
        ) THEN 1 
        ELSE 0 
    END AS "V19",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationStopFactor" asf 
            WHERE asf."ApplicationID" = laf."TargetAppID" 
              AND asf."StopFactorID" = 4
        ) THEN 1 
        ELSE 0 
    END AS "V20",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationStopFactor" asf 
            WHERE asf."ApplicationID" = laf."TargetAppID" 
              AND asf."StopFactorID" = 5
        ) THEN 1 
        ELSE 0 
    END AS "V21",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationStopFactor" asf 
            WHERE asf."ApplicationID" = laf."TargetAppID" 
              AND asf."StopFactorID" = 6
        ) THEN 1 
        ELSE 0 
    END AS "V22",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationStopFactor" asf 
            WHERE asf."ApplicationID" = laf."TargetAppID" 
              AND asf."StopFactorID" = 7
        ) THEN 1 
        ELSE 0 
    END AS "V23",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationStopFactor" asf 
            WHERE asf."ApplicationID" = laf."TargetAppID" 
              AND asf."StopFactorID" = 8
        ) THEN 1 
        ELSE 0 
    END AS "V24",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationStopFactor" asf 
            WHERE asf."ApplicationID" = laf."TargetAppID" 
              AND asf."StopFactorID" = 9
        ) THEN 1 
        ELSE 0 
    END AS "V25",
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM "ApplicationStopFactor" asf 
            WHERE asf."ApplicationID" = laf."TargetAppID" 
              AND asf."StopFactorID" = 10
        ) THEN 1 
        ELSE 0 
    END AS "V26",
    (
        SELECT COUNT(DISTINCT h."SSN")
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V27",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V28",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V29",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 
                    AND COALESCE(bf."HasDisability", h."HasDisability", 'f') != 't' 
                    AND COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') != 't' 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V30",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") < 18 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V31",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") >= 63 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V32",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 74 
                    AND (
                        COALESCE(bf."HasDisability", h."HasDisability", 'f') = 't' 
                        OR COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') = 't'
                    )
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V33",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") >= 75 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V34",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") < 18 
                     OR (
                         COALESCE(bf."Age", h."Age") BETWEEN 18 AND 74 
                         AND (
                             COALESCE(bf."HasDisability", h."HasDisability", 'f') = 't' 
                             OR COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') = 't'
                         )
                     ) 
                     OR COALESCE(bf."Age", h."Age") >= 75 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V35",
COALESCE(b."DependencyRatio", ae."DependencyRatio") AS "V36",
COALESCE(b."DependencyIndex", ae."DependencyIndex") AS "V37",
ft."Name" AS "V38",
COALESCE(b."AdultEquivalent", ae."AdultEquivalent") AS "V39",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."IsStudent", h."IsStudent") = 't' 
                    AND COALESCE(bf."Age", h."Age") BETWEEN 18 AND 22 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V40",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."IsPregnant", h."IsPregnant") = 't' 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V41",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."HasDependentChild", h."HasDependentChild") = 't' 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V42",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") BETWEEN 14 AND 17 
                    AND COALESCE(bf."HasDisability", h."HasDisability", 'f') != 't' 
                    AND COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') != 't' 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V43",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Salary", h."Salary") IS NOT NULL 
                    AND COALESCE(bf."Salary", h."Salary") != 0 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V44",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN (
                       COALESCE(bf."Pension", h."Pension", 0) != 0 OR 
                       COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) != 0 OR 
                       COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) != 0 OR 
                       COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) != 0 OR 
                       COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) != 0 OR 
                       COALESCE(bf."UrgentSupportAmount", h."UrgentSupportAmount", 0) != 0 OR 
                       COALESCE(bf."ArtsakhSupportAmount", h."ArtsakhSupportAmount", 0) != 0
                   )
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V45",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Pension", h."Pension") IS NOT NULL 
                    AND COALESCE(bf."Pension", h."Pension") != 0 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V46",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 
                    AND COALESCE(bf."HasDisability", h."HasDisability", 'f') != 't' 
                    AND COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') != 't' 
                    AND COALESCE(bf."Salary", h."Salary", 0) > 0 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V47",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 
                    AND COALESCE(bf."HasDisability", h."HasDisability", 'f') != 't' 
                    AND COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') != 't' 
                    AND (COALESCE(bf."Salary", h."Salary", 0) + COALESCE(bf."Pension", h."Pension", 0)) = 0 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V48",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 
                    AND COALESCE(bf."IsEmployed", h."IsEmployed", 'f') = 'f' 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V49",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") BETWEEN 14 AND 17 
                    AND COALESCE(bf."HasDisability", h."HasDisability", 'f') != 't' 
                    AND COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') != 't' 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V50",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."Age", h."Age") >= 65 
                    AND COALESCE(bf."Pension", h."Pension", 0) = 0 
                    AND COALESCE(bf."IsEmployed", h."IsEmployed", 'f') = 'f' 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V51",
(
        SELECT COUNT(DISTINCT CASE 
                   WHEN COALESCE(bf."IsRegisteredInEWork", h."IsRegisteredInEWork", 'f') = 't' 
                   THEN COALESCE(bf."SSN", h."SSN") 
               END)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V52",
(
        SELECT COALESCE(SUM(
            -- 1. Բոլոր սոցիալական աջակցությունները
            COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) +
            COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) +
            COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + 
            COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + 
            COALESCE(bf."UrgentSupportAmount", h."UrgentSupportAmount", 0) + 
            COALESCE(bf."ArtsakhSupportAmount", h."ArtsakhSupportAmount", 0) +
            
            -- 2. Կենսաթոշակ
            COALESCE(bf."Pension", h."Pension", 0) +
            
            -- 3. Զինապահ և անշարժ գույքից / այլ տնտեսությունից եկամուտներ
            COALESCE(bf."ZinapahAmount", h."ZinapahAmount", 0) +
            COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0) +
            
            -- 4. Աշխատավարձի հաշվարկման կանոնը (բացառություն դիմելուց հետո ընդունվածների համար)
            CASE 
                -- Եթե ընդունվել է աշխատանքի դիմելուց հետո, ընթացիկ աշխատավարձը չի հաշվվում,
                -- վերցվում է դիմելու պահին նախորդող պատմական աշխատավարձը BenefitFamilyHistory-ից
                WHEN bf."EmploymentStartDate" > app."DateSubmitted" THEN (
                    SELECT COALESCE(bfh."Salary", 0)
                    FROM "BenefitFamilyHistory" bfh
                    WHERE (bfh."BenefitFamilyID" = bf."ID" OR bfh."SSN" = h."SSN")
                      AND (
                          bfh."Year" < EXTRACT(YEAR FROM app."DateSubmitted")
                          OR (
                              bfh."Year" = EXTRACT(YEAR FROM app."DateSubmitted") 
                              AND bfh."Month" <= EXTRACT(MONTH FROM app."DateSubmitted")
                          )
                      )
                    ORDER BY bfh."Year" DESC, bfh."Month" DESC
                    LIMIT 1
                )
                -- Հակառակ դեպքում (սովորական դեպք) հաշվվում է ընթացիկ աշխատավարձը
                ELSE COALESCE(bf."Salary", h."Salary", 0)
            END
        ), 0)
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ) AS "V53",
(
        COALESCE((
            SELECT SUM(
                COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) +
                COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) +
                COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + 
                COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + 
                COALESCE(bf."UrgentSupportAmount", h."UrgentSupportAmount", 0) + 
                COALESCE(bf."ArtsakhSupportAmount", h."ArtsakhSupportAmount", 0) +
                COALESCE(bf."Salary", h."Salary", 0) +
                COALESCE(bf."Pension", h."Pension", 0) +
                COALESCE(bf."ZinapahAmount", h."ZinapahAmount", 0) +
                COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0)
            )
            FROM "Household" h
            LEFT JOIN "Benefit" ben 
                ON h."ApplicationID" = ben."ApplicationID"
            LEFT JOIN "BenefitFamily" bf 
                ON ben."ID" = bf."BenefitID" 
               AND h."SSN" = bf."SSN"
            WHERE h."ApplicationID" = laf."TargetAppID"
              AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
        ), 0) 
        + COALESCE(b."BenefitAmount", 0)
    ) AS "V54",
(
        COALESCE(b."LivestockIncome", app."LivestockIncome", 0) +
        COALESCE((
            SELECT SUM(COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0))
            FROM "Household" h
            LEFT JOIN "Benefit" ben 
                ON h."ApplicationID" = ben."ApplicationID"
            LEFT JOIN "BenefitFamily" bf 
                ON ben."ID" = bf."BenefitID" 
               AND h."SSN" = bf."SSN"
            WHERE h."ApplicationID" = laf."TargetAppID"
              AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
        ), 0)
    ) AS "V55",
    -- V56. Ընտանիքի բոլոր անդամների գյուղատնտեսական հողի ընդհանուր մակերեսը (հա), 0՝ եթե գ/տ հող չունեն.
    -- Հաշվվում են միայն հարկվող (amount > 0) հողակտորները՝ ըստ personRealityData-ի (ըստ մասնաբաժնի՝ partSize):
    COALESCE((
        SELECT ROUND(SUM(COALESCE((p ->> 'partSize')::numeric, (p ->> 'area')::numeric)), 2)
        FROM jsonb_array_elements(
                 CASE WHEN jsonb_typeof(sfr."Content" -> 'data') = 'array' 
                      THEN sfr."Content" -> 'data' ELSE '[]'::jsonb END) AS d
        CROSS JOIN LATERAL jsonb_array_elements(
                 CASE WHEN jsonb_typeof(d -> 'personRealityData') = 'array' 
                      THEN d -> 'personRealityData' ELSE '[]'::jsonb END) AS pr
        CROSS JOIN LATERAL jsonb_array_elements(
                 CASE WHEN jsonb_typeof(pr -> 'parcells') = 'array' 
                      THEN pr -> 'parcells' ELSE '[]'::jsonb END) AS p
        WHERE COALESCE((p ->> 'amount')::numeric, 0) > 0
    ), 0) AS "V56",
    -- V57. Ընտանիքի բոլոր անդամների գյուղատնտեսական հողի կադաստրային զուտ գումարային ամսական եկամուտը (դրամ).
    -- MTA պատասխանի incomeAmount դաշտը հենց այդ ամսական կադաստրային զուտ եկամուտն է, ուստի գումարվում է ուղիղ:
    COALESCE((
        SELECT ROUND(SUM(COALESCE((d ->> 'incomeAmount')::numeric, 0)), 2)
        FROM jsonb_array_elements(
                 CASE WHEN jsonb_typeof(sfr."Content" -> 'data') = 'array' 
                      THEN sfr."Content" -> 'data' ELSE '[]'::jsonb END) AS d
    ), 0) AS "V57",
COALESCE(b."LivestockIncome", app."LivestockIncome", 0) AS "V58",
(
    SELECT COALESCE(SUM(
        COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) +
        COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) +
        COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + 
        COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + 
        COALESCE(bf."UrgentSupportAmount", h."UrgentSupportAmount", 0) + 
        COALESCE(bf."ArtsakhSupportAmount", h."ArtsakhSupportAmount", 0)
    ), 0)
    FROM "Household" h
    LEFT JOIN "Benefit" ben 
        ON h."ApplicationID" = ben."ApplicationID"
    LEFT JOIN "BenefitFamily" bf 
        ON ben."ID" = bf."BenefitID" 
       AND h."SSN" = bf."SSN"
    WHERE h."ApplicationID" = laf."TargetAppID"
      AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
) AS "V59",
(
    SELECT COALESCE(SUM(
        COALESCE(bf."Pension", h."Pension", 0)
    ), 0)
    FROM "Household" h
    LEFT JOIN "Benefit" ben 
        ON h."ApplicationID" = ben."ApplicationID"
    LEFT JOIN "BenefitFamily" bf 
        ON ben."ID" = bf."BenefitID" 
       AND h."SSN" = bf."SSN"
    WHERE h."ApplicationID" = laf."TargetAppID"
      AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
) AS "V62",
(
    (
        COALESCE((
            SELECT SUM(
                COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) +
                COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) +
                COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + 
                COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + 
                COALESCE(bf."UrgentSupportAmount", h."UrgentSupportAmount", 0) + 
                COALESCE(bf."ArtsakhSupportAmount", h."ArtsakhSupportAmount", 0) +
                COALESCE(bf."Salary", h."Salary", 0) +
                COALESCE(bf."Pension", h."Pension", 0) +
                COALESCE(bf."ZinapahAmount", h."ZinapahAmount", 0) +
                COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0)
            )
            FROM "Household" h
            LEFT JOIN "Benefit" ben 
                ON h."ApplicationID" = ben."ApplicationID"
            LEFT JOIN "BenefitFamily" bf 
                ON ben."ID" = bf."BenefitID" 
               AND h."SSN" = bf."SSN"
            WHERE h."ApplicationID" = laf."TargetAppID"
              AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
        ), 0)
        + COALESCE(b."LivestockIncome", app."LivestockIncome", 0)
    )
    / NULLIF(COALESCE(b."AdultEquivalent", ae."AdultEquivalent"), 0)
) AS "V63",
(
    SELECT COUNT(DISTINCT CASE 
               WHEN COALESCE(bf."AssignedSum", h."AssignedSum") IS NOT NULL 
                AND COALESCE(bf."AssignedSum", h."AssignedSum") != 0 
               THEN COALESCE(bf."SSN", h."SSN") 
           END)
    FROM "Household" h
    LEFT JOIN "Benefit" ben 
        ON h."ApplicationID" = ben."ApplicationID"
    LEFT JOIN "BenefitFamily" bf 
        ON ben."ID" = bf."BenefitID" 
       AND h."SSN" = bf."SSN"
    WHERE h."ApplicationID" = laf."TargetAppID"
      AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
) AS "V64",
(
    SELECT COALESCE(SUM(
        COALESCE(bf."AssignedSum", h."AssignedSum", 0) + 
        COALESCE(bf."AdditionalAssignment", 0)
    ), 0)
    FROM "Household" h
    LEFT JOIN "Benefit" ben 
        ON h."ApplicationID" = ben."ApplicationID"
    LEFT JOIN "BenefitFamily" bf 
        ON ben."ID" = bf."BenefitID" 
       AND h."SSN" = bf."SSN"
    WHERE h."ApplicationID" = laf."TargetAppID"
      AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
) AS "V65",
(
    COALESCE((
        SELECT SUM(
            COALESCE(bf."AssignedSum", h."AssignedSum", 0) + 
            COALESCE(bf."AdditionalAssignment", 0)
        )
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ), 0)
    / NULLIF(COALESCE(b."AdultEquivalent", ae."AdultEquivalent", 0), 0)
) AS "V66",
(
    COALESCE((
        SELECT SUM(
            -- HH_Income_Subtotal
            COALESCE(bf."Salary", h."Salary", 0) + 
            COALESCE(bf."Pension", h."Pension", 0) + 
            COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) + 
            COALESCE(bf."ZinapahAmount", h."ZinapahAmount", 0) + 
            COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) + 
            COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + 
            COALESCE(bf."OrphanSupportAmount", h."OrphanSupportAmount", 0) + 
            COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + 
            COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0) +
            -- 73 (AssignedSum + AdditionalAssignment)
            COALESCE(bf."AssignedSum", h."AssignedSum", 0) + 
            COALESCE(bf."AdditionalAssignment", 0)
        )
        FROM "Household" h
        LEFT JOIN "Benefit" ben 
            ON h."ApplicationID" = ben."ApplicationID"
        LEFT JOIN "BenefitFamily" bf 
            ON ben."ID" = bf."BenefitID" 
           AND h."SSN" = bf."SSN"
        WHERE h."ApplicationID" = laf."TargetAppID"
          AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
    ), 0)
    + COALESCE(b."LivestockIncome", app."LivestockIncome", 0)
) AS "V67",
(
    (
        COALESCE((
            SELECT SUM(
                -- HH_Income_Subtotal
                COALESCE(bf."Salary", h."Salary", 0) + 
                COALESCE(bf."Pension", h."Pension", 0) + 
                COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) + 
                COALESCE(bf."ZinapahAmount", h."ZinapahAmount", 0) + 
                COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) + 
                COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + 
                COALESCE(bf."OrphanSupportAmount", h."OrphanSupportAmount", 0) + 
                COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + 
                COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0) +
                -- 73 (AssignedSum + AdditionalAssignment)
                COALESCE(bf."AssignedSum", h."AssignedSum", 0) + 
                COALESCE(bf."AdditionalAssignment", 0)
            )
            FROM "Household" h
            LEFT JOIN "Benefit" ben 
                ON h."ApplicationID" = ben."ApplicationID"
            LEFT JOIN "BenefitFamily" bf 
                ON ben."ID" = bf."BenefitID" 
               AND h."SSN" = bf."SSN"
            WHERE h."ApplicationID" = laf."TargetAppID"
              AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
        ), 0)
        + COALESCE(b."LivestockIncome", app."LivestockIncome", 0)
        + COALESCE(b."BenefitAmount", 0)
    )
    / NULLIF(ae."AdultEquivalent", 0)
) AS "V68",
(
    CASE 
        WHEN EXTRACT(YEAR FROM app."DateSubmitted") = 2025 THEN 34581
        WHEN EXTRACT(YEAR FROM app."DateSubmitted") = 2026 THEN 35875
        ELSE 35875 -- or default threshold if outside 2025/2026
    END - COALESCE(ae."AdultEquivalentMonthlyIncome", 0)
) AS "V69",
CASE 
    WHEN (
        (
            COALESCE((
                SELECT SUM(
                    -- HH_Income_Subtotal
                    COALESCE(bf."Salary", h."Salary", 0) + 
                    COALESCE(bf."Pension", h."Pension", 0) + 
                    COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) + 
                    COALESCE(bf."ZinapahAmount", h."ZinapahAmount", 0) + 
                    COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) + 
                    COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + 
                    COALESCE(bf."OrphanSupportAmount", h."OrphanSupportAmount", 0) + 
                    COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + 
                    COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0) +
                    -- 73 (AssignedSum + AdditionalAssignment)
                    COALESCE(bf."AssignedSum", h."AssignedSum", 0) + 
                    COALESCE(bf."AdditionalAssignment", 0)
                )
                FROM "Household" h
                LEFT JOIN "Benefit" ben 
                    ON h."ApplicationID" = ben."ApplicationID"
                LEFT JOIN "BenefitFamily" bf 
                    ON ben."ID" = bf."BenefitID" 
                   AND h."SSN" = bf."SSN"
                WHERE h."ApplicationID" = laf."TargetAppID"
                  AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
            ), 0)
            + COALESCE(b."LivestockIncome", app."LivestockIncome", 0)
            + COALESCE(b."BenefitAmount", 0)
        )
        / NULLIF(ae."AdultEquivalent", 0)
    ) > (
        CASE 
            WHEN EXTRACT(YEAR FROM app."DateCreated") = 2025 THEN 34581
            WHEN EXTRACT(YEAR FROM app."DateCreated") = 2026 THEN 35875
            ELSE 35875
        END * 1.30
    ) THEN 1
    ELSE 0
END AS "V70",
CASE 
    WHEN (
        (
            COALESCE((
                SELECT SUM(
                    -- HH_Income_Subtotal
                    COALESCE(bf."Salary", h."Salary", 0) + 
                    COALESCE(bf."Pension", h."Pension", 0) + 
                    COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) + 
                    COALESCE(bf."ZinapahAmount", h."ZinapahAmount", 0) + 
                    COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) + 
                    COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + 
                    COALESCE(bf."OrphanSupportAmount", h."OrphanSupportAmount", 0) + 
                    COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + 
                    COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0) +
                    -- 73 (AssignedSum + AdditionalAssignment)
                    COALESCE(bf."AssignedSum", h."AssignedSum", 0) + 
                    COALESCE(bf."AdditionalAssignment", 0)
                )
                FROM "Household" h
                LEFT JOIN "Benefit" ben 
                    ON h."ApplicationID" = ben."ApplicationID"
                LEFT JOIN "BenefitFamily" bf 
                    ON ben."ID" = bf."BenefitID" 
                   AND h."SSN" = bf."SSN"
                WHERE h."ApplicationID" = laf."TargetAppID"
                  AND COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
            ), 0)
            + COALESCE(b."LivestockIncome", app."LivestockIncome", 0)
            + COALESCE(b."BenefitAmount", 0)
        )
        / NULLIF(ae."AdultEquivalent", 0)
    ) > (
        CASE 
            WHEN EXTRACT(YEAR FROM app."DateSubmitted") = 2025 THEN 34581
            WHEN EXTRACT(YEAR FROM app."DateSubmitted") = 2026 THEN 35875
            ELSE 35875
        END * 1.60
    ) THEN 1
    ELSE 0
END AS "V71",
    -- V72. Ընտանիքի՝ 2015 թվականից սկսած (ներառյալ) արտադրված ավտոտրանսպորտային միջոցների քանակը (ըստ StopFactorID = 1 պատասխանի).
    COALESCE((
        SELECT COUNT(*)
        FROM jsonb_array_elements(
                 CASE WHEN jsonb_typeof(sfr1."Content" -> 'data' -> 'personsList') = 'array' 
                      THEN sfr1."Content" -> 'data' -> 'personsList' ELSE '[]'::jsonb END) AS pl
        CROSS JOIN LATERAL jsonb_array_elements(
                 CASE WHEN jsonb_typeof(pl -> 'movablePropertyData') = 'array' 
                      THEN pl -> 'movablePropertyData' ELSE '[]'::jsonb END) AS mp
        WHERE CASE WHEN mp ->> 'released' ~ '^[0-9]{4}$' 
                   THEN (mp ->> 'released')::int ELSE 0 END >= 2015
    ), 0) AS "V72",
    -- V73. Ընտանիքի ավտոտրանսպորտային միջոցների գումարային գույքահարկը (դրամ)՝ 12000 շեմի հետ համեմատվող գումարը.
    -- Չի զտվում ըստ արտադրության տարվա. >12000 գումարը հենց բացառող գործոնի չափանիշն է, հետևաբար գումարվում են բոլոր միջոցները։
    COALESCE((
        SELECT ROUND(SUM(COALESCE((mp -> 'tkenResponse' ->> 'amount')::numeric, 0)), 2)
        FROM jsonb_array_elements(
                 CASE WHEN jsonb_typeof(sfr1."Content" -> 'data' -> 'personsList') = 'array' 
                      THEN sfr1."Content" -> 'data' -> 'personsList' ELSE '[]'::jsonb END) AS pl
        CROSS JOIN LATERAL jsonb_array_elements(
                 CASE WHEN jsonb_typeof(pl -> 'movablePropertyData') = 'array' 
                      THEN pl -> 'movablePropertyData' ELSE '[]'::jsonb END) AS mp
        WHERE CASE WHEN mp ->> 'released' ~ '^[0-9]{4}$' 
                   THEN (mp ->> 'released')::int ELSE 0 END >= 2015
    ), 0) AS "V73",
    -- V74. Արդյո՞ք ընտանիքի ավտոտրանսպորտային միջոցների գումարային գույքահարկը գերազանցում է 12000 դրամի սահմանաչափը (MovableTaxCap), 1-այո, 0-ոչ։
    CASE 
        WHEN COALESCE((
            SELECT SUM(COALESCE((mp -> 'tkenResponse' ->> 'amount')::numeric, 0))
            FROM jsonb_array_elements(
                     CASE WHEN jsonb_typeof(sfr1."Content" -> 'data' -> 'personsList') = 'array' 
                          THEN sfr1."Content" -> 'data' -> 'personsList' ELSE '[]'::jsonb END) AS pl
            CROSS JOIN LATERAL jsonb_array_elements(
                     CASE WHEN jsonb_typeof(pl -> 'movablePropertyData') = 'array' 
                          THEN pl -> 'movablePropertyData' ELSE '[]'::jsonb END) AS mp
            WHERE CASE WHEN mp ->> 'released' ~ '^[0-9]{4}$' 
                       THEN (mp ->> 'released')::int ELSE 0 END >= 2015
        ), 0) > 12000 THEN 1 
        ELSE 0 
    END AS "V74",
    -- V75. Դիմելու օրվա դրությամբ ընտանիքի անդամներին պատկանող անշարժ գույքերի քանակը։
    -- Յուրաքանչյուր unitId հաշվվում է մեկ անգամ, եթե rights[].subjects[].ssn-ում կա Household-ի SSN,
    -- և այդ սեփականության իրավունքը չի դադարել մինչև Application.DateSubmitted-ը։
    COALESCE((
        SELECT COUNT(DISTINCT u ->> 'unitId')
        FROM jsonb_array_elements(
                 CASE WHEN jsonb_typeof(sfr."Content" -> 'data') = 'array' 
                      THEN sfr."Content" -> 'data' ELSE '[]'::jsonb END) AS d
        CROSS JOIN LATERAL jsonb_array_elements(
                 CASE WHEN jsonb_typeof(d -> 'originalCadastreData') = 'array' 
                      THEN d -> 'originalCadastreData' ELSE '[]'::jsonb END) AS u
        WHERE NULLIF(u ->> 'unitId', '') IS NOT NULL
          AND EXISTS (
              SELECT 1
              FROM jsonb_array_elements(
                       CASE WHEN jsonb_typeof(u -> 'rights') = 'array' 
                            THEN u -> 'rights' ELSE '[]'::jsonb END) AS r
              CROSS JOIN LATERAL jsonb_array_elements(
                       CASE WHEN jsonb_typeof(r -> 'subjects') = 'array' 
                            THEN r -> 'subjects' ELSE '[]'::jsonb END) AS subject
              INNER JOIN "Household" AS h
                  ON h."ApplicationID" = laf."TargetAppID"
                 AND h."SSN" = subject ->> 'ssn'
              WHERE (r ->> 'rightType') LIKE '%ՍԵՓԱԿԱՆՈՒԹՅՈՒՆ%'
                AND (
                    NULLIF(r ->> 'rightTermDate', '') IS NULL
                    OR (
                        r ->> 'rightTermDate' ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                        AND app."DateSubmitted" IS NOT NULL
                        AND (r ->> 'rightTermDate')::date > app."DateSubmitted"::date
                    )
                )
          )
    ), 0) AS "V75",
    -- V76. Ընտանիքի անշարժ գույքերի ընդհանուր գույքահարկը (դրամ)՝ MTA պատասխանի ընտանիքի ընդհանուր totalAmount դաշտից։
    COALESCE(NULLIF(sfr."Content" ->> 'totalAmount', '')::numeric, 0) AS "V76",
    -- V77. Գույքահարկի շեմի գերազանցում՝ Երևան 18750 դրամ, այլ մարզեր 6560 դրամ։
    CASE
        WHEN COALESCE(NULLIF(sfr."Content" ->> 'totalAmount', '')::numeric, 0) >
             CASE
                 WHEN app."Content" -> 'CitizenData' -> 'ActualAddress' ->> 'Region' = 'Երևան' THEN 18750
                 ELSE 6560
             END
        THEN 1
        ELSE 0
    END AS "V77",
    -- V78. Ընտանիքում ձեռնարկատիրական գործունեությամբ զբաղված անդամի կամ ընտանիքի անդամ չհանդիսացող վարձու աշխատող ունեցող ԱՁ-ի առկայություն։
    CASE
        WHEN COALESCE(
            NULLIF(sfb4."Content" -> 'data' ->> 'isStopFactor', '')::boolean,
            FALSE
        ) THEN 1
        ELSE 0
    END AS "V78",
    -- V79. Ձեռնարկատիրական գործունեությամբ զբաղված ընտանիքի անդամների քանակը՝ Factor 4 personsList SSN-ները համադրելով Household-ի հետ։
    COALESCE((
        SELECT COUNT(DISTINCT person ->> 'ssn')
        FROM jsonb_array_elements(
                 CASE WHEN jsonb_typeof(sfb4."Content" -> 'data' -> 'personsList') = 'array'
                      THEN sfb4."Content" -> 'data' -> 'personsList' ELSE '[]'::jsonb END) AS person
        INNER JOIN "Household" AS household_member
            ON household_member."ApplicationID" = laf."TargetAppID"
           AND household_member."SSN" = person ->> 'ssn'
        WHERE sfb4."Content" -> 'data' ->> 'isStopFactor' = 'true'
          AND NULLIF(person ->> 'ssn', '') IS NOT NULL
    ), 0) AS "V79",
    -- V80. Ընտանիքի՝ ապրանքների ներմուծման կամ արտահանման համար գումարային մաքսային վճարը (դրամ)՝ BenefitStopFactorID 6-ի data.totalAmount-ից։
    COALESCE(NULLIF(sfc6."Content" -> 'data' ->> 'totalAmount', '')::numeric, 0) AS "V80",
    -- V81. Ընտանիքի ընդհանուր մաքսային վճարը՝ ընտանիքի մեկ հաշվարկային անդամի հաշվով։
    COALESCE(NULLIF(sfc6."Content" -> 'data' ->> 'totalAmount', '')::numeric, 0)
        / NULLIF(COALESCE(b."AdultEquivalent", ae."AdultEquivalent"), 0) AS "V81",
    -- V82. Արդյո՞ք մեկ հաշվարկային անդամի հաշվով մաքսային վճարը գերազանցում է տարվա սահմանաչափը։
    CASE
        WHEN COALESCE(NULLIF(sfc6."Content" -> 'data' ->> 'totalAmount', '')::numeric, 0)
             / NULLIF(COALESCE(b."AdultEquivalent", ae."AdultEquivalent"), 0)
             > CASE
                   WHEN EXTRACT(YEAR FROM app."DateSubmitted") = 2025 THEN 34581
                   WHEN EXTRACT(YEAR FROM app."DateSubmitted") = 2026 THEN 35875
                   ELSE 35875
               END
        THEN 1
        ELSE 0
    END AS "V82",
    -- V83. Ընտանիքի՝ էլեկտրաէներգիայի ամսական միջին սպառումը ամռան ամիսներին (կՎտ/ժամ). աղբյուրում տվյալ չկա։
    NULL::numeric AS "V83"
FROM LatestAppFilter AS laf
INNER JOIN "Application" AS app ON laf."TargetAppID" = app."ID"
LEFT JOIN "Benefit" AS b ON laf."TargetAppID" = b."ApplicationID"
LEFT JOIN "ApplicationEvaluation" AS ae ON laf."TargetAppID" = ae."ApplicationID"
LEFT JOIN "FamilyType" AS ft 
    ON ft."ID" = COALESCE(b."FamilyTypeID", ae."FamilyTypeID")
-- Անշարժ գույք՝ նախ նպաստի արտաքին պատմության վերջին պատասխանը, դրա բացակայության դեպքում՝ դիմումի պատասխանը
LEFT JOIN LATERAL (
    SELECT source."Content"
    FROM (
        (
            SELECT history."Content", 1 AS source_priority, history."DateCreated", history."ID" AS source_id
            FROM "External"."BenefitExternalDataHistory" AS history
            WHERE history."BenefitID" = b."ID"
              AND history."BenefitStopFactorID" = 2
            ORDER BY history."DateCreated" DESC NULLS LAST, history."ID" DESC
            LIMIT 1
        )
        UNION ALL
        (
            SELECT response."Content", 2 AS source_priority, response."DateCreated", 0::bigint AS source_id
            FROM "External"."ApplicationStopFactorResponse" AS response
            WHERE response."ApplicationID" = laf."TargetAppID"
              AND response."StopFactorID" = 2
            ORDER BY response."DateCreated" DESC NULLS LAST
            LIMIT 1
        )
    ) AS source
    ORDER BY source.source_priority, source."DateCreated" DESC NULLS LAST, source.source_id DESC
    LIMIT 1
) AS sfr ON TRUE
-- Շարժական գույք՝ նախ նպաստի արտաքին պատմության վերջին պատասխանը, դրա բացակայության դեպքում՝ դիմումի պատասխանը
LEFT JOIN LATERAL (
    SELECT source."Content"
    FROM (
        (
            SELECT history."Content", 1 AS source_priority, history."DateCreated", history."ID" AS source_id
            FROM "External"."BenefitExternalDataHistory" AS history
            WHERE history."BenefitID" = b."ID"
              AND history."BenefitStopFactorID" = 1
            ORDER BY history."DateCreated" DESC NULLS LAST, history."ID" DESC
            LIMIT 1
        )
        UNION ALL
        (
            SELECT response."Content", 2 AS source_priority, response."DateCreated", 0::bigint AS source_id
            FROM "External"."ApplicationStopFactorResponse" AS response
            WHERE response."ApplicationID" = laf."TargetAppID"
              AND response."StopFactorID" = 1
            ORDER BY response."DateCreated" DESC NULLS LAST
            LIMIT 1
        )
    ) AS source
    ORDER BY source.source_priority, source."DateCreated" DESC NULLS LAST, source.source_id DESC
    LIMIT 1
) AS sfr1 ON TRUE
-- Ձեռնարկատիրական գործունեություն՝ նախ նպաստի արտաքին պատմության վերջին պատասխանը, ապա դիմումի պատասխանի fallback-ը
LEFT JOIN LATERAL (
    SELECT source."Content"
    FROM (
        (
            SELECT history."Content", 1 AS source_priority, history."DateCreated", history."ID" AS source_id
            FROM "External"."BenefitExternalDataHistory" AS history
            WHERE history."BenefitID" = b."ID"
              AND history."BenefitStopFactorID" = 4
            ORDER BY history."DateCreated" DESC NULLS LAST, history."ID" DESC
            LIMIT 1
        )
        UNION ALL
        (
            SELECT response."Content", 2 AS source_priority, response."DateCreated", 0::bigint AS source_id
            FROM "External"."ApplicationStopFactorResponse" AS response
            WHERE response."ApplicationID" = laf."TargetAppID"
              AND response."StopFactorID" = 4
            ORDER BY response."DateCreated" DESC NULLS LAST
            LIMIT 1
        )
    ) AS source
    ORDER BY source.source_priority, source."DateCreated" DESC NULLS LAST, source.source_id DESC
    LIMIT 1
) AS sfb4 ON TRUE
-- Մաքսային վճար՝ նախ նպաստի արտաքին պատմության վերջին պատասխանը, ապա դիմումի պատասխանի fallback-ը
LEFT JOIN LATERAL (
    SELECT source."Content"
    FROM (
        (
            SELECT history."Content", 1 AS source_priority, history."DateCreated", history."ID" AS source_id
            FROM "External"."BenefitExternalDataHistory" AS history
            WHERE history."BenefitID" = b."ID"
              AND history."BenefitStopFactorID" = 6
            ORDER BY history."DateCreated" DESC NULLS LAST, history."ID" DESC
            LIMIT 1
        )
        UNION ALL
        (
            SELECT response."Content", 2 AS source_priority, response."DateCreated", 0::bigint AS source_id
            FROM "External"."ApplicationStopFactorResponse" AS response
            WHERE response."ApplicationID" = laf."TargetAppID"
              AND response."StopFactorID" = 6
            ORDER BY response."DateCreated" DESC NULLS LAST
            LIMIT 1
        )
    ) AS source
    ORDER BY source.source_priority, source."DateCreated" DESC NULLS LAST, source.source_id DESC
    LIMIT 1
) AS sfc6 ON TRUE
WHERE laf.rn = 1
ORDER BY "V01" ASC;
