const db = require('../Config/db');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Set up storage for uploaded images
const storage = multer.diskStorage({
  destination: function(req, file, cb) {
    const dir = './images';
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: function(req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

// Filter for image files only
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  }
});

// Combined create crop with image upload
exports.createCrop = (req, res) => {
  upload.single('image')(req, res, function(err) {
    if (err instanceof multer.MulterError) {
      return res.status(400).json({ message: `Multer error: ${err.message}` });
    } else if (err) {
      return res.status(400).json({ message: err.message });
    }

    const { farmer_id, name, description, price, is_available, organic, fresh } = req.body;
    
    // Set default values if not provided
    const availability = is_available !== undefined ? is_available : 1;
    const isOrganic = organic !== undefined ? organic : 0;
    const isFresh = fresh !== undefined ? fresh : 0;
    
    // Get image path if file was uploaded
    const image_path = req.file ? 'images/' + req.file.filename : null;

    db.query(
      'INSERT INTO crops (farmer_id, name, description, price, is_available, organic, fresh, image_path) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', 
      [farmer_id, name, description, price, availability, isOrganic, isFresh, image_path], 
      (err, results) => {
        if (err) {
          // Clean up uploaded file if database operation fails
          if (req.file) {
            try {
              fs.unlinkSync(req.file.path);
            } catch (cleanupErr) {
              console.error('Failed to clean up uploaded file:', cleanupErr);
            }
          }
          return res.status(500).json({ 
            message: 'Database error',
            error: err.message 
          });
        }
        res.status(201).json({ 
          id: results.insertId,
          image_path: image_path 
        });
      }
    );
  });
};

// Get all crops (keep this the same as before)
exports.getCrops = (req, res) => {
  db.query(`
    SELECT 
      crop_id,
      farmer_id,
      name,
      description,
      price,
      is_available,
      organic,
      fresh,
      image_path,
      CONCAT(name, ' @ Tsh ', FORMAT(price, 0)) AS product_display,
      CONCAT(
        IF(organic = 1, 'Organic', ''),
        IF(organic = 1 AND fresh = 1, ' ', ''),
        IF(fresh = 1, 'Fresh', '')
      ) AS tags
    FROM crops
  `, (err, results) => {
    if (err) return res.status(500).send(err);
    res.json(results);
  });
};

// Get crop by ID (keep this the same)
exports.getCropById = (req, res) => {
  const { id } = req.params;
  db.query(`
    SELECT 
      *,
      CONCAT(name, ' @ Tsh ', FORMAT(price, 0)) AS product_display,
      CONCAT(
        IF(organic = 1, 'Organic', ''),
        IF(organic = 1 AND fresh = 1, ' ', ''),
        IF(fresh = 1, 'Fresh', '')
      ) AS tags
    FROM crops 
    WHERE crop_id = ?
  `, [id], (err, results) => {
    if (err) return res.status(500).send(err);
    if (results.length === 0) return res.status(404).json({ message: 'Crop not found' });
    res.json(results[0]);
  });
};

// Update crop with potential image update
exports.updateCrop = (req, res) => {
  upload.single('image')(req, res, function(err) {
    if (err instanceof multer.MulterError) {
      return res.status(400).json({ message: `Multer error: ${err.message}` });
    } else if (err) {
      return res.status(400).json({ message: err.message });
    }

    const { id } = req.params;
    const { farmer_id, name, description, price, is_available, organic, fresh } = req.body;
    
    // First get the current image path
    db.query('SELECT image_path FROM crops WHERE crop_id = ?', [id], (err, results) => {
      if (err) return res.status(500).send(err);
      if (results.length === 0) return res.status(404).json({ message: 'Crop not found' });

      const oldImagePath = results[0].image_path;
      const newImagePath = req.file ? 'images/' + req.file.filename : oldImagePath;

      db.query(
        `UPDATE crops SET 
          farmer_id = ?, 
          name = ?, 
          description = ?, 
          price = ?, 
          is_available = ?,
          organic = ?,
          fresh = ?,
          image_path = ?
        WHERE crop_id = ?`, 
        [farmer_id, name, description, price, is_available, organic, fresh, newImagePath, id], 
        (err, results) => {
          if (err) {
            // Clean up new uploaded file if database operation fails
            if (req.file) {
              try {
                fs.unlinkSync(req.file.path);
              } catch (cleanupErr) {
                console.error('Failed to clean up uploaded file:', cleanupErr);
              }
            }
            return res.status(500).send(err);
          }
          
          // Delete old image if it was replaced
          if (req.file && oldImagePath) {
            try {
              fs.unlinkSync(oldImagePath);
            } catch (cleanupErr) {
              console.error('Failed to clean up old image:', cleanupErr);
            }
          }
          
          res.json({ message: 'Crop updated successfully.' });
        }
      );
    });
  });
};

// Delete crop (updated to also delete associated image)
exports.deleteCrop = (req, res) => {
  const { id } = req.params;
  
  // First get the image path
  db.query('SELECT image_path FROM crops WHERE crop_id = ?', [id], (err, results) => {
    if (err) return res.status(500).send(err);
    if (results.length === 0) return res.status(404).json({ message: 'Crop not found' });

    const imagePath = results[0].image_path;
    
    // Delete the crop record
    db.query('DELETE FROM crops WHERE crop_id = ?', [id], (err, results) => {
      if (err) return res.status(500).send(err);
      if (results.affectedRows === 0) {
        return res.status(404).json({ message: 'Crop not found' });
      }
      
      // Delete the associated image file if it exists
      if (imagePath) {
        try {
          fs.unlinkSync(imagePath);
        } catch (err) {
          console.error('Failed to delete image file:', err);
        }
      }
      
      res.json({ message: 'Crop deleted successfully.' });
    });
  });
};

// Remove the separate uploadImage function as it's now integrated