const db = require('../Config/db');

// Create chat message
exports.createChat = (req, res) => {
    const { sender_id, receiver_id, message } = req.body;
    db.query('INSERT INTO chat (sender_id, receiver_id, message) VALUES (?, ?, ?)', 
             [sender_id, receiver_id, message], 
             (err, results) => {
                 if (err) return res.status(500).send(err);
                 res.status(201).json({ id: results.insertId });
             });
};

// Get all chat messages
exports.getChats = (req, res) => {
    db.query('SELECT * FROM chat', (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
};

// Get chat by ID
exports.getChatById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM chat WHERE chat_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results[0]);
    });
};

// Delete chat message
exports.deleteChat = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM chat WHERE chat_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json({ message: 'Chat message deleted successfully.' });
    });
};