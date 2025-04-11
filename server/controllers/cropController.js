const db = require('../Config/db');

// Create crop
exports.createCrop = (req, res) => {
    const { farmer_id, name, description, price, availability } = req.body;
    db.query('INSERT INTO crops (farmer_id, name, description, price, availability) VALUES (?, ?, ?, ?, ?)', 
             [farmer_id, name, description, price, availability], 
             (err, results) => {
                 if (err) return res.status(500).send(err);
                 res.status(201).json({ id: results.insertId });
             });
};

// Get all crops
exports.getCrops = (req, res) => {
    db.query('SELECT * FROM crops', (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
};

// Get crop by ID
exports.getCropById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM crops WHERE crop_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results[0]);
    });
};

// Update crop
exports.updateCrop = (req, res) => {
    const { id } = req.params;
    const { farmer_id, name, description, price, availability } = req.body;
    db.query('UPDATE crops SET farmer_id = ?, name = ?, description = ?, price = ?, availability = ? WHERE crop_id = ?', 
             [farmer_id, name, description, price, availability, id], 
             (err, results) => {
                 if (err) return res.status(500).send(err);
                 res.json({ message: 'Crop updated successfully.' });
             });
};

// Delete crop
exports.deleteCrop = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM crops WHERE crop_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json({ message: 'Crop deleted successfully.' });
    });
};