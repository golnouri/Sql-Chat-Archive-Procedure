# SQL Server Chat Archiver (Bi-Directional)

A SQL Server stored procedure that archives old chat messages while keeping the most recent messages for each conversation pair.

This procedure is designed for messaging systems where chat tables grow quickly and older messages should be moved to an archive table for better performance and storage management.

---

## Features

- Archives messages **per conversation pair** (bi-directional).
- Keeps the **last N messages** (currently 30) for each pair.
- Uses **transaction handling** to ensure data integrity.
- Uses **CTE and window functions** for efficient ranking.
- Safe rollback on errors.

---

## How It Works

1. Groups messages by conversation pair (`sender`, `receiver`) regardless of direction.
2. Counts total messages per pair.
3. Ranks messages by date (oldest first).
4. Selects all messages except the most recent 30.
5. Moves selected rows to an archive table.
6. Deletes archived rows from the main table.

© Mojtaba Golnouri  
GitHub: https://github.com/golnouri
