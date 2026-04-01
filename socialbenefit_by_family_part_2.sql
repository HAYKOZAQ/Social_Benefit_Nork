WITH LatestAppFilter AS (
    SELECT 
        A."ID" AS "TargetAppID",
        H."SSN" AS "Primary_SSN",
        MIN(A."DateSubmitted") OVER(PARTITION BY H."SSN") AS "FirstSubmissionDate",
        COUNT(*) OVER(PARTITION BY H."SSN") AS "Total_Applications",
        ROW_NUMBER() OVER(
            PARTITION BY H."SSN" 
            ORDER BY A."ID" DESC
        ) AS "rn"
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
),
RejectionThreeOnly AS (
    SELECT 
        "ApplicationID"
    FROM "ApplicationRejection"
    GROUP BY "ApplicationID"
    HAVING COUNT(*) = 1 AND MIN("RejectionReasonID") = 3
)

SELECT
    "App"."ID" AS "APPLICATIONID", 
    "App"."Num" AS "1", 
    "LAF"."Total_Applications" AS "Total_Count",
    
    -- Calculation 100: The logic you requested
    CASE 
        WHEN EXTRACT(YEAR FROM "App"."DateSubmitted") = 2026 THEN
            CASE WHEN "Eval"."AdultEquivalentMonthlyIncome" - ("HH"."73") / NULLIF("Eval"."AdultEquivalent", 0) < 35875.00 THEN 1 ELSE 0 END
        WHEN EXTRACT(YEAR FROM "App"."DateSubmitted") = 2025 THEN
            CASE WHEN "Eval"."AdultEquivalentMonthlyIncome" - ("HH"."73") / NULLIF("Eval"."AdultEquivalent", 0) < 34581.00 THEN 1 ELSE 0 END
        ELSE 0 
    END AS "100",

    -- Income Columns (73-78, 101)
    COALESCE("HH"."73", 0) AS "73", 
    COALESCE("HH"."73", 0) / NULLIF(COALESCE("Benefit"."AdultEquivalent", "Eval"."AdultEquivalent", 0), 0) AS "74", 
    (COALESCE("HH"."HH_Income_Subtotal", 0) + COALESCE("App"."LivestockIncome", 0) + COALESCE("HH"."73", 0)) AS "75", 
    (COALESCE("HH"."HH_Income_Subtotal", 0) + COALESCE("App"."LivestockIncome", 0) + COALESCE("HH"."73", 0)) / NULLIF("Eval"."AdultEquivalent", 0) AS "76", 
    (34581 - COALESCE("Eval"."AdultEquivalentMonthlyIncome", 0)) AS "77", 
    CASE 
        WHEN EXTRACT(YEAR FROM "App"."DateSubmitted") = 2026 THEN
            CASE WHEN (("Eval"."AdultEquivalentMonthlyIncome" + "HH"."73") / NULLIF("Eval"."AdultEquivalent", 0)) >= 35875.00 THEN 1 ELSE 0 END
        WHEN EXTRACT(YEAR FROM "App"."DateSubmitted") = 2025 THEN
            CASE WHEN (("Eval"."AdultEquivalentMonthlyIncome" + "HH"."73") / NULLIF("Eval"."AdultEquivalent", 0)) >= 34581.00 THEN 1 ELSE 0 END
        ELSE 0 
    END AS "101",

    -- Rejection & Inspection Logic
    COALESCE("Rej"."Is_Only_8", 0) AS "102",
    COALESCE("Rej"."Has_8_And_3", 0) AS "103",
    CASE WHEN "Eval"."InspectionScore" IS NOT NULL THEN 1 ELSE 0 END AS "104",
    "Eval"."InspectionScore" AS "105",
    CASE 
        WHEN COALESCE("Rej"."Is_Only_8", 0) = 1 AND COALESCE("SF_Check"."Is_Only_9", 0) = 1 
        THEN 1 ELSE 0 
    END AS "106",
    COALESCE("HH"."Benefit_BaseBenefit", "Eval"."BaseBenefit", 0) AS "107",
    COALESCE("HH"."Benefit_Supplement", "Eval"."Supplement", 0) AS "108",
    (COALESCE("HH"."Benefit_BaseBenefit", "Eval"."BaseBenefit", 0) + 
     COALESCE("HH"."Benefit_Supplement", "Eval"."Supplement", 0)) AS "109",

    -- Pivoted Stop Factors
    MAX(CASE WHEN "SF"."Name" = 'Շարժական գույք' THEN 1 ELSE 0 END) AS "92-99(1)", 
    MAX(CASE WHEN "SF"."Name" = 'Անշարժ գույք' THEN 1 ELSE 0 END) AS "92-99(2)", 
    MAX(CASE WHEN "SF"."Name" = 'Հայտարարագրված եկամուտ' THEN 1 ELSE 0 END) AS "92-99(3)", 
    MAX(CASE WHEN "SF"."Name" = 'Ձեռնարկատիրական գործունեություն' THEN 1 ELSE 0 END) AS "92-99(4)", 
    MAX(CASE WHEN "SF"."Name" = 'Վարկ' THEN 1 ELSE 0 END) AS "92-99(5)", 
    MAX(CASE WHEN "SF"."Name" = 'Մաքսային' THEN 1 ELSE 0 END) AS "92-99(6)", 
    MAX(CASE WHEN "SF"."Name" = 'Էլեկտրաէներգիա' THEN 1 ELSE 0 END) AS "92-99(7)", 
    MAX(CASE WHEN "SF"."Name" = 'Բնական գազ' THEN 1 ELSE 0 END) AS "92-99(8)", 
    MAX(CASE WHEN "SF"."Name" = 'Տնայց' THEN 1 ELSE 0 END) AS "92-99(9)", 
    MAX(CASE WHEN "SF"."Name" = 'Վարկային պայմանագրի երաշխավոր' THEN 1 ELSE 0 END) AS "92-99(10)"
