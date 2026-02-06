USE [test_database]
GO
/****** Object:  StoredProcedure [dbo].[ArchiveOldChats_BiDirectional]    Script Date: 2/6/2026 10:13:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ArchiveOldChats_BiDirectional]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- محاسبه تعداد پیام‌ها بین هر Pair
        ;WITH PairCounts AS (
            SELECT 
                CASE WHEN sender < receiver THEN sender ELSE receiver END AS User1,
                CASE WHEN sender < receiver THEN receiver ELSE sender END AS User2,
                COUNT(*) AS MsgCount
            FROM tbl_chat
            GROUP BY 
                CASE WHEN sender < receiver THEN sender ELSE receiver END,
                CASE WHEN sender < receiver THEN receiver ELSE sender END
        ),

        Ranked AS (
            SELECT 
                c.id, c.chatcontent, c.p_regdate, c.e_regdate,
                c.isphoto, c.islocation, c.istext, c.isread,
                c.sender, c.receiver,
                ROW_NUMBER() OVER (
                    PARTITION BY 
                        CASE WHEN c.sender < c.receiver THEN c.sender ELSE c.receiver END,
                        CASE WHEN c.sender < c.receiver THEN c.receiver ELSE c.sender END
                    ORDER BY c.p_regdate ASC, c.id ASC
                ) AS rn,
                pc.MsgCount
            FROM tbl_chat c
            INNER JOIN PairCounts pc
                ON (CASE WHEN c.sender < c.receiver THEN c.sender ELSE c.receiver END) = pc.User1
                AND (CASE WHEN c.sender < c.receiver THEN c.receiver ELSE c.sender END) = pc.User2
        )

        SELECT *
        INTO #ToArchive
        FROM Ranked
        WHERE rn <= MsgCount - 30;  -- فقط پیام‌های قدیمی‌تر از ۳۰ آخر

        -- اگر چیزی برای آرشیو وجود نداشت، خارج شو
        IF NOT EXISTS (SELECT 1 FROM #ToArchive)
        BEGIN
            COMMIT TRANSACTION;
            RETURN;
        END

        -- انتقال به آرشیو
        INSERT INTO tbl_chat_archive
        (
            chatcontent, p_regdate, e_regdate,
            isphoto, islocation, istext, isread,
            sender, receiver
        )
        SELECT 
            chatcontent, p_regdate, e_regdate,
            isphoto, islocation, istext, isread,
            sender, receiver
        FROM #ToArchive;

        -- حذف از جدول اصلی
        DELETE c
        FROM tbl_chat c
        INNER JOIN #ToArchive t ON c.id = t.id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
