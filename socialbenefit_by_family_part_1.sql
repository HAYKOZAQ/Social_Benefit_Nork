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
SELECT
    "App"."ID" AS "APPLICATIONID", 
    "App"."Num" AS "1", 
    "App"."Content" -> 'CitizenData' -> 'ActualAddress' ->> 'Region' AS "2", 
    "App"."Content" -> 'CitizenData' -> 'ActualAddress' ->> 'Community' AS "3",
    CASE 
        WHEN "App"."Status" IN (20,25,26,30) THEN 1
        WHEN "App"."Status" IN (1, 2, 3, 4, 6, 7, 8, 9, 22, 27, 28) THEN 0
        ELSE NULL 
    END AS "4", 
    CASE 
        WHEN "App"."Status" IN (5,20,21,25,26,30) THEN 1
        WHEN "App"."Status" IN (1, 2, 3, 4, 6, 7, 8, 9, 22, 27, 28) THEN 0
        ELSE NULL 
    END AS "5",  
    CASE 
        WHEN "Benefit"."BenefitStatusID" IN (0, 1, 2) THEN 1
        WHEN "Benefit"."BenefitStatusID" IN (3, 4) THEN 0
        ELSE NULL 
    END AS "6", 
    EXTRACT(YEAR FROM AGE('2026-02-24', "LAF"."FirstSubmissionDate")) * 12 +
    EXTRACT(MONTH FROM AGE('2026-02-24', "LAF"."FirstSubmissionDate")) as "10",
    EXTRACT(YEAR FROM AGE(COALESCE("Benefit"."StopDate", '2026-02-24'), "Benefit"."OrderDate")) * 12 +
    EXTRACT(MONTH FROM AGE(COALESCE("Benefit"."StopDate", '2026-02-24'), "Benefit"."OrderDate")) as "11",
    "LAF"."Total_Applications" AS "12",

    MAX(CASE WHEN "RR"."Name" = 'Դիմումը, դրանում ներկայացված տվյալները կամ փաստաթղթերը չեն համապատասխանում օրենսդրությամբ և ՀՀ կառավարության 09.01.2025 թ. N 27-Ն որոշմամբ սահմանված պայմաններին և պահանջներին' THEN 1 ELSE 0 END) AS "13-19(1)", 
    MAX(CASE WHEN "RR"."Name" = 'Դիմումի բնօրինակը չի ներկայացվել Միասնական սոցիալական ծառայության համապատասխան տարածքային կենտրոն՝ այն ներբեռնելուց հետո երեք աշխատանքային օրվա ընթացքում' THEN 1 ELSE 0 END) AS "13-19(2)", 
    MAX(CASE WHEN "RR"."Name" = 'Ընտանիքի որևէ անդամի համար ներկայացված՝ անապահովության նպաստ ստանալու իրավունքի որոշման համար հիմք հանդիսացող տվյալները (փաստաթղթերը) հավաստի չեն կամ կեղծ են (առկա է անհամապատասխանություն ընտանիքի կազմի և Բնակչության պետական ռեգիստրի տվյալների միջև)' THEN 1 ELSE 0 END) AS "13-19(3)", 
    MAX(CASE WHEN "RR"."Name" = 'Ընտանիքում չափահաս աշխատունակ, բայց չզբաղված անդամի կողմից աշխատանք փնտրող անձի կողմից հաշվառվելու համար դիմում չներկայացնելը' THEN 1 ELSE 0 END) AS "13-19(4)", 
    MAX(CASE WHEN "RR"."Name" = 'Ընտանիքի մեկ հաշվարկային անդամի ամսական եկամտի չափը բարձր է Հայաստանի Հանրապետության կառավարության կողմից տվյալ տարվա համար սահմանված անապահովության նպաստ ստանալու իրավունք տվող սահմանային շեմից' THEN 1 ELSE 0 END) AS "13-19(5-6)", 
    MAX(CASE WHEN "RR"."Name" = 'Առկա է ՀՀ կառավարության 09.01.2025 թ. N 27-Ն որոշման N 1 հավելվածով սահմանված որևէ բացառող գործոն' THEN 1 ELSE 0 END) AS "13-19(7)", 
    MAX(CASE WHEN "RR"."Name" in ('Ընտանիքի համար հաշվարկված անապահովության նպաստի չափը ցածր է Հայասանտանի Հանրապետության կառավարության կողմից տվյալ տարվա համար սահմանված անապահովության նպաստի նվազագույն չափից', 'Ընտանիքի անապահովության գնահատման դիմումում չեն լրացվել ու ներկայացվել այն երեխայի տվյալները, ում համար ներկայացվել է դիմում՝ առաջին դասարան ընդունվելու միանվագ հրատապ օգնության նշանակման համար', 'Դիմումը չի համապատասխանում ՀՀ կառավարության 09.01.2025 թ. N 27-Ն որոշմամբ սահմանված պայմաններին և պահանջներին', 'Առկա չէ տեղեկատվություն ընտանիքի անչափահաս անդամի՝ հանրակրթական ուսումնական հաստատության առաջին դասարան ընդունվելու մասին', 'Դիմումը մերժվել է հարցմանը չպատասխանելու պատճառով') THEN 1 ELSE 0 END) AS "13-19(9)", 
    MAX(CASE WHEN "RR"."Name" = 'Դիմումը չի համապատասխանում ՀՀ կառավարության 09.01.2025 թ. N 27-Ն որոշմամբ սահմանված պայմաններին կամ պայմաններին' THEN 1 ELSE 0 END) AS "13-19(13)", 

    COALESCE("HH"."Count_21", 0) AS "21",
    COALESCE("AI"."PeopleCount", 0) AS "22",
    COALESCE("HH"."Count_23", 0) AS "23", 
    COALESCE("HH"."Count_24", 0) AS "24", 
    COALESCE("HH"."Count_25", 0) AS "25", 
    COALESCE("HH"."Count_26", 0) AS "26", 
    COALESCE("HH"."Count_27", 0) AS "27", 
    COALESCE("HH"."Count_28", 0) AS "28", 
    COALESCE("HH"."Count_29", 0) AS "29", 
    COALESCE("HH"."Count_30", 0) AS "30", 
    COALESCE("Benefit"."DependencyRatio", "ApplicationEvaluation"."DependencyRatio") AS "31", 
    COALESCE("Benefit"."DependencyIndex", "ApplicationEvaluation"."DependencyIndex") AS "32", 
    "FamilyType"."Name" AS "33",
    COALESCE("Benefit"."AdultEquivalent", "ApplicationEvaluation"."AdultEquivalent") AS "34",
    COALESCE("HH"."Count_35", 0) AS "35", 
    COALESCE("HH"."Count_36", 0) AS "36", 
    COALESCE("HH"."Count_37", 0) AS "37", 
    COALESCE("HH"."Count_38", 0) AS "38", 
    COALESCE("HH"."Count_39", 0) AS "39", 
    COALESCE("HH"."Count_40", 0) AS "40", 
    COALESCE("HH"."Count_41", 0) AS "41", 
    COALESCE("HH"."Count_42", 0) AS "42", 
    COALESCE("HH"."Count_43", 0) AS "43", 
    CASE WHEN "HH"."Count_44" = "HH"."Count_21" THEN 1 ELSE 0 END AS "44", 
    CASE WHEN "HH"."Count_30" = "HH"."Count_45_Matches" AND "HH"."Count_30" > 0 THEN 1 ELSE 0 END AS "45", 
    COALESCE("HH"."Count_46", 0) AS "46", 
    COALESCE("HH"."Count_47", 0) AS "47", 
    COALESCE("HH"."Total_48", 0) AS "48",
    COALESCE("HH"."TotalSalarySum", 0) AS "49", 
    COALESCE("Benefit"."LivestockIncome", "App"."LivestockIncome", 0) + COALESCE("HH"."RealEstateIncomeSum", 0) AS "50",
    COALESCE("HH"."RealEstateIncomeSum", 0) AS "52",

    COALESCE("LS"."53", 0) AS "53-64(1)", COALESCE("LS"."54", 0) AS "53-64(2)", COALESCE("LS"."55", 0) AS "53-64(3)", 
    COALESCE("LS"."56", 0) AS "53-64(4)", COALESCE("LS"."57", 0) AS "53-64(5)", COALESCE("LS"."58", 0) AS "53-64(6)", 
    COALESCE("LS"."60", 0) AS "53-64(8)", COALESCE("LS"."61", 0) AS "53-64(9)", 
    COALESCE("LS"."63", 0) AS "53-64(11)", COALESCE("LS"."64", 0) AS "53-64(12)", 
    COALESCE("LS"."65", 0) AS "53-64(13)", COALESCE("LS"."66", 0) AS "53-64(14)", 
    COALESCE("Benefit"."LivestockIncome", "App"."LivestockIncome", 0) AS "65", 

    COALESCE("HH"."Total_66", 0) AS "66", 
    COALESCE("HH"."TotalPensionSum", 0) AS "69", 
    (COALESCE("HH"."Total_70", 0) + COALESCE("App"."LivestockIncome", 0)) AS "70", 
    (COALESCE("HH"."Total_70", 0) + COALESCE("App"."LivestockIncome", 0)) / NULLIF(COALESCE("Benefit"."AdultEquivalent", "ApplicationEvaluation"."AdultEquivalent"), 0) AS "71", 
    COALESCE("HH"."Count_72", 0) AS "72",
    (COALESCE("HH"."Total_70", 0) + COALESCE("App"."LivestockIncome", 0) + COALESCE("HH"."73", 0)) AS "75",
    (COALESCE("HH"."Total_70", 0) + COALESCE("App"."LivestockIncome", 0) + COALESCE("HH"."73", 0)) / NULLIF(COALESCE("Benefit"."AdultEquivalent", "ApplicationEvaluation"."AdultEquivalent"), 0) AS "76"
