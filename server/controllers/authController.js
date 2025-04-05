const { createUser } = require('../models/userModel');

const register = (req, res) => {
  const { username, phone, email, password } = req.body;

  if (!username || !phone || !email || !password) {
    return res.status(400).json({ message: 'Jaza kila sehemu tafadhali.' });
  }

  createUser(username, phone, email, password, (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Tatizo la database' });
    }

    res.status(201).json({ message: 'Usajili umefanikiwa!' });
  });
};

module.exports = { register };
