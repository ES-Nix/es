const bcrypt = require('bcrypt');

bcrypt.hash('myPlainTextPassword', 10, function(err, hash) {
  if (err) {
    console.error('Error hashing password:', err);
    process.exit(1);
  } else {
    console.log('Hashed password:', hash);
  }
});