FROM
    "Application" AS "App"
    INNER JOIN LatestAppFilter AS "LAF" ON "App"."ID" = "LAF"."TargetAppID"
    LEFT JOIN "Community" AS "Comm" ON "App"."CommunityID" = "Comm"."ID"
    LEFT JOIN "Region" AS "Reg" ON "Comm"."RegionID" = "Reg"."ID"
    LEFT JOIN "ApplicationStatus" AS "Stat" ON "App"."Status" = "Stat"."ID"
    LEFT JOIN "ApplicationRejection" AS "AR" ON "App"."ID" = "AR"."ApplicationID"
    LEFT JOIN "RejectionReason" AS "RR" ON "AR"."RejectionReasonID" = "RR"."ID"
    LEFT JOIN (
        SELECT
            h."ApplicationID", 
            COUNT(DISTINCT COALESCE(bf."SSN", h."SSN")) AS "TotalMembers", 
            COUNT(DISTINCT COALESCE(bf."SSN", h."SSN")) AS "Count_21", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_23", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 AND COALESCE(bf."HasDisability", h."HasDisability", 'f') != 't' AND COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') != 't' THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_24", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 AND (COALESCE(bf."HasDisability", h."HasDisability", 'f') = 't' OR COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') = 't') THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_25", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") < 18 THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_26", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") >= 63 THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_27", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 74 AND (COALESCE(bf."HasDisability", h."HasDisability", 'f') = 't' OR COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') = 't') THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_28", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") >= 75 THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_29", 
            COUNT(DISTINCT CASE WHEN (COALESCE(bf."Age", h."Age") < 18 OR (COALESCE(bf."Age", h."Age") BETWEEN 18 AND 74 AND (COALESCE(bf."HasDisability", h."HasDisability", 'f') = 't' OR COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') = 't')) OR COALESCE(bf."Age", h."Age") >= 75) THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_30", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."IsStudent", h."IsStudent") = 't' AND COALESCE(bf."Age", h."Age") BETWEEN 18 AND 22 THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_35", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."IsPregnant", h."IsPregnant") = 't' THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_36", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."HasDependentChild", h."HasDependentChild") = 't' THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_37",
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") BETWEEN 14 AND 17 AND COALESCE(bf."HasDisability", h."HasDisability", 'f') != 't' AND COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') != 't' THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_38", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Salary", h."Salary") IS NOT NULL AND COALESCE(bf."Salary", h."Salary") != 0 THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_39",
            COUNT(DISTINCT CASE 
                WHEN (COALESCE(bf."Pension", h."Pension", 0) != 0 OR 
                      COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) != 0 OR 
                      COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) != 0 OR 
                      COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) != 0 OR 
                      COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) != 0 OR 
                      COALESCE(bf."UrgentSupportAmount", h."UrgentSupportAmount", 0) != 0 OR 
                      COALESCE(bf."ArtsakhSupportAmount", h."ArtsakhSupportAmount", 0) != 0)
                THEN COALESCE(bf."SSN", h."SSN") 
            END) AS "Count_40",
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Pension", h."Pension") IS NOT NULL AND COALESCE(bf."Pension", h."Pension") != 0 THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_41", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 AND COALESCE(bf."HasDisability", h."HasDisability", 'f') != 't' AND COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') != 't' AND (COALESCE(bf."Salary", h."Salary", 0)) > 0 THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_42", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 AND COALESCE(bf."HasDisability", h."HasDisability", 'f') != 't' AND COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') != 't' AND (COALESCE(bf."Salary", h."Salary", 0) + COALESCE(bf."Pension", h."Pension", 0)) = 0 THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_43", 
            COUNT(DISTINCT CASE 
                WHEN COALESCE(bf."Age", h."Age") BETWEEN 18 AND 62 
                 AND COALESCE(bf."IsEmployed", h."IsEmployed", 'f') = 'f' 
                THEN COALESCE(bf."SSN", h."SSN") 
            END) AS "Count_44",
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") BETWEEN 14 AND 17 AND COALESCE(bf."HasDisability", h."HasDisability", 'f') != 't' AND COALESCE(bf."HasFunctionalLimit", h."HasFunctionalLimit", 'f') != 't' THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_45_Matches", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."Age", h."Age") >= 65 AND COALESCE(bf."Pension", h."Pension", 0) = 0 AND COALESCE(bf."IsEmployed", h."IsEmployed", 'f') = 'f' THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_46", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."IsRegisteredInEWork", h."IsRegisteredInEWork", 'f') = 't' THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_47", 
            SUM(
                COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) +
                COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) +
                COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + 
                COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + 
                COALESCE(bf."UrgentSupportAmount", h."UrgentSupportAmount", 0) + 
                COALESCE(bf."ArtsakhSupportAmount", h."ArtsakhSupportAmount", 0)
            ) AS "Total_66",
            SUM(
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
            ) AS "Total_70",
            SUM(
                COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) +
                COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) +
                COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + 
                COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + 
                COALESCE(bf."UrgentSupportAmount", h."UrgentSupportAmount", 0) + 
                COALESCE(bf."ArtsakhSupportAmount", h."ArtsakhSupportAmount", 0) +
                COALESCE(bf."Pension", h."Pension", 0) +
                COALESCE(bf."ZinapahAmount", h."ZinapahAmount", 0) +
                COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0) +
                CASE 
                    WHEN bf."EmploymentStartDate" > a."DateSubmitted" THEN COALESCE("BFH"."HistorySalary", 0)
                    ELSE 0
                END
            ) AS "Total_48",
            SUM(COALESCE(bf."Salary", h."Salary", 0) + COALESCE(bf."Pension", h."Pension", 0) + COALESCE(bf."RentalAssistanceAmount", h."RentalAssistanceAmount", 0) + COALESCE(bf."ZinapahAmount", h."ZinapahAmount", 0) + COALESCE(bf."MigrantSupportAmount", h."MigrantSupportAmount", 0) + COALESCE(bf."RefugeeSupportAmount", h."RefugeeSupportAmount", 0) + COALESCE(bf."OrphanSupportAmount", h."OrphanSupportAmount", 0) + COALESCE(bf."FosterFamilyAmount", h."FosterFamilyAmount", 0) + COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0)) AS "TotalIncome", 
            SUM(COALESCE(bf."Salary", h."Salary", 0)) AS "TotalSalarySum", 
            SUM(COALESCE(bf."Pension", h."Pension", 0)) AS "TotalPensionSum", 
            SUM(COALESCE(h."AssignedSum", 0)) AS "TotalAssignedSum", 
            COUNT(DISTINCT CASE WHEN COALESCE(bf."AssignedSum", h."AssignedSum") IS NOT NULL AND COALESCE(bf."AssignedSum", h."AssignedSum") != 0 THEN COALESCE(bf."SSN", h."SSN") END) AS "Count_72", 
            SUM(COALESCE(bf."AssignedSum", h."AssignedSum", 0) + COALESCE(bf."AdditionalAssignment", 0)) AS "73", 
            SUM(COALESCE(bf."RealEstateNetIncomeAmount", h."RealEstateNetIncomeAmount", 0)) AS "RealEstateIncomeSum", 
            MIN(CASE WHEN COALESCE(bf."AssignedSum", h."AssignedSum", 0) > 0 THEN 1 ELSE 0 END) AS "AllMembersHaveSum"
        FROM "Household" AS h
        LEFT JOIN "Application" AS a ON h."ApplicationID" = a."ID"
        LEFT JOIN "Benefit" AS b ON h."ApplicationID" = b."ApplicationID"
        LEFT JOIN "BenefitFamily" AS bf ON b."ID" = bf."BenefitID" AND h."SSN" = bf."SSN"
        LEFT JOIN (
            SELECT 
                bfSalary."BenefitID",
                SUM(bfSalary."HistorySalary") AS "HistorySalary"
            FROM (
                SELECT 
                    bf."BenefitID",
                    bf."ID",
                    SUM(COALESCE(bfh."Salary", 0)) AS "HistorySalary"
                FROM "BenefitFamily" bf
                LEFT JOIN "BenefitFamilyHistory" bfh 
                    ON bfh."BenefitFamilyID" = bf."ID"
                    AND (bfh."Year" * 12 + bfh."Month") >= 
                        (EXTRACT(YEAR FROM bf."EmploymentStartDate") * 12 + EXTRACT(MONTH FROM bf."EmploymentStartDate"))
                    AND (bfh."Year" * 12 + bfh."Month") < 
                        (EXTRACT(YEAR FROM bf."EmploymentStartDate") * 12 + EXTRACT(MONTH FROM bf."EmploymentStartDate") + 12)
                GROUP BY bf."BenefitID", bf."ID"
            ) AS bfSalary
            GROUP BY bfSalary."BenefitID"
        ) AS "BFH" ON b."ID" = "BFH"."BenefitID"
        WHERE COALESCE(bf."AbsenceReasonID", h."AbsenceReasonID") IS NULL
        GROUP BY h."ApplicationID"
    ) AS "HH" ON "App"."ID" = "HH"."ApplicationID"
    LEFT JOIN (
        SELECT
            "AL"."ApplicationID", 
            SUM(CASE WHEN "LT"."Name" = 'Կով' THEN "AL"."Count" ELSE 0 END) AS "53",
            SUM(CASE WHEN "LT"."Name" = 'Այլ սեռահասակային խմբերի տավար' THEN "AL"."Count" ELSE 0 END) AS "54", 
            SUM(CASE WHEN "LT"."Name" = 'Գոմշամատակ' THEN "AL"."Count" ELSE 0 END) AS "55",
            SUM(CASE WHEN "LT"."Name" = 'Խոզամայր (խոճկորներով)' THEN "AL"."Count" ELSE 0 END) AS "56", 
            SUM(CASE WHEN "LT"."Name" = 'Այլ սեռահասակային խմբերի խոզեր' THEN "AL"."Count" ELSE 0 END) AS "57",
            SUM(CASE WHEN "LT"."Name" in ('Ոչխար', 'Այծ') THEN "AL"."Count" ELSE 0 END) AS "58", 
            SUM(CASE WHEN "LT"."Name" = 'Հավ' THEN "AL"."Count" ELSE 0 END) AS "60", 
            SUM(CASE WHEN "LT"."Name" in ('Բադ','Սագ') THEN "AL"."Count" ELSE 0 END) AS "61", 
            SUM(CASE WHEN "LT"."Name" = 'Ջայլամ' THEN "AL"."Count" ELSE 0 END) AS "63",
            SUM(CASE WHEN "LT"."Name" = 'Հնդկահավ' THEN "AL"."Count" ELSE 0 END) AS "64", 
            SUM(CASE WHEN "LT"."Name" = 'Մեղվաընտանիք' THEN "AL"."Count" ELSE 0 END) AS "65",
            SUM(CASE WHEN "LT"."Name" = 'Ճագար' THEN "AL"."Count" ELSE 0 END) AS "66"
        FROM "ApplicationLivestock" AS "AL"
        JOIN "LivestockType" AS "LT" ON "AL"."LivestockTypeID" = "LT"."ID"
        GROUP BY "AL"."ApplicationID"
    ) AS "LS" ON "App"."ID" = "LS"."ApplicationID"
    LEFT JOIN "Benefit" ON "App"."ID" = "Benefit"."ApplicationID"
    LEFT JOIN (
        SELECT 
            "ApplicationID",
            SUM("PeopleCount") AS "PeopleCount"
        FROM "ApplicationInspection"
        GROUP BY "ApplicationID"
    ) AS "AI" ON "App"."ID" = "AI"."ApplicationID"
    LEFT JOIN "BenefitFamily" AS "BF_MAIN" ON "Benefit"."ID" = "BF_MAIN"."BenefitID"
    LEFT JOIN "ApplicationEvaluation" ON "App"."ID" = "ApplicationEvaluation"."ApplicationID"
    LEFT JOIN "FamilyType" ON "FamilyType"."ID" = COALESCE("Benefit"."FamilyTypeID", "ApplicationEvaluation"."FamilyTypeID")
