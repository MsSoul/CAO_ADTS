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
            i.MR_NO,
            i.ACCOUNT_CODE
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
AND di.deleted = 0;

        `;

        const [responseItems] = await db.query(query, [emp_id]);

        // Log the results for debugging
        console.log(`✅ Found ${responseItems.length} items for emp_id ${emp_id}`);

        res.status(200).json({ items: responseItems });
    } catch (error) {
        console.error("❌ Database error:", error);
        res.status(500).json({ error: "Server error. Please try again later." });
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
    bt.distributed_item_id, 
    bt.owner_emp_id, 
    bt.createdAt, 
    bt.quantity,
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
JOIN distributed_items di ON bt.distributed_item_id = di.ID  -- Fix here
JOIN items i ON di.ITEM_ID = i.ID  -- Fix here
WHERE bt.borrower_emp_id = ?
AND bt.status = 1 
AND bt.remarks = 1;
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
            distributed_item_id: borrowed.distributed_item_id,
            createdAt: borrowed.createdAt,
            quantity: borrowed.quantity,
            OWNER_NAME: ownersMap[borrowed.owner_emp_id] || "Unknown Owner",
            ITEM_NAME: borrowed.ITEM_NAME,
            DESCRIPTION: borrowed.DESCRIPTION,
            PAR_NO: borrowed.PAR_NO || "N/A",
            MR_NO: borrowed.MR_NO || "N/A",
            PIS_NO: borrowed.PIS_NO || "N/A",
            PROP_NO: borrowed.PROP_NO || "N/A",
            SERIAL_NO: borrowed.SERIAL_NO || "N/A",
            unit_value: borrowed.unit_value || 0,
            total_value: borrowed.total_value || 0
        }));

        return res.status(200).json({ borrowed_items: borrowedItems });
    } catch (error) {
        console.error("Database error:", error);
        return res.status(500).json({ error: "Server error. Please try again later." });
    }
});


module.exports = router;