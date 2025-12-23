// Example test using official Pug library
// Run: npm install pug && node example_test.js

const pug = require('pug');
const path = require('path');

// Render example/index.pug with includes
const html = pug.renderFile(
  path.join(__dirname, 'example/index.pug'),
  { pretty: false }
);

console.log('=== Official Pug Output ===');
console.log(html);

// Expected output (minified):
// <!DOCTYPE html><html><head><title>My Site</title><script src="/javascripts/jquery.js"></script><script src="/javascripts/app.js"></script></head><body><h1>My Site</h1><p>Welcome to my super lame site.</p><footer id="footer"><p>Copyright (c) foobar</p></footer></body></html>
