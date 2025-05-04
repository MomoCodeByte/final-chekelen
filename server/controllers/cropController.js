const db = require('../Config/db');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Multer configuration for image uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = './images';
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});

const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
});

// =========================
// Create Crop
// =========================
exports.createCrop = (req, res) => {
  upload.single('image')(req, res, function (err) {
    if (err) {
      return res.status(400).json({ message: `Upload error: ${err.message}` });
    }

    const { farmer_id, name, categories, price, is_available = 1, organic = 0, fresh = 0 } = req.body;
    const image_path = req.file ? 'images/' + req.file.filename : null;

    if (!farmer_id || !name || !price) {
      return res.status(400).json({ message: "Please provide farmer_id, name, and price." });
    }

    const sql = `
      INSERT INTO crops (farmer_id, name, categories, price, is_available, organic, fresh, image_path)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;

    db.query(sql, [farmer_id, name, categories, price, is_available, organic, fresh, image_path], (err, results) => {
      if (err) {
        if (req.file) fs.unlinkSync(req.file.path);
        return res.status(500).json({ message: 'Database error', error: err.message });
      }
      res.status(201).json({ message: 'Crop created', id: results.insertId, image_path });
    });
  });
};

// =========================
// Get All Crops with SQL Filtering
// =========================
exports.getCrops = (req, res) => {
  const role = req.user.role;
  const userId = req.user.id;

  let sql = 'SELECT * FROM crops';
  let params = [];

  if (role === 'farmer') {
    sql += ' WHERE farmer_id = ?';
    params.push(userId);
  } else if (role === 'customer') {
    sql += ' WHERE is_available = 1';
  }

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ message: 'Database error', error: err.message });
    res.status(200).json(results);
  });
};

// =========================
// Get Single Crop
// =========================
exports.getCropById = (req, res) => {
  const { id } = req.params;
  const role = req.user.role;
  const userId = req.user.id;

  let sql = 'SELECT * FROM crops WHERE crop_id = ?';
  let params = [id];

  if (role === 'farmer') {
    sql += ' AND farmer_id = ?';
    params.push(userId);
  } else if (role === 'customer') {
    sql += ' AND is_available = 1';
  }

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ message: 'Database error', error: err.message });
    if (results.length === 0) {
      return res.status(404).json({ message: 'Crop not found or you do not have access' });
    }
    res.status(200).json(results[0]);
  });
};

// =========================
// public logic to get all crops
// =========================

exports.getPublicCrops = (req, res) => {
  const sql = 'SELECT * FROM crops WHERE is_available = 1';
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ message: 'Database error', error: err.message });
    res.status(200).json(results);
  });
};


// =========================
// Update Crop
// =========================
exports.updateCrop = (req, res) => {
  upload.single('image')(req, res, function (err) {
    if (err) {
      return res.status(400).json({ message: `Upload error: ${err.message}` });
    }

    const { id } = req.params;
    const { farmer_id, name, categories, price, is_available, organic, fresh } = req.body;

    db.query('SELECT image_path FROM crops WHERE crop_id = ?', [id], (err, cropResults) => {
      if (err) return res.status(500).send(err);
      if (cropResults.length === 0) return res.status(404).json({ message: 'Crop not found' });

      const oldImagePath = cropResults[0].image_path;
      const newImagePath = req.file ? 'images/' + req.file.filename : oldImagePath;

      const sql = `
        UPDATE crops SET farmer_id = ?, name = ?, categories = ?, price = ?, is_available = ?, organic = ?, fresh = ?, image_path = ?
        WHERE crop_id = ?
      `;
      const params = [farmer_id, name, categories, price, is_available, organic, fresh, newImagePath, id];

      db.query(sql, params, (err, updateResults) => {
        if (err) {
          if (req.file) fs.unlinkSync(req.file.path);
          return res.status(500).send(err);
        }

        if (req.file && oldImagePath) {
          try {
            fs.unlinkSync(oldImagePath);
          } catch (cleanupErr) {
            console.error('Failed to delete old image:', cleanupErr);
          }
        }

        res.status(200).json({ message: 'Crop updated successfully.' });
      });
    });
  });
};

// =========================
// Delete Crop
// =========================
exports.deleteCrop = (req, res) => {
  const { id } = req.params;

  db.query('SELECT image_path FROM crops WHERE crop_id = ?', [id], (err, results) => {
    if (err) return res.status(500).send(err);
    if (results.length === 0) return res.status(404).json({ message: 'Crop not found' });

    const imagePath = results[0].image_path;

    db.query('DELETE FROM crops WHERE crop_id = ?', [id], (err, deleteResults) => {
      if (err) return res.status(500).send(err);

      if (imagePath) {
        try {
          fs.unlinkSync(imagePath);
        } catch (err) {
          console.error('Failed to delete image file:', err);
        }
      }

      res.status(200).json({ message: 'Crop deleted successfully.' });
    });
  });
};
