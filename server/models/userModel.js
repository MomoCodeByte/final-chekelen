const db = require('../Config/db');

const createUser = (username,phone, email, password, callback) => {
  const sql = 'INSERT INTO users (username,phone, email, password) VALUES (?, ?, ?, ?)';
  db.query(sql, [username, phone, email, password], callback);
};

module.exports = { createUser };
