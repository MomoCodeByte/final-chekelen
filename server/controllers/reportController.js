const db = require('../Config/db');

// Create report
exports.createReport = (req, res) => {
    const { admin_id, report_type, content } = req.body;
    db.query('INSERT INTO reports (admin_id, report_type, content) VALUES (?, ?, ?)', 
             [admin_id, report_type, content], 
             (err, results) => {
                 if (err) return res.status(500).send(err);
                 res.status(201).json({ id: results.insertId });
             });
};

// Get all reports
exports.getReports = (req, res) => {
    db.query('SELECT * FROM reports', (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
};

// Get report by ID
exports.getReportById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM reports WHERE report_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results[0]);
    });
};

// Delete report
exports.deleteReport = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM reports WHERE report_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json({ message: 'Report deleted successfully.' });
    });
};