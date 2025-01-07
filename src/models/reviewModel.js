const db = require('../config/db');

const getAllReviews = async () => {
  const [rows] = await db.query('SELECT * FROM reviews');
  return rows;
};

const addReview = async (book, review) => {
  await db.query('INSERT INTO reviews (book, review) VALUES (?, ?)', [book, review]);
};

const deleteReview = async (id) => {
  await db.query('DELETE FROM reviews WHERE id = ?', [id]);
};

module.exports = { getAllReviews, addReview, deleteReview };
