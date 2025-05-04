const db = require('../Config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET;

// Create user
exports.createUser = async (req, res) => {
    const { username, password, role, email, phone } = req.body;
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        db.query(
            'INSERT INTO users (username, password, role, email, phone) VALUES (?, ?, ?, ?, ?)', 
            [username, hashedPassword, 'customer', email, phone], 
            (err, results) => {
                if (err) return res.status(500).send(err);
                res.status(201).json({ id: results.insertId });
            }
        );
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

        const token = jwt.sign({ id: user.user_id, role: user.role }, JWT_SECRET, { expiresIn: '1h' });
        res.json({ token });
    });
};

// Token blacklist (for logout)
const tokenBlacklist = new Set();

// Logout user
exports.logout = (req, res) => {
    try {
        const authHeader = req.headers.authorization;
        const token = authHeader && authHeader.split(' ')[1];
        
        if (token) {
            tokenBlacklist.add(token);
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

// Get user by ID
exports.getUserById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM users WHERE user_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        if (results.length === 0) {
            return res.status(404).send('User not found');
        }
        res.json(results[0]);
    });
};


exports.updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const { username, password, role, email, phone } = req.body;
        
        // Validate input
        if (!id || !username || !email) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        
        // Validate role
        const validRoles = ['customer', 'farmer', 'admin'];
        if (role && !validRoles.includes(role)) {
            return res.status(400).json({ error: 'Invalid role' });
        }
        
        // Check if user exists
        const userExists = await new Promise((resolve, reject) => {
            db.query('SELECT * FROM users WHERE user_id = ?', [id], (err, results) => {
                if (err) return reject(err);
                resolve(results.length > 0 ? results[0] : null);
            });
        });
        
        if (!userExists) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        // Prepare update parameters
        let queryParams = [username, email, phone, id];
        let query = 'UPDATE users SET username = ?, email = ?, phone = ?';
        
        // If password is provided, hash it and update
        if (password) {
            const hashedPassword = await bcrypt.hash(password, 10);
            query += ', password = ?';
            queryParams.splice(3, 0, hashedPassword); // Insert password before id
        }

        // Update role only if it's valid and provided
        if (role) {
            query += ', role = ?';
            queryParams.push(role); // Add role to parameters
        }

        query += ' WHERE user_id = ?';
        
        db.query(query, queryParams, (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ 
                success: true, 
                message: 'User updated successfully.',
                user: { id, username, role: role || userExists.role, email, phone }
            });
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};


// Get users by role
exports.getUserRoles = (req, res) => {
    const { role } = req.params;
    
    // Validate role parameter
    if (!role) {
        return res.status(400).json({ error: 'Role parameter is required' });
    }
    
    // Validate that the role is one of the allowed values
    const validRoles = ['customer', 'farmer', 'admin'];
    if (!validRoles.includes(role)) {
        return res.status(400).json({ error: 'Invalid role. Must be customer, farmer, or admin' });
    }
    
    db.query('SELECT * FROM users WHERE role = ?', [role], (err, results) => {
        if (err) {
            console.error('Error fetching users by role:', err);
            return res.status(500).json({ error: 'Database error' });
        }
        
        if (results.length === 0) {
            return res.status(200).json({ message: `No users found with role: ${role}`, users: [] });
        }
        
        // Return users with the specified role
        res.status(200).json(results);
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