FROM
    "Application" AS "App"
    INNER JOIN LatestAppFilter AS "LAF" ON "App"."ID" = "LAF"."TargetAppID"
    INNER JOIN RejectionThreeOnly AS "R3" ON "App"."ID" = "R3"."ApplicationID"
    LEFT JOIN (
        SELECT
            h."ApplicationID", 
            SUM(COALESCE(bf."AssignedSum", h."AssignedSum", 0) + COALESCE(bf."AdditionalAssignment", 0)) AS "73", 
            SUM(COALESCE(bf."Salary", h."Salary", 0) + COALESCE(bf."Pension", h."Pension", 0) + COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) + COALESCE(bf."ZinapahAmount", h."ZinapahAmount", 0) + COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) + COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + COALESCE(bf."OrphanSupportAmount", h."OrphanSupportAmount", 0) + COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0)) AS "HH_Income_Subtotal",
            -- Keep original 101 logic here if needed
            MAX(CASE WHEN (COALESCE(bf."Salary", h."Salary", 0) + COALESCE(bf."Pension", h."Pension", 0) + COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) + COALESCE(bf."ZinapahAmount", h."ZinapahAmount", 0) + COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) + COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + COALESCE(bf."OrphanSupportAmount", h."OrphanSupportAmount", 0) + COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0) + COALESCE(bf."AssignedSum", h."AssignedSum", 0)) >= (CASE WHEN EXTRACT(YEAR FROM inner_a."DateSubmitted") = 2026 THEN 35875.00 ELSE 34581.00 END) THEN 1 ELSE 0 END) AS "101",
            MAX(b."BaseBenefit") AS "Benefit_BaseBenefit",
            MAX(b."Supplement") AS "Benefit_Supplement"
        FROM "Household" AS h
        INNER JOIN "Application" AS inner_a ON h."ApplicationID" = inner_a."ID"
        LEFT JOIN "Benefit" AS b ON h."ApplicationID" = b."ApplicationID"
        LEFT JOIN "BenefitFamily" AS bf ON b."ID" = bf."BenefitID" AND h."SSN" = bf."SSN"
        WHERE COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL 
        GROUP BY h."ApplicationID"
    ) AS "HH" ON "App"."ID" = "HH"."ApplicationID"
    LEFT JOIN (
        SELECT 
            "ApplicationID",
            CASE WHEN COUNT(*) > 0 AND MAX(CASE WHEN "RejectionReasonID" = 8 THEN 1 ELSE 0 END) = 1 AND MAX(CASE WHEN "RejectionReasonID" <> 8 THEN 1 ELSE 0 END) = 0 THEN 1 ELSE 0 END AS "Is_Only_8",
            CASE WHEN MAX(CASE WHEN "RejectionReasonID" = 8 THEN 1 ELSE 0 END) = 1 AND MAX(CASE WHEN "RejectionReasonID" = 3 THEN 1 ELSE 0 END) = 1 THEN 1 ELSE 0 END AS "Has_8_And_3"
        FROM "ApplicationRejection"
        GROUP BY "ApplicationID"
    ) AS "Rej" ON "App"."ID" = "Rej"."ApplicationID"
    LEFT JOIN (
        SELECT 
            "ApplicationID",
            CASE WHEN COUNT(*) > 0 AND MAX(CASE WHEN "StopFactorID" = 9 THEN 1 ELSE 0 END) = 1 AND MAX(CASE WHEN "StopFactorID" <> 9 THEN 1 ELSE 0 END) = 0 THEN 1 ELSE 0 END AS "Is_Only_9"
        FROM "ApplicationStopFactor"
        GROUP BY "ApplicationID"
    ) AS "SF_Check" ON "App"."ID" = "SF_Check"."ApplicationID"
    LEFT JOIN "ApplicationEvaluation" AS "Eval" ON "App"."ID" = "Eval"."ApplicationID"
    LEFT JOIN "ApplicationStopFactor" AS "ASF" ON "App"."ID" = "ASF"."ApplicationID"
    LEFT JOIN "StopFactor" AS "SF" ON "ASF"."StopFactorID" = "SF"."ID"
    LEFT JOIN "Benefit" ON "App"."ID" = "Benefit"."ApplicationID"
WHERE "LAF"."rn" = 1 
GROUP BY
    "App"."ID", "App"."Num", "App"."DateSubmitted", "LAF"."Total_Applications", "HH"."73", "Benefit"."AdultEquivalent", "Eval"."AdultEquivalent", 
    "HH"."HH_Income_Subtotal", "App"."LivestockIncome", "Eval"."AdultEquivalentMonthlyIncome", 
    "HH"."101", "Rej"."Is_Only_8", "Rej"."Has_8_And_3", 
    "Eval"."InspectionScore", "SF_Check"."Is_Only_9", "HH"."Benefit_BaseBenefit", 
    "Eval"."BaseBenefit", "HH"."Benefit_Supplement", "Eval"."Supplement";
