//filebame:lib/server/db.js
const mysql = require("mysql2");
require("dotenv").config();

console.log("db.js is running....");

// Create a connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT, 
  user: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  connectionLimit: 10,
  waitForConnections: true,
  queueLimit: 0,
  connectTimeout: 60000,
});

pool.getConnection((err, connection) => {
  if (err) {
    console.error("❌ Database Connection Failed:", err.code, err.message);
  } else {
    console.log("✅ Connected to MySQL Database Online");
    connection.release();
  }
});

module.exports = pool.promise();
