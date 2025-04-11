const db = require('../Config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET; // Use the secret from .env

// Create user
exports.createUser = async (req, res) => {
    const { username, password, role, email, phone } = req.body;
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        db.query('INSERT INTO users (username, password, role, email, phone) VALUES (?, ?, ?, ?, ?)', 
                 [username, hashedPassword,'customer', email, phone], 
                 (err, results) => {
                     if (err) return res.status(500).send(err);
                     res.status(201).json({ id: results.insertId });
                 });
    } catch (error) {
        res.status(500).send('Error hashing password');
    }
};


// User login
exports.loginUser = async (req, res) => {
    const { email, password } = req.body;
    db.query('SELECT * FROM users WHERE email = ?', [email], async (err, results) => {
        if (err) return res.status(500).send(err);
        
        if (results.length === 0) {
            return res.status(401).send('Email uliyo sajilia aipo');
        }
          
        
        const user = results[0];
        const match = await bcrypt.compare(password, user.password);
     
        if (!match) {
            return res.status(401).send('email au password sio sahii');
        }
        console.log("nasubilia kujenerate token..")
        console.log(user.user_id);

        const token = jwt.sign({ id: user.user_id, role: user.role },JWT_SECRET, { expiresIn: '1h' });
        res.json({ token });
    });
}; 

// Token blacklist - in a production app, use Redis or a database
const tokenBlacklist = new Set();

// Logout endpoint
exports.logout = (req, res) => {
    try {
        // Get the token from authorization header
        const authHeader = req.headers.authorization;
        const token = authHeader && authHeader.split(' ')[1];
        
        if (token) {
            // Add token to blacklist
            tokenBlacklist.add(token);
            
            // You might want to set an expiry for blacklisted tokens
            // In a production app, you'd use Redis with TTL or
            // a database with a scheduled cleanup job
            
            // For JWT with short expiry, you could also just let them expire naturally
        }
        
        res.status(200).json({ message: 'Logout successful' });
    } catch (error) {
        console.error('Logout error:', error);
        res.status(500).json({ message: 'Server error during logout' });
    }
};

// Get all users
exports.getUsers = (req, res) => {
    db.query('SELECT * FROM users', (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
};

// Get User by ID
exports.getUserById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM users WHERE user_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results[0]);
    });
};

// Update user
exports.updateUser = async (req, res) => {
    const { id } = req.params;
    const { username, password, role, email, phone } = req.body;
    let hashedPassword = password;

    if (password) {
        try {
            hashedPassword = await bcrypt.hash(password, 10);
        } catch (error) {
            return res.status(500).send('Error hashing password');
        }
    }

    db.query('UPDATE users SET username = ?, password = ?, role = ?, email = ?, phone = ? WHERE user_id = ?', 
             [username, hashedPassword, role, email, phone, id], 
             (err, results) => {
                 if (err) return res.status(500).send(err);
                 res.json({ message: 'User updated successfully.' });
             });
};

// Delete user
exports.deleteUser = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM users WHERE user_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json({ message: 'User deleted successfully.' });
    });
};