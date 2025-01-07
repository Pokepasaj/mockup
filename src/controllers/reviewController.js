const { getAllReviews, addReview, deleteReview } = require('../models/reviewModel');

const getReviews = async (req, res) => {
  try {
    const reviews = await getAllReviews();
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch reviews' });
  }
};

const createReview = async (req, res) => {
  const { book, review } = req.body;
  if (!book || !review) {
    return res.status(400).json({ error: 'Both book and review are required' });
  }
  try {
    await addReview(book, review);
    res.status(201).json({ message: 'Review added successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to add review' });
  }
};

const removeReview = async (req, res) => {
  const { id } = req.params;
  try {
    await deleteReview(id);
    res.json({ message: 'Review deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete review' });
  }
};

module.exports = { getReviews, createReview, removeReview };
