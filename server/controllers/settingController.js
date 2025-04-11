const db = require('../Config/db');

// Create setting
exports.createSetting = (req, res) => {
    const { admin_id, setting_name, setting_value } = req.body;
    db.query('INSERT INTO settings (admin_id, setting_name, setting_value) VALUES (?, ?, ?)', 
             [admin_id, setting_name, setting_value], 
             (err, results) => {
                 if (err) return res.status(500).send(err);
                 res.status(201).json({ id: results.insertId });
             });
};

// Get all settings
exports.getSettings = (req, res) => {
    db.query('SELECT * FROM settings', (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
};

// Get setting by ID
exports.getSettingById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM settings WHERE setting_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results[0]);
    });
};

// Update setting
exports.updateSetting = (req, res) => {
    const { id } = req.params;
    const { admin_id, setting_name, setting_value } = req.body;
    db.query('UPDATE settings SET admin_id = ?, setting_name = ?, setting_value = ? WHERE setting_id = ?', 
             [admin_id, setting_name, setting_value, id], 
             (err, results) => {
                 if (err) return res.status(500).send(err);
                 res.json({ message: 'Setting updated successfully.' });
             });
};

// Delete setting
exports.deleteSetting = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM settings WHERE setting_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json({ message: 'Setting deleted successfully.' });
    });
};