//filename:lib/server/borrowing_transaction.js
const express = require("express");
const router = express.Router();
const db = require("./db");

console.log("borrowing_transaction.js is running...");

//fetching items to borrow
router.get("/:currentDptId/:empId", async (req, res) => {
    const currentDptId = Number(req.params.currentDptId);
    const empId = Number(req.params.empId);

    if (isNaN(currentDptId)) {
        console.warn("❌ Invalid or missing currentDptId parameter.");
        return res.status(400).json({ error: "Invalid currentDptId parameter." });
    }

    if (isNaN(empId)) {
        console.warn("❌ Invalid or missing empId parameter.");
        return res.status(400).json({ error: "Invalid empId parameter." });
    }

    console.log(`🔍 Fetching items for department_id: ${currentDptId}, excluding employee ID: ${empId}...`);

    try {
        const query = `
            SELECT 
                di.*, 
                it.ITEM_NAME, 
                it.DESCRIPTION, 
                it.PAR_NO, 
                it.PIS_NO, 
                it.PROP_NO, 
                it.SERIAL_NO, 
                it.MR_NO,
                e.FIRSTNAME, 
                e.MIDDLENAME, 
                e.LASTNAME, 
                e.SUFFIX,
                TRIM(CONCAT(e.FIRSTNAME, ' ', 
                            COALESCE(e.MIDDLENAME, ''), ' ', 
                            e.LASTNAME, ' ', 
                            COALESCE(e.SUFFIX, ''))) AS accountable_name
            FROM distributed_items di
            LEFT JOIN employee e ON di.accountable_emp = e.ID
            LEFT JOIN items it ON di.ITEM_ID = it.ID
            WHERE di.current_dpt_id = ? 
            AND di.deleted = 0
            AND di.accountable_emp != ?
            ORDER BY di.quantity DESC;  
        `;

        console.log(`📝 SQL Query: ${query}`);

        const [rows] = await db.query(query, [currentDptId, empId]);

        console.log(`✅ Total items fetched (excluding empId ${empId}): ${rows.length}`);

        return res.status(200).json({ items: rows });
    } catch (error) {
        console.error("❌ Database error:", error);
        return res.status(500).json({ error: "Server error. Please try again later." });
    }
});

router.get("/:empId", async (req, res) => {
    try {
        const empId = parseInt(req.params.empId, 10);

        if (isNaN(empId)) {
            console.warn("❌ Invalid or missing empId parameter.");
            return res.status(400).json({ error: "Invalid empId parameter." });
        }

        console.log(`🔍 Fetching userName for employee ID: ${empId}`);

        const [rows] = await db.query(
            "SELECT FIRSTNAME, MIDDLENAME, LASTNAME, SUFFIX FROM employee WHERE ID = ?",
            [empId]
        );

        if (rows.length === 0) {
            console.warn(`⚠ Employee ID ${empId} not found.`);
            return res.status(404).json({ error: "User not found" });
        }

        const { FIRSTNAME, MIDDLENAME, LASTNAME, SUFFIX } = rows[0];

        // Construct full name including suffix
        const userName = [FIRSTNAME, MIDDLENAME, LASTNAME, SUFFIX]
            .filter(name => name && name.trim() !== '')
            .map(name => name.trim())
            .join(" ");

        console.log(`✅ User Name: ${userName}`);

        res.json({ userName });
    } catch (error) {
        console.error("❌ Error fetching user:", error);
        res.status(500).json({ error: "Server error" });
    }
});


router.post("/borrow", async (req, res) => {
    try {
        console.log("📥 Received borrow request:", req.body);

        const { borrower_emp_id, owner_emp_id, itemId, quantity, DPT_ID, distributed_item_id } = req.body;

        if (!borrower_emp_id || !owner_emp_id || !distributed_item_id || quantity === undefined || quantity === null || !DPT_ID) {
            return res.status(400).json({ error: "Missing required fields" });
        }

        if (typeof quantity !== 'number' || isNaN(quantity)) {
            return res.status(400).json({ error: "Invalid quantity provided" });
        }

        console.log(`🔄 Processing borrow request: Borrower ${borrower_emp_id}, DistributedItemId ${distributed_item_id}`);

        const [itemResult] = await db.query(
            `SELECT 
                di.ID AS DISTRIBUTED_ITEM_ID,
                di.ITEM_ID,
                di.accountable_emp AS OWNER_EMP_ID,
                di.quantity,  
                i.ITEM_NAME  
            FROM distributed_items di
            JOIN items i ON di.ITEM_ID = i.ID
            WHERE di.ID = ? AND di.deleted = 0`,
            [distributed_item_id]
        );

        if (itemResult.length === 0) {
            console.error(`❌ Distributed item not found`);
            return res.status(404).json({ error: "Item not found" });
        }

        const item = itemResult[0];

        if (Number(item.OWNER_EMP_ID) !== Number(owner_emp_id)) {
            console.error(`🚨 Owner mismatch! OWNER_EMP_ID=${item.OWNER_EMP_ID}, provided=${owner_emp_id}`);
            return res.status(400).json({ error: "Invalid owner for this item" });
        }

        if (quantity > item.quantity) {
            return res.status(400).json({ error: "Not enough stock available" });
        }

        // Insert borrow transaction
        const [insertResult] = await db.query(
            `INSERT INTO borrowing_transaction 
              (DISTRIBUTED_ITM_ID, distributed_item_id, borrower_emp_id, owner_emp_id, quantity, DPT_ID, createdAt, updatedAt, status, remarks) 
              VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW(), 2, 1)`,
            [distributed_item_id, itemId, borrower_emp_id, owner_emp_id, quantity, DPT_ID]
        );

        const transactionId = insertResult.insertId;
        console.log(`✅ Borrow transaction successful: Transaction ID ${transactionId}`);

        // Save a single notification
        await db.query(
            `INSERT INTO notification_tbl 
            (TRANSACTION_ID, TRANSACTION, ITEM_ID, QUANTITY, REQUEST_STATUS, OWNER_ID, BORROWER_ID, ADMIN_ID, createdAt, updatedAt, \`READ\`) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), 0)`,
            [
                transactionId,
                1, // 1 for borrowing
                item.ITEM_ID,
                quantity,
                2, // pending
                owner_emp_id,
                borrower_emp_id,
                1 // admin
            ]
        );
        
        console.log("✅ Single notification saved successfully!");

        res.status(201).json({
            message: "Borrow transaction recorded and notification saved!",
            transactionId: transactionId
        });

    } catch (error) {
        console.error("❌ Error processing borrow transaction:", error);
        res.status(500).json({ error: "Server error" });
    }
});

module.exports = router;