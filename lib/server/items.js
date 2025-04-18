const express = require("express");
const db = require("./db");

const router = express.Router();

console.log("distributed_items.js is running...");

// Fetch item details by ID
async function getItemDetails(itemIds) {
    if (!itemIds.length) return [];

    const query = `
        SELECT 
            i.ID AS ITEM_ID,
            i.ITEM_NAME,
            i.DESCRIPTION,
            i.PAR_NO,
            i.PIS_NO,
            i.PROP_NO,
            i.SERIAL_NO,
            i.MR_NO
        FROM items i
        WHERE i.ID IN (?);
    `;

    const [rows] = await db.query(query, [itemIds]);
    return rows;
}

// Fetch item details by item_id
router.get("/item-details/:item_id", async (req, res) => {
    const { item_id } = req.params;
    if (!item_id || isNaN(item_id)) {
        return res.status(400).json({ error: "Invalid item_id parameter." });
    }

    try {
        const items = await getItemDetails([item_id]);
        if (items.length === 0) {
            return res.status(404).json({ error: "Item not found." });
        }
        return res.status(200).json({ item_details: items[0] });
    } catch (error) {
        console.error("Database error:", error);
        return res.status(500).json({ error: "Server error. Please try again later." });
    }
});

// Fetch distributed items for an employee (owned items)
router.get("/:emp_id", async (req, res) => {
    const { emp_id } = req.params;
    if (!emp_id || isNaN(emp_id)) {
        return res.status(400).json({ error: "Invalid emp_id parameter." });
    }

    try {
        const query = `
SELECT 
    di.ID AS DISTRIBUTED_ITEM_ID,
    di.ITEM_ID,
    di.accountable_emp AS OWNER_EMP_ID,
    di.quantity,  
    di.original_quantity AS ORIGINAL_QUANTITY,
    di.remarks,
    i.PAR_NO, 
    i.MR_NO, 
    i.PIS_NO, 
    i.PROP_NO, 
    i.SERIAL_NO,
    i.unit_value,
    i.total_value,
    i.ITEM_NAME,  
    i.DESCRIPTION
FROM distributed_items di
JOIN items i ON di.ITEM_ID = i.ID
WHERE di.accountable_emp = ? 
AND di.deleted = 0
ORDER BY di.quantity DESC;
        `;

        const [results] = await db.query(query, [emp_id]);
        return res.status(200).json({ owned_items: results });
    } catch (error) {
        console.error("Database error:", error);
        return res.status(500).json({ error: "Server error. Please try again later." });
    }
});


// Fetch borrowed items
router.get("/borrowed/:borrower_emp_id", async (req, res) => {
    const { borrower_emp_id } = req.params;
    if (!borrower_emp_id || isNaN(borrower_emp_id)) {
        return res.status(400).json({ error: "Invalid borrower_emp_id parameter." });
    }

    try {
        const borrowingQuery = `
        SELECT 
            bt.ID AS transactionId,  
            bt.distributed_item_id, 
            bt.owner_emp_id, 
            bt.createdAt, 
            bt.quantity,
            bt.status,
            bt.remarks,
            i.ID AS ITEM_ID,
            i.PAR_NO, 
            i.MR_NO, 
            i.PIS_NO, 
            i.PROP_NO, 
            i.SERIAL_NO,
            i.unit_value,
            i.total_value,
            i.ITEM_NAME,
            i.DESCRIPTION
        FROM borrowing_transaction bt
        JOIN items i ON bt.distributed_item_id = i.ID
        WHERE bt.borrower_emp_id = ?
        AND ((bt.status = 1 AND bt.remarks = 1) OR (bt.status = 2 AND bt.remarks = 5))
        ORDER BY bt.quantity DESC;
    `;
    

        const [borrowingRecords] = await db.query(borrowingQuery, [borrower_emp_id]);
        if (borrowingRecords.length === 0) {
            return res.status(200).json({ borrowed_items: [] });
        }

        const ownerIds = [...new Set(borrowingRecords.map(record => record.owner_emp_id))];

        const ownerQuery = `
            SELECT ID AS OWNER_ID, 
                CONCAT(FIRSTNAME, ' ', COALESCE(MIDDLENAME, ''), ' ', LASTNAME, ' ', COALESCE(SUFFIX, '')) AS OWNER_NAME
            FROM employee 
            WHERE ID IN (?);
        `;

        const [ownerDetails] = await db.query(ownerQuery, [ownerIds]);
        const ownersMap = Object.fromEntries(ownerDetails.map(owner => [owner.OWNER_ID, owner.OWNER_NAME.trim()]));

        const borrowedItems = borrowingRecords.map(borrowed => ({
            transactionId: borrowed.transactionId,
            distributed_item_id: borrowed.distributed_item_id,
            item_id: borrowed.ITEM_ID,
            createdAt: borrowed.createdAt,
            quantity: borrowed.quantity,
            OWNER_NAME: ownersMap[borrowed.owner_emp_id] || "Unknown Owner",
            owner_emp_id: borrowed.owner_emp_id,
            ITEM_NAME: borrowed.ITEM_NAME,
            DESCRIPTION: borrowed.DESCRIPTION,
            PAR_NO: borrowed.PAR_NO || "N/A",
            MR_NO: borrowed.MR_NO || "N/A",
            PIS_NO: borrowed.PIS_NO || "N/A",
            PROP_NO: borrowed.PROP_NO || "N/A",
            SERIAL_NO: borrowed.SERIAL_NO || "N/A",
            unit_value: borrowed.unit_value || 0,
            total_value: borrowed.total_value || 0,
            status: borrowed.status,
            remarks: borrowed.remarks,
            already_requested_return: borrowed.status === 2 && borrowed.remarks === 5 
        }));

        const totalItems = borrowingRecords.reduce((sum, record) => sum + record.quantity, 0);

        return res.status(200).json({
            borrowed_items: borrowedItems,
            total_borrowed_quantity: totalItems,
            total_borrowed_transactions: borrowedItems.length
        });

    } catch (error) {
        console.error("Database error:", error);
        return res.status(500).json({ error: "Server error. Please try again later." });
    }
});
module.exports = router;