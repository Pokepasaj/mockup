const express = require('express');
const router = express.Router();

// Sample in-memory data for book reviews
let bookReviews = [
  { id: 1, title: 'Book 1', review: 'Great book!' },
  { id: 2, title: 'Book 2', review: 'Interesting read, a bit slow at times.' }
];

// Get all reviews
router.get('/reviews', (req, res) => {
  res.json(bookReviews);
});

// Get a single review by ID
router.get('/reviews/:id', (req, res) => {
  const review = bookReviews.find(r => r.id === parseInt(req.params.id));
  if (!review) {
    return res.status(404).json({ error: 'Review not found' });
  }
  res.json(review);
});

// Create a new review
router.post('/reviews', (req, res) => {
  const { title, review } = req.body;
  const newReview = { id: bookReviews.length + 1, title, review };
  bookReviews.push(newReview);
  res.status(201).json(newReview);
});

// Update a review
router.put('/reviews/:id', (req, res) => {
  const { title, review } = req.body;
  const reviewIndex = bookReviews.findIndex(r => r.id === parseInt(req.params.id));
  if (reviewIndex === -1) {
    return res.status(404).json({ error: 'Review not found' });
  }
  bookReviews[reviewIndex] = { id: parseInt(req.params.id), title, review };
  res.json(bookReviews[reviewIndex]);
});

// Delete a review
router.delete('/reviews/:id', (req, res) => {
  const reviewIndex = bookReviews.findIndex(r => r.id === parseInt(req.params.id));
  if (reviewIndex === -1) {
    return res.status(404).json({ error: 'Review not found' });
  }
  bookReviews.splice(reviewIndex, 1);
  res.status(204).send();
});

module.exports = router;
