//filename:lib/server/users.js
const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const db = require("../server/db");
const { check, validationResult } = require("express-validator");
require("dotenv").config();

const JWT_SECRET = process.env.JWT_SECRET;

console.log("users.js is running....");

// LOGIN ROUTE
router.post(
  "/login",
  [
    check("id_number", "ID Number is required").not().isEmpty(),
    check("password", "Password is required").not().isEmpty(),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ msg: "Please provide both ID Number and password." });
    }

    let { id_number, password } = req.body;
    id_number = id_number.trim();
    password = password.trim();

    try {
      console.log("Received login request for ID_number:", id_number);

      const [employeeRows] = await db.query(
        "SELECT ID AS emp_id, FIRSTNAME, CURRENT_DPT_ID FROM employee WHERE ID_NUMBER = ?",
        [id_number]
      );

      if (employeeRows.length === 0) {
        console.log("ID not found in employee table.");
        return res.status(400).json({ msg: "Invalid credentials" });
      }

      const employee = employeeRows[0];
      const emp_Id = employee.emp_id; 
      const firstName = employee.FIRSTNAME ? employee.FIRSTNAME.trim() : null;
      const firstLetter = firstName ? firstName.charAt(0).toUpperCase() : null;
      const currentDptId = employee.CURRENT_DPT_ID;

      console.log("User found in employee table:", employee);
      console.log("Extracted Emp ID:", emp_Id);
      console.log("First Letter Extracted:", firstLetter);


      const defaultPassword = id_number.toString(); 

      // 🔹 Check if user exists in the users table
      const [userRows] = await db.query("SELECT * FROM users WHERE emp_id = ?", [emp_Id]);

      if (userRows.length === 0) {
        console.log("First-time user detected.");

        // 🔹 First-time users must use their ID_NUMBER as password
        if (password !== defaultPassword) {
          console.log("Entered password does not match default password.");
          return res.status(400).json({ msg: "Invalid credentials" });
        }

        console.log("Default password match. Redirecting to update.");

        return res.json({
          msg: "Redirect to update",
          redirect: "update",
          id_number,
          emp_id: emp_Id,
          firstLetter,
          currentDptId
        });
      }

      // 🔹 User exists, verify hashed password
      const user = userRows[0];
      const isMatch = await bcrypt.compare(password, user.password);

      if (!isMatch) {
        console.log("Incorrect password.");
        return res.status(400).json({ msg: "Invalid credentials" });
      }

      console.log("Login successful.");
      const token = jwt.sign(
        { userId: user.id, username: user.email, emp_id: emp_Id },
        JWT_SECRET,
        { expiresIn: "1h" }
      );

      res.json({
        msg: "Login successful",
        redirect: "home",
        token,
        user,
        emp_id: emp_Id, 
        firstLetter,
        currentDptId
      });

    } catch (err) {
      console.error("Login error:", err.message);
      res.status(500).send("Server error");
    }
  }
);


// UPDATE ROUTE
router.post("/update", async (req, res) => {
  try {
    const { emp_id, email, password } = req.body;

    console.log("Received update request:", { emp_id, email, password: "hidden for security" });

    if (!emp_id) {
      return res.status(400).json({ error: "Employee ID (emp_id) is missing" });
    }
    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required" });
    }

    const emp_id_int = parseInt(emp_id, 10);
    console.log(`Checking employee with ID: ${emp_id_int} (Type: ${typeof emp_id_int})`);

    // Fetch employee using ID (Primary Key)
    const [employee] = await db.query(
      "SELECT ID FROM employee WHERE ID = ?", 
      [emp_id_int]
    );

    console.log("Employee Query Result:", employee);

    if (employee.length === 0) {
      return res.status(404).json({ error: `Employee ID ${emp_id_int} not found in the employee table.` });
    }

    const { ID } = employee[0];

    console.log("Fetched Employee Data:", { ID });

    // Check if user already exists in users table using emp_id (ID from employee table)
    const [users] = await db.query("SELECT * FROM users WHERE emp_id = ?", [ID]);
    console.log("User Query Result:", users);

    const existingUser = users.length > 0 ? users[0] : null;

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    if (existingUser) {
      await db.query(
        "UPDATE users SET email = ?, password = ?, role = 3 WHERE emp_id = ?",
        [email, hashedPassword, ID]
      );

      console.log("User updated successfully:", { ID, email, role: 3 });
      return res.status(200).json({ success: "User updated successfully." });
    } else {
      await db.query(
        "INSERT INTO users (emp_id, email, password, role) VALUES (?, ?, ?, 3)",
        [ID, email, hashedPassword]
      );

      console.log("User created successfully:", { ID, email, "password": "updated!", role: 3 });
      return res.status(201).json({ success: "User created successfully." });
    }
  } catch (error) {
    console.error("Error updating user:", error);
    return res.status(500).json({ error: "Server error. Please try again later." });
  }
});

router.post("/verify-email-id", async (req, res) => {
  const { email, id_number } = req.body;
  console.log("Received email and ID number for verification:", { email, id_number });

  try {
    // Find the user by email in the users table
    const [userRows] = await db.query("SELECT emp_id FROM users WHERE email = ?", [email]);

    if (userRows.length === 0) {
      console.log("Email not found in users table.");
      return res.status(400).json({ error: "Email not found." });
    }

    const emp_id = userRows[0].emp_id;
    console.log("Retrieved emp_id from users table:", emp_id);

    // Verify the ID_NUMBER in the employee table
    const [employeeRows] = await db.query("SELECT ID_NUMBER FROM employee WHERE ID = ?", [emp_id]);
    
    if (employeeRows.length === 0) {
      console.log("No employee found with emp_id:", emp_id);
      return res.status(400).json({ error: "ID Number is incorrect." });
    }

    console.log("Retrieved ID_NUMBER from employee table:", employeeRows[0].ID_NUMBER);
    console.log("Provided ID Number:", id_number);

    // Ensure ID number matches
    if (employeeRows[0].ID_NUMBER.toString().trim() !== id_number.toString().trim()) {
      console.log("Mismatch: Stored ID_NUMBER:", employeeRows[0].ID_NUMBER, "Provided ID Number:", id_number);
      return res.status(400).json({ error: "ID Number is incorrect." });
    }

    return res.json({ success: "Identity verified." });

  } catch (error) {
    console.error("Error verifying identity:", error);
    return res.status(500).json({ error: "Server error. Please try again later." });
  }
});


router.post("/reset-password", async (req, res) => {
  const { email, new_password } = req.body;

  try {
    // Check if the email exists in the users table
    const [userRows] = await db.query("SELECT emp_id FROM users WHERE email = ?", [email]);

    if (userRows.length === 0) {
      return res.status(400).json({ error: "Email not found." });
    }

    // Hash the new password before saving
    const hashedPassword = await bcrypt.hash(new_password, 10);

    // Update the password in the users table
    await db.query("UPDATE users SET password = ? WHERE email = ?", [hashedPassword, email]);

    return res.json({ success: "Password has been reset successfully." });

  } catch (error) {
    console.error("Error resetting password:", error);
    return res.status(500).json({ error: "Server error. Please try again later." });
  }
});


module.exports = router;
