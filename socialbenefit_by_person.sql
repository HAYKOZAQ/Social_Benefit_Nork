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
)
SELECT "App"."Num" AS "1",
    "H"."ID" AS "2",
    -- 3: Primary Applicant status translated
    CASE
        WHEN COALESCE(
            "BF"."IsPrimaryApplicant",
            "H"."IsPrimaryApplicant"
        ) = 't' THEN 'այո'
        WHEN COALESCE(
            "BF"."IsPrimaryApplicant",
            "H"."IsPrimaryApplicant"
        ) = 'f' THEN 'ոչ'
        ELSE NULL
    END AS "3",
    COALESCE("BF"."Age", "H"."Age") AS "4",
    COALESCE("BF"."Sex", "H"."Sex") AS "5",
    -- 6: Disability or Functional Limit (any age)
    CASE
        WHEN COALESCE("BF"."HasDisability", "H"."HasDisability") = 't'
        OR COALESCE(
            "BF"."HasFunctionalLimit",
            "H"."HasFunctionalLimit"
        ) = 't' THEN 1
        ELSE 0
    END AS "6",
    -- 7: Aged 18-74 WITH Disability or Functional Limit
    CASE
        WHEN COALESCE("BF"."Age", "H"."Age") BETWEEN 18 AND 74
        AND (
            COALESCE("BF"."HasDisability", "H"."HasDisability") = 't'
            OR COALESCE(
                "BF"."HasFunctionalLimit",
                "H"."HasFunctionalLimit"
            ) = 't'
        ) THEN 1
        ELSE 0
    END AS "7",
    -- 8: IsStudent
    CASE
        WHEN COALESCE("BF"."IsStudent", "H"."IsStudent") = 't' THEN 1
        ELSE 0
    END AS "8",
    -- 9: IsPregnant
    CASE
        WHEN COALESCE("BF"."IsPregnant", "H"."IsPregnant") = 't' THEN 1
        ELSE 0
    END AS "9",
    -- 10: HasDependentChild
    CASE
        WHEN COALESCE(
            "BF"."HasDependentChild",
            "H"."HasDependentChild"
        ) = 't' THEN 1
        ELSE 0
    END AS "10",
    -- 11: Aged 14-17 WITHOUT Disability or Functional Limit
    CASE
        WHEN COALESCE("BF"."Age", "H"."Age") BETWEEN 14 AND 17
        AND COALESCE("BF"."HasDisability", "H"."HasDisability", 'f') != 't'
        AND COALESCE(
            "BF"."HasFunctionalLimit",
            "H"."HasFunctionalLimit",
            'f'
        ) != 't' THEN 1
        ELSE 0
    END AS "11",
    -- 12: Aged 0-17 WITH Disability or Functional Limit
    CASE
        WHEN COALESCE("BF"."Age", "H"."Age") BETWEEN 0 AND 17
        AND (
            COALESCE("BF"."HasDisability", "H"."HasDisability") = 't'
            OR COALESCE(
                "BF"."HasFunctionalLimit",
                "H"."HasFunctionalLimit"
            ) = 't'
        ) THEN 1
        ELSE 0
    END AS "12",
    -- 13: Combined Vulnerability Logic
    CASE
        WHEN COALESCE("BF"."Age", "H"."Age") < 18
        OR (
            COALESCE("BF"."Age", "H"."Age") BETWEEN 18 AND 74
            AND (
                COALESCE("BF"."HasDisability", "H"."HasDisability") = 't'
                OR COALESCE(
                    "BF"."HasFunctionalLimit",
                    "H"."HasFunctionalLimit"
                ) = 't'
            )
        )
        OR COALESCE("BF"."Age", "H"."Age") >= 75 THEN 1
        ELSE 0
    END AS "13",
    -- 15: Employment indicator
    CASE
        WHEN COALESCE("BF"."IsEmployed", "H"."IsEmployed", 'f') = 't' THEN 1
        ELSE 0
    END AS "15",
    -- 16: Salary amount
    COALESCE("BF"."Salary", "H"."Salary") AS "16",
    -- 17: Registered in EWork
    CASE
        WHEN COALESCE(
            "BF"."IsRegisteredInEWork",
            "H"."IsRegisteredInEWork"
        ) = 't' THEN 1
        ELSE 0
    END AS "17",
    -- 23: Support check flag (Any support type not null)
    CASE
        WHEN COALESCE(
            "BF"."Salary", 
            "H"."Salary",
            "BF"."Pension",
            "H"."Pension",
            "BF"."RentalAssistanceAmount",
            "H"."RentalAssistanceAmount",
            "BF"."MigrantSupportAmount",
            "H"."MigrantSupportAmount",
            "BF"."ZinapahAmount",
            "H"."ZinapahAmount",
            "BF"."RefugeeSupportAmount",
            "H"."RefugeeSupportAmount",
            "BF"."FosterFamilyAmount",
            "H"."FosterFamilyAmount",
            "BF"."OrphanSupportAmount",
            "H"."OrphanSupportAmount",
            "BF"."RealEstateNetIncomeAmount",
            "H"."RealEstateNetIncomeAmount",
            "BF"."UrgentSupportAmount",
            "H"."UrgentSupportAmount",
            "BF"."ArtsakhSupportAmount",
            "H"."ArtsakhSupportAmount"
        ) IS NOT NULL THEN 1
        ELSE 0
    END AS "23",
    -- 24: Total Support Sum
    (
        COALESCE(
            "BF"."RentalAssistanceAmount",
            "H"."RentalAssistanceAmount",
            0
        ) + COALESCE("BF"."ZinapahAmount", "H"."ZinapahAmount", 0) + COALESCE(
            "BF"."MigrantSupportAmount",
            "H"."MigrantSupportAmount",
            0
        ) + COALESCE(
            "BF"."RefugeeSupportAmount",
            "H"."RefugeeSupportAmount",
            0
        ) + COALESCE(
            "BF"."OrphanSupportAmount",
            "H"."OrphanSupportAmount",
            0
        ) + COALESCE(
            "BF"."FosterFamilyAmount",
            "H"."FosterFamilyAmount",
            0
        ) + COALESCE(
            "BF"."UrgentSupportAmount",
            "H"."UrgentSupportAmount",
            0
        ) + COALESCE(
            "BF"."ArtsakhSupportAmount",
            "H"."ArtsakhSupportAmount",
            0
        )
    ) AS "24",
    -- 25: Pension indicator
    CASE
        WHEN COALESCE("BF"."Pension", "H"."Pension") IS NOT NULL THEN 1
        ELSE 0
    END AS "25",
    -- 26: Pension amount
    COALESCE("BF"."Pension", "H"."Pension") AS "26",
    -- 31: RealEstateNetIncomeAmount
    COALESCE(
        "BF"."RealEstateNetIncomeAmount",
        "H"."RealEstateNetIncomeAmount"
    ) AS "31",
    -- 33: AssignedSum indicator
    CASE
        WHEN COALESCE("BF"."AssignedSum", "H"."AssignedSum") IS NOT NULL THEN 1
        ELSE 0
    END AS "33",
    -- 34: AssignedSum amount
    COALESCE("BF"."AssignedSum", "H"."AssignedSum") AS "34",
    -- 35: Grand Total Monthly Income
