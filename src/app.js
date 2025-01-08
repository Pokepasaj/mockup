const express = require('express');
const app = express();

// Middleware to parse JSON bodies
app.use(express.json());

// Import routes from reviewRoutes.js
const reviewRoutes = require('./routes/reviewRoutes');

// Use the reviewRoutes for the API
app.use('/api', reviewRoutes);

// Define a route for the root URL
app.get('/', (req, res) => {
  res.send('Welcome to the Book Review App!');
});

const PORT = process.env.PORT || 5010;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
