// filename: lib/server/verifyOtp.js
const express = require("express");
const router = express.Router();
const db = require("../server/db");
const jwt = require("jsonwebtoken");
require("dotenv").config();

const JWT_SECRET = process.env.JWT_SECRET;

console.log("verifyOtp.js is running...");

router.post("/verify-otp", async (req, res) => {
  const { emp_id, otp } = req.body;

  if (!emp_id || !otp) {
    return res.status(400).json({ msg: "emp_id and OTP are required." });
  }

  try {
    const [otpRows] = await db.query(
      "SELECT * FROM user_otps WHERE emp_id = ? AND otp = ? AND expires_at > NOW() ORDER BY id DESC LIMIT 1",
      [emp_id, otp]
    );

    if (otpRows.length === 0) {
      return res.status(400).json({ msg: "Invalid or expired OTP." });
    }

    // Delete used OTP
    await db.query("DELETE FROM user_otps WHERE emp_id = ?", [emp_id]);

    // Fetch user data
    const [userRows] = await db.query("SELECT * FROM users WHERE emp_id = ?", [emp_id]);
    if (userRows.length === 0) {
      return res.status(400).json({ msg: "User not found." });
    }
    const user = userRows[0];

    // Generate JWT
    const token = jwt.sign(
      { userId: user.id, username: user.email, emp_id: emp_id },
      JWT_SECRET,
      { expiresIn: "1h" }
    );

    return res.json({
      msg: "OTP verified successfully",
      redirect: "home",
      token,
      user,
    });

  } catch (err) {
    console.error("OTP verification error:", err.message);
    return res.status(500).json({ msg: "Server error." });
  }
});

module.exports = router;