(
    COALESCE("BF"."Salary", "H"."Salary", 0) +
    COALESCE("BF"."Pension", "H"."Pension", 0) +
    COALESCE("BF"."AssignedSum", "H"."AssignedSum", 0) +
    COALESCE("BF"."AdditionalAssignment",0) +
    COALESCE("BF"."RentalAssistanceAmount", "H"."RentalAssistanceAmount", 0) +
    COALESCE("BF"."ZinapahAmount", "H"."ZinapahAmount", 0) +
    COALESCE("BF"."MigrantSupportAmount", "H"."MigrantSupportAmount", 0) +
    COALESCE("BF"."RefugeeSupportAmount", "H"."RefugeeSupportAmount", 0) +
    COALESCE("BF"."FosterFamilyAmount", "H"."FosterFamilyAmount", 0) +
    COALESCE("BF"."RealEstateNetIncomeAmount", "H"."RealEstateNetIncomeAmount", 0) +
    COALESCE("BF"."UrgentSupportAmount", "H"."UrgentSupportAmount", 0) +
    COALESCE("BF"."ArtsakhSupportAmount", "H"."ArtsakhSupportAmount", 0)
) AS "35",
    -- 44: LoanRepaymentAmount indicator
    CASE
        WHEN COALESCE(
            "BF"."LoanRepaymentAmount",
            "H"."LoanRepaymentAmount"
        ) IS NOT NULL THEN 1
        ELSE 0
    END AS "44",
    -- 45: LoanRepaymentAmount actual amount
    COALESCE(
        "BF"."LoanRepaymentAmount",
        "H"."LoanRepaymentAmount"
    ) AS "45"
FROM "Application" AS "App"
    INNER JOIN LatestAppFilter AS "LAF" ON "App"."ID" = "LAF"."TargetAppID"
    INNER JOIN "Household" AS "H" ON "App"."ID" = "H"."ApplicationID"
    LEFT JOIN "Benefit" AS "B" ON "App"."ID" = "B"."ApplicationID"
    LEFT JOIN "BenefitFamily" AS "BF" ON "B"."ID" = "BF"."BenefitID"
    AND "H"."SSN" = "BF"."SSN"
WHERE "LAF"."rn" = 1 -- Filter for physical presence (AbsenceReasonID is NULL)
