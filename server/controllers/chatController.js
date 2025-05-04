const db = require('../Config/db');

// Create chat message
exports.createChat = (req, res) => {
    const sender_id = req.user.id;
    const { receiver_id, message } = req.body;

    db.query(
        'INSERT INTO chat (sender_id, receiver_id, message) VALUES (?, ?, ?)',
        [sender_id, receiver_id, message],
        (err, results) => {
            if (err) return res.status(500).send(err);
            res.status(201).json({ id: results.insertId, message });
        }
    );
};

// Get all chats for the logged-in user
exports.getChats = (req, res) => {
    const userId = req.user.id;

    const query = `
        SELECT 
            c.chat_id,
            c.message,
            c.created_at,
            sender.username AS sender_name,
            receiver.username AS receiver_name
        FROM chat c
        JOIN users sender ON c.sender_id = sender.user_id
        JOIN users receiver ON c.receiver_id = receiver.user_id
        WHERE c.sender_id = ? OR c.receiver_id = ?
        ORDER BY c.created_at ASC
    `;

    db.query(query, [userId, userId], (err, results) => {
        if (err) return res.status(500).send(err);
        res.status(200).json(results);
    });
};

// Get a specific chat by ID (only if user is involved)
exports.getChatById = (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;

    const query = `
        SELECT 
            c.chat_id,
            c.message,
            c.created_at,
            sender.username AS sender_name,
            receiver.username AS receiver_name
        FROM chat c
        JOIN users sender ON c.sender_id = sender.user_id
        JOIN users receiver ON c.receiver_id = receiver.user_id
        WHERE c.chat_id = ? AND (c.sender_id = ? OR c.receiver_id = ?)
    `;

    db.query(query, [id, userId, userId], (err, results) => {
        if (err) return res.status(500).send(err);
        if (results.length === 0) return res.status(404).json({ message: 'Chat not found' });
        res.status(200).json(results[0]);
    });
};

// Delete chat (only if sender)
exports.deleteChat = (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;

    db.query(
        'DELETE FROM chat WHERE chat_id = ? AND sender_id = ?',
        [id, userId],
        (err, results) => {
            if (err) return res.status(500).send(err);
            if (results.affectedRows === 0) return res.status(403).json({ message: 'Unauthorized delete' });
            res.json({ message: 'Chat deleted successfully' });
        }
    );
};