WHERE "LAF"."rn" = 1 
GROUP BY
    "App"."Num", 
    "App"."Content" -> 'CitizenData' -> 'ActualAddress' ->> 'Region', 
    "App"."Content" -> 'CitizenData' -> 'ActualAddress' ->> 'Community', 
    "App"."Status", 
    "Benefit"."BenefitStatusID", 
    "App"."ID", 
    "App"."LivestockIncome", 
    "Benefit"."OrderDate", 
    "LAF"."Total_Applications",
    "HH"."Count_21", "AI"."PeopleCount", "HH"."Count_23", "HH"."Count_24", "HH"."Count_25", "HH"."Count_26", "HH"."Count_27", "HH"."Count_28", "HH"."Count_29", "HH"."Count_30", 
    "Benefit"."DependencyRatio",
    "ApplicationEvaluation"."DependencyRatio", "Benefit"."DependencyIndex", "ApplicationEvaluation"."DependencyIndex", "FamilyType"."Name", "Benefit"."AdultEquivalent", "ApplicationEvaluation"."AdultEquivalent", 
    "ApplicationEvaluation"."AdultEquivalentMonthlyIncome",
    "Benefit"."LivestockIncome", "ApplicationEvaluation"."LivestockIncome",
    "HH"."Count_35", "HH"."Count_36", "HH"."Count_37", "HH"."Count_38", "HH"."Count_39", "HH"."TotalIncome", "HH"."Count_40", "HH"."Count_41", "HH"."Count_42", "HH"."Count_43", "HH"."Count_44", "Benefit"."StopDate", "LAF"."FirstSubmissionDate",
    "HH"."TotalMembers", "HH"."Count_45_Matches", "HH"."Count_46", "HH"."Count_47", "HH"."Total_48", "HH"."Total_66", "HH"."Total_70", "HH"."73", "HH"."TotalSalarySum", "HH"."TotalPensionSum", "HH"."TotalAssignedSum", "HH"."Count_72", "HH"."RealEstateIncomeSum",
    "LS"."53", "LS"."54", "LS"."55", "LS"."56", "LS"."57", "LS"."58", "LS"."60", "LS"."61", "LS"."63", "LS"."64", "LS"."65", "LS"."66";
